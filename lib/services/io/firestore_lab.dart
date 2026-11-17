import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:tick/lab/feed_log.dart';
import 'package:tick/lab/lab_store.dart';
import 'package:tick/lab/logic.dart';
import 'package:tick/lab/models.dart';
import 'package:tick/lab/profile.dart';
import 'package:tick/services/gateways.dart';
import 'package:tick/services/io/lab_profile_remote.dart';

const _ventExpiryReadBuffer = Duration(minutes: 1);

class FirestoreLabStore implements LabStore {
  FirestoreLabStore({
    required this.auth,
    required this.newId,
    required this.languageCode,
    required this.profileCache,
    this.profileRemote,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final AuthGateway auth;
  final String Function() newId;
  final String Function() languageCode;
  final LabProfileCache profileCache;
  final LabProfileRemote? profileRemote;
  final DateTime Function() now;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  String? get uid => auth.current?.uid;

  @override
  bool get canReview => labCanReview(auth.current?.email);

  @override
  bool get sharesWithOthers => true;

  @override
  LabFeed? get cachedPromptFeed => _lastPromptFeed;

  Stream<LabFeed>? _promptStream;
  StreamController<LabFeed>? _promptFeedCtrl;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _promptSub;
  LabFeed? _lastPromptFeed;

  @override
  void refreshPromptFeed() {
    LabFeedLog.event('refresh');
    unawaited(_promptSub?.cancel());
    _promptSub = null;
    unawaited(_promptFeedCtrl?.close());
    _promptFeedCtrl = null;
    _promptStream = null;
    _lastPromptFeed = null;
  }

  void _emitPromptFeed(LabFeed feed, {required String reason}) {
    _lastPromptFeed = feed;
    LabFeedLog.event('emit', {
      'reason': reason,
      'loading': feed.loading,
      'remoteFailed': feed.remoteFailed,
      'count': feed.prompts.length,
      'featuredOpen': feed.prompts
          .where((p) => p.featured && p.phase == LabPhase.open)
          .length,
    });
    final ctrl = _promptFeedCtrl;
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(feed);
    } else {
      LabFeedLog.event('emit.skipped', {'reason': 'controller closed'});
    }
  }

  void _ensurePromptFeedListening() {
    if (_promptSub != null) {
      LabFeedLog.event('listen.skip', {'reason': 'already subscribed'});
      return;
    }
    LabFeedLog.event('listen.start');
    final watch = Stopwatch()..start();
    _emitPromptFeed(
      const LabFeed(prompts: [], loading: true),
      reason: 'initial',
    );
    unawaited(() async {
      LabFeedLog.event('auth.start');
      final uid = await _ensureUser();
      LabFeedLog.event('auth.done', {
        'uid': uid ?? '(null)',
        'ms': watch.elapsedMilliseconds,
      });
      if (_promptSub != null) return;
      if (uid == null) {
        LabFeedLog.event('listen.abort', {'reason': 'no uid'});
        _emitPromptFeed(
          const LabFeed(prompts: [], loading: false, remoteFailed: true),
          reason: 'auth failed',
        );
        return;
      }
      LabFeedLog.event('snapshots.subscribe');
      _promptSub = _publishedPrompts.snapshots().listen(
        (snapshot) {
          unawaited(() async {
            try {
              final rawDocs = snapshot.docs.length;
              var skipped = 0;
              final base = <LabPrompt>[];
              for (final doc in snapshot.docs) {
                final prompt = _promptFrom(doc);
                if (prompt != null) {
                  base.add(prompt);
                } else {
                  skipped++;
                }
              }
              final sorted = sortLabPrompts(base);
              final meta = snapshot.metadata;
              final awaitingServer = meta.isFromCache && sorted.isEmpty;
              LabFeedLog.event('snapshot', {
                'ms': watch.elapsedMilliseconds,
                'rawDocs': rawDocs,
                'parsed': base.length,
                'skipped': skipped,
                'sorted': sorted.length,
                'fromCache': meta.isFromCache,
                'hasPendingWrites': meta.hasPendingWrites,
                'awaitingServer': awaitingServer,
              });
              _emitPromptFeed(
                LabFeed(prompts: sorted, loading: awaitingServer),
                reason: awaitingServer ? 'cache empty' : 'snapshot',
              );
              if (awaitingServer) return;
            } catch (error, stack) {
              LabFeedLog.event('snapshot.parse.failed', {'error': error});
              debugPrint('lab prompts parse failed: $error\n$stack');
              _emitPromptFeed(
                const LabFeed(prompts: [], remoteFailed: true),
                reason: 'parse failed',
              );
            }
          }());
        },
        onError: (Object error, StackTrace stack) {
          final hint = error.toString().contains('permission-denied')
              ? 'deploy firestore.rules or check labPrompts read rule'
              : null;
          LabFeedLog.event('snapshots.error', {
            'error': error,
            'ms': watch.elapsedMilliseconds,
            if (hint != null) 'hint': hint,
          });
          debugPrint('lab prompts failed: $error\n$stack');
          _emitPromptFeed(
            const LabFeed(prompts: [], loading: false, remoteFailed: true),
            reason: 'snapshots error',
          );
        },
        onDone: () {
          LabFeedLog.event('snapshots.done');
        },
        cancelOnError: false,
      );
    }());
  }

  final _boardStreams = <String, Stream<PromptBoard>>{};
  Stream<List<LabProposal>>? _proposalStream;
  Stream<List<LabReport>>? _reportStream;

  CollectionReference<Map<String, dynamic>> get _prompts =>
      _db.collection('labPrompts');

  /// Must match [firestore.rules] (`phase in open|closed`) or list queries fail.
  Query<Map<String, dynamic>> get _publishedPrompts =>
      _prompts.where('phase', whereIn: ['open', 'closed']);

  CollectionReference<Map<String, dynamic>> get _proposals =>
      _db.collection('labProposals');

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('labReports');

  @override
  Stream<LabFeed> watchPrompts() {
    _promptFeedCtrl ??= StreamController<LabFeed>.broadcast(
      onListen: () {
        LabFeedLog.event('ui.subscribe');
        final last = _lastPromptFeed;
        if (last != null) {
          final ctrl = _promptFeedCtrl;
          if (ctrl != null && !ctrl.isClosed) {
            ctrl.add(last);
          }
        }
      },
    );
    _promptStream ??= _promptFeedCtrl!.stream;
    _ensurePromptFeedListening();
    return _promptStream!;
  }

  @override
  Future<Map<String, int>> fetchEntryCounts(Iterable<String> promptIds) async {
    final ids = promptIds.toList();
    if (ids.isEmpty) return {};
    final counts = <String, int>{};
    await Future.wait(
      ids.map((id) async {
        counts[id] = await _visibleEntryCount(id);
      }),
    );
    return counts;
  }

  Future<int> _visibleEntryCount(String promptId) async {
    try {
      final snap = await _prompts
          .doc(promptId)
          .collection('entries')
          .where('hidden', isEqualTo: false)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<Set<String>> fetchJoinedPromptIds(Iterable<String> promptIds) async {
    final me = uid;
    final ids = promptIds.toList();
    if (me == null || ids.isEmpty) return {};
    final joined = <String>{};
    await Future.wait(
      ids.map((promptId) async {
        try {
          final doc = await _prompts
              .doc(promptId)
              .collection('entries')
              .doc(me)
              .get();
          if (doc.exists && doc.data()?['hidden'] != true) {
            joined.add(promptId);
          }
        } catch (error) {
          LabFeedLog.event('joinedSet.oneFailed', {
            'promptId': promptId,
            'error': error,
          });
        }
      }),
    );
    LabFeedLog.event('joinedSet', {
      'checked': ids.length,
      'count': joined.length,
    });
    return joined;
  }

  @override
  Stream<PromptBoard> watchBoard(String promptId) {
    return _boardStreams.putIfAbsent(
      promptId,
      () => Stream<PromptBoard>.multi((listener) {
        var cancelled = false;
        var entries = <_RemoteEntry>[];
        var ballots = <_Ballot>[];
        var gotEntries = false;
        var failed = false;
        LabPrompt? prompt;
        StreamSubscription<dynamic>? entrySub;
        StreamSubscription<dynamic>? ballotSub;
        StreamSubscription<dynamic>? promptSub;
        listener.onCancel = () {
          cancelled = true;
          entrySub?.cancel();
          ballotSub?.cancel();
          promptSub?.cancel();
        };
        void emit() {
          if (cancelled || !gotEntries) return;
          listener.add(_board(promptId, prompt, entries, ballots, failed));
        }

        unawaited(() async {
          await _ensureUser();
          if (cancelled) return;
          promptSub = _prompts.doc(promptId).snapshots().listen((doc) {
            if (doc.exists) prompt = _promptFrom(doc);
            emit();
          });
          entrySub = _prompts
              .doc(promptId)
              .collection('entries')
              .where('hidden', isEqualTo: false)
              .snapshots()
              .listen(
                (snapshot) {
                  entries = [for (final doc in snapshot.docs) _entryFrom(doc)]
                      .whereType<_RemoteEntry>()
                      .toList();
                  gotEntries = true;
                  emit();
                },
                onError: (Object error) {
                  debugPrint('lab entries failed: $error');
                  failed = true;
                  gotEntries = true;
                  emit();
                },
              );
          ballotSub = _prompts
              .doc(promptId)
              .collection('ballots')
              .snapshots()
              .listen(
                (snapshot) {
                  ballots = [for (final doc in snapshot.docs) _ballotFrom(doc)]
                      .whereType<_Ballot>()
                      .toList();
                  emit();
                },
                onError: (Object error) {
                  debugPrint('lab ballots failed: $error');
                  failed = true;
                  ballots = [];
                  emit();
                },
              );
        }());
      }),
    );
  }

  @override
  Stream<List<LabProposal>> watchProposals() {
    return _proposalStream ??= Stream<List<LabProposal>>.multi((listener) {
      var cancelled = false;
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;
      listener.onCancel = () {
        cancelled = true;
        sub?.cancel();
      };
      unawaited(() async {
        final me = await _ensureUser();
        if (cancelled || me == null) {
          if (!cancelled) listener.add(const []);
          return;
        }
        final query = canReview
            ? _proposals
            : _proposals.where('authorUid', isEqualTo: me);
        sub = query.snapshots().listen(
          (snapshot) {
            final items =
                [for (final doc in snapshot.docs) _proposalFrom(doc)]
                    .whereType<LabProposal>()
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            if (!cancelled) listener.add(items);
          },
          onError: (Object error) {
            debugPrint('lab proposals failed: $error');
            if (!cancelled) listener.add(const []);
          },
        );
      }());
    });
  }

  @override
  Stream<List<LabReport>> watchReports() {
    return _reportStream ??= Stream<List<LabReport>>.multi((listener) {
      if (!canReview) {
        scheduleMicrotask(() => listener.add(const []));
        return;
      }
      var cancelled = false;
      final sub = _reports.snapshots().listen(
        (snapshot) {
          final items =
              [for (final doc in snapshot.docs) _reportFrom(doc)]
                  .whereType<LabReport>()
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (!cancelled) listener.add(items);
        },
        onError: (Object error) {
          debugPrint('lab reports failed: $error');
          if (!cancelled) listener.add(const []);
        },
      );
      listener.onCancel = () {
        cancelled = true;
        sub.cancel();
      };
    });
  }

  @override
  Future<LabOutcome> submitText(String promptId, String text) async {
    final failure = validateAnswer(text);
    if (failure != null) return LabOutcome.fail(failure);
    final prompt = await _loadPrompt(promptId);
    if (prompt == null) return const LabOutcome.fail(LabFailure.invalid);
    if (!labTakesText(prompt.format))
      return const LabOutcome.fail(LabFailure.invalid);
    return _createEntry(prompt, text: text.trim(), choiceIndex: null);
  }

  @override
  Future<LabOutcome> submitPhoto(String promptId, String localImagePath) async {
    if (localImagePath.trim().isEmpty) {
      return const LabOutcome.fail(LabFailure.photo);
    }
    final prompt = await _loadPrompt(promptId);
    if (prompt == null) return const LabOutcome.fail(LabFailure.invalid);
    if (!labTakesPhoto(prompt.format)) {
      return const LabOutcome.fail(LabFailure.invalid);
    }
    if (!isAccepting(prompt, now())) {
      return const LabOutcome.fail(LabFailure.closed);
    }
    final me = await _ensureUser();
    if (me == null) return const LabOutcome.fail(LabFailure.offline);
    final ref = _prompts.doc(prompt.id).collection('entries').doc(me);
    final existing = await ref.get();
    if (existing.exists) return const LabOutcome.fail(LabFailure.already);
    try {
      final storageRef = FirebaseStorage.instance.ref(
        'labEntries/${prompt.id}/$me.jpg',
      );
      await storageRef.putFile(
        File(localImagePath),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final imageUrl = await storageRef.getDownloadURL();
      final author = await _entryAuthor(me);
      await ref.set({
        'uid': me,
        'name': author.name,
        if (author.avatarUrl != null) 'avatarUrl': author.avatarUrl,
        'text': '',
        'imageUrl': imageUrl,
        'hidden': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const LabOutcome.ok();
    } catch (error) {
      debugPrint('lab photo submit failed: $error');
      return const LabOutcome.fail(LabFailure.offline);
    }
  }

  @override
  Future<LabOutcome> submitChoice(String promptId, int index) async {
    final prompt = await _loadPrompt(promptId);
    if (prompt == null) return const LabOutcome.fail(LabFailure.invalid);
    if (prompt.format != LabFormat.quiz && prompt.format != LabFormat.choice) {
      return const LabOutcome.fail(LabFailure.invalid);
    }
    if (index < 0 || index >= prompt.choices.length)
      return const LabOutcome.fail(LabFailure.invalid);
    return _createEntry(
      prompt,
      text: prompt.choices[index],
      choiceIndex: index,
    );
  }

  Future<LabOutcome> _createEntry(
    LabPrompt prompt, {
    required String text,
    required int? choiceIndex,
  }) async {
    if (labTakesPhoto(prompt.format)) {
      return const LabOutcome.fail(LabFailure.invalid);
    }
    if (!isAccepting(prompt, now()))
      return const LabOutcome.fail(LabFailure.closed);
    final me = await _ensureUser();
    if (me == null) return const LabOutcome.fail(LabFailure.offline);
    final ref = _prompts.doc(prompt.id).collection('entries').doc(me);
    final existing = await ref.get();
    if (existing.exists) return const LabOutcome.fail(LabFailure.already);
    try {
      final author = await _entryAuthor(me);
      await ref.set({
        'uid': me,
        'name': author.name,
        if (author.avatarUrl != null) 'avatarUrl': author.avatarUrl,
        'text': text,
        'choiceIndex': ?choiceIndex,
        'hidden': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const LabOutcome.ok();
    } catch (error) {
      debugPrint('lab submit failed: $error');
      return const LabOutcome.fail(LabFailure.offline);
    }
  }

  @override
  Future<LabOutcome> toggleVote(String promptId, String entryUid) async {
    final me = await _ensureUser();
    if (me == null) return const LabOutcome.fail(LabFailure.offline);
    if (entryUid == me) return const LabOutcome.fail(LabFailure.selfVote);
    final ballot = _prompts
        .doc(promptId)
        .collection('ballots')
        .doc('${me}_$entryUid');
    try {
      final existing = await ballot.get();
      if (existing.exists) {
        await ballot.delete();
      } else {
        await ballot.set({
          'voterUid': me,
          'entryUid': entryUid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return const LabOutcome.ok();
    } catch (error) {
      debugPrint('lab vote failed: $error');
      return const LabOutcome.fail(LabFailure.offline);
    }
  }

  @override
  Future<LabOutcome> report(String promptId, String entryUid) async {
    final me = await _ensureUser();
    if (me == null) return const LabOutcome.fail(LabFailure.offline);
    final id = '${promptId}_${entryUid}_$me';
    final ref = _reports.doc(id);
    try {
      final existing = await ref.get();
      if (existing.exists) return const LabOutcome.fail(LabFailure.already);
      await ref.set({
        'promptId': promptId,
        'entryUid': entryUid,
        'reporterUid': me,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const LabOutcome.ok();
    } catch (error) {
      debugPrint('lab report failed: $error');
      return const LabOutcome.fail(LabFailure.offline);
    }
  }

  @override
  Future<LabOutcome> propose(LabDraft draft) async {
    final failure = validateDraft(draft, publishing: false);
    if (failure != null) return LabOutcome.fail(failure);
    final me = await _ensureUser();
    if (me == null) return const LabOutcome.fail(LabFailure.offline);
    try {
      await _proposals.doc(newId()).set({
        'title': draft.title.trim(),
        'body': draft.body.trim(),
        'category': draft.category.name,
        'format': draft.format.name,
        'status': ProposalStatus.pending.name,
        'authorUid': me,
        'choices': draft.cleanedChoices,
        'correctIndex': ?draft.correctIndex,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const LabOutcome.ok();
    } catch (error) {
      debugPrint('lab propose failed: $error');
      return const LabOutcome.fail(LabFailure.offline);
    }
  }

  @override
  Future<LabOutcome> setProposalStatus(String id, ProposalStatus status) async {
    if (!canReview) return const LabOutcome.fail(LabFailure.forbidden);
    try {
      await _proposals.doc(id).update({'status': status.name});
      return const LabOutcome.ok();
    } catch (error) {
      debugPrint('lab review failed: $error');
      return const LabOutcome.fail(LabFailure.offline);
    }
  }

  @override
  Future<LabOutcome> publishProposal(String id, LabDraft draft) async {
    if (!canReview) return const LabOutcome.fail(LabFailure.forbidden);
    final published = await publishPrompt(draft);
    if (!published.ok) return published;
    return setProposalStatus(id, ProposalStatus.accepted);
  }

  @override
  Future<LabOutcome> publishPrompt(LabDraft draft) async {
    if (!canReview) return const LabOutcome.fail(LabFailure.forbidden);
    final failure = validateDraft(draft, publishing: true);
    if (failure != null) return LabOutcome.fail(failure);
    try {
      final data = <String, Object?>{
        'title': draft.title.trim(),
        'body': draft.body.trim(),
        'category': draft.category.name,
        'format': draft.format.name,
        'phase': LabPhase.open.name,
        'featured': draft.featured,
        'choices': draft.cleanedChoices,
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (draft.format == LabFormat.quiz && draft.correctIndex != null) {
        data['correctIndex'] = draft.correctIndex;
      }
      await _prompts.doc(newId()).set(data);
      return const LabOutcome.ok();
    } catch (error) {
      debugPrint('lab publish failed: $error');
      return const LabOutcome.fail(LabFailure.offline);
    }
  }

  @override
  Future<LabOutcome> upsertPrompt(String id, LabDraft draft) async {
    if (!canReview) return const LabOutcome.fail(LabFailure.forbidden);
    final failure = validateDraft(draft, publishing: true);
    if (failure != null) return LabOutcome.fail(failure);
    try {
      final data = <String, Object?>{
        'title': draft.title.trim(),
        'body': draft.body.trim(),
        'category': draft.category.name,
        'format': draft.format.name,
        'phase': LabPhase.open.name,
        'featured': draft.featured,
        'choices': draft.cleanedChoices,
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (draft.format == LabFormat.quiz && draft.correctIndex != null) {
        data['correctIndex'] = draft.correctIndex;
      }
      await _prompts.doc(id).set(data, SetOptions(merge: true));
      return const LabOutcome.ok();
    } catch (error) {
      debugPrint('lab upsert failed: $error');
      return const LabOutcome.fail(LabFailure.offline);
    }
  }

  @override
  Future<LabOutcome> setEntryHidden(
    String promptId,
    String entryUid,
    bool hidden,
  ) async {
    if (!canReview) return const LabOutcome.fail(LabFailure.forbidden);
    try {
      await _prompts.doc(promptId).collection('entries').doc(entryUid).update({
        'hidden': hidden,
      });
      return const LabOutcome.ok();
    } catch (error) {
      debugPrint('lab hide failed: $error');
      return const LabOutcome.fail(LabFailure.offline);
    }
  }

  @override
  Future<LabOutcome> deleteEntry(String promptId, String entryUid) async {
    if (!canReview) return const LabOutcome.fail(LabFailure.forbidden);
    try {
      final entryRef = _prompts
          .doc(promptId)
          .collection('entries')
          .doc(entryUid);
      final ballotSnap = await _prompts
          .doc(promptId)
          .collection('ballots')
          .where('entryUid', isEqualTo: entryUid)
          .get();
      final batch = _db.batch();
      for (final doc in ballotSnap.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(entryRef);
      await batch.commit();
      return const LabOutcome.ok();
    } catch (error) {
      debugPrint('lab delete entry failed: $error');
      return const LabOutcome.fail(LabFailure.offline);
    }
  }

  @override
  Stream<VentFeed> watchVents() {
    return Stream<VentFeed>.multi((controller) {
      var cancelled = false;
      var generation = 0;
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subscription;
      controller.add(const VentFeed(loading: true));
      controller.onCancel = () {
        cancelled = true;
        subscription?.cancel();
      };
      unawaited(() async {
        final me = await _ensureUser();
        if (cancelled) return;
        if (me == null) {
          controller.add(const VentFeed(remoteFailed: true));
          return;
        }
        final feedQuery = _db
            .collection('ventPosts')
            .where(
              'expiresAt',
              isGreaterThan: Timestamp.fromDate(
                now().add(_ventExpiryReadBuffer),
              ),
            )
            .orderBy('expiresAt')
            .orderBy('createdAt', descending: true);
        subscription = feedQuery
            .limit(30)
            .snapshots()
            .listen(
              (snapshot) {
                final current = ++generation;
                unawaited(() async {
                  try {
                    final posts = await Future.wait(
                      snapshot.docs.map((doc) => _ventPost(doc, me)),
                    );
                    var count = posts.length;
                    try {
                      count =
                          (await feedQuery.count().get()).count ?? posts.length;
                    } catch (error) {
                      debugPrint('vent count fetch failed: $error');
                    }
                    if (!cancelled && current == generation) {
                      controller.add(VentFeed(posts: posts, count: count));
                    }
                  } catch (error) {
                    debugPrint('vent feed parse failed: $error');
                    if (!cancelled && current == generation) {
                      controller.add(const VentFeed(remoteFailed: true));
                    }
                  }
                }());
              },
              onError: (Object error) {
                debugPrint('vent feed failed: $error');
                if (!cancelled) {
                  controller.add(const VentFeed(remoteFailed: true));
                }
              },
            );
      }());
    });
  }

  Future<VentPost> _ventPost(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String me,
  ) async {
    final data = _plain(doc.data());
    final reactionFuture = doc.reference.collection('reactions').doc(me).get();
    final ownerFuture = _db
        .collection('ventOwners')
        .doc(me)
        .collection('ventOwnerPosts')
        .doc(doc.id)
        .get();
    final reaction = await reactionFuture;
    final owner = await ownerFuture;
    final reactionName = reaction.data()?['type'] as String?;
    final createdAt = data['createdAt'];
    final expiresAt = data['expiresAt'];
    return VentPost(
      id: doc.id,
      text: data['text'] as String? ?? '',
      createdAt: createdAt is DateTime
          ? createdAt
          : DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt: expiresAt is DateTime
          ? expiresAt
          : DateTime.fromMillisecondsSinceEpoch(0),
      relateCount: (data['relateCount'] as num?)?.toInt() ?? 0,
      cheerCount: (data['cheerCount'] as num?)?.toInt() ?? 0,
      mine: owner.exists,
      myReaction: switch (reactionName) {
        'relate' => VentReaction.relate,
        'cheer' => VentReaction.cheer,
        _ => null,
      },
    );
  }

  @override
  Future<LabOutcome> submitVent(String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return const LabOutcome.fail(LabFailure.empty);
    if (cleaned.length > 140) {
      return const LabOutcome.fail(LabFailure.tooLong);
    }
    final me = await _ensureUser();
    if (me == null) return const LabOutcome.fail(LabFailure.offline);
    final createdAt = now();
    try {
      final id = newId();
      final expiresAt = Timestamp.fromDate(
        createdAt.add(const Duration(hours: 24)),
      );
      final postRef = _db.collection('ventPosts').doc(id);
      final ownerRef = _db
          .collection('ventOwners')
          .doc(me)
          .collection('ventOwnerPosts')
          .doc(id);
      final batch = _db.batch();
      batch.set(postRef, {
        'text': cleaned,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
        'relateCount': 0,
        'cheerCount': 0,
      });
      batch.set(ownerRef, {
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
      });
      await batch.commit();
      return const LabOutcome.ok();
    } catch (error) {
      debugPrint('vent submit failed: $error');
      return const LabOutcome.fail(LabFailure.offline);
    }
  }

  @override
  Future<LabOutcome> toggleVentReaction(
    String postId,
    VentReaction reaction,
  ) async {
    final me = await _ensureUser();
    if (me == null) return const LabOutcome.fail(LabFailure.offline);
    final postRef = _db.collection('ventPosts').doc(postId);
    final reactionRef = postRef.collection('reactions').doc(me);
    final ownerRef = _db
        .collection('ventOwners')
        .doc(me)
        .collection('ventOwnerPosts')
        .doc(postId);
    try {
      await _db.runTransaction((transaction) async {
        final post = await transaction.get(postRef);
        if (!post.exists) throw StateError('missing-vent');
        final postData = post.data()!;
        final owner = await transaction.get(ownerRef);
        if (owner.exists) throw StateError('own-vent');
        final reactionDoc = await transaction.get(reactionRef);
        final previous = reactionDoc.data()?['type'] as String?;
        final selected = reaction.name;
        var relateCount = (postData['relateCount'] as num?)?.toInt() ?? 0;
        var cheerCount = (postData['cheerCount'] as num?)?.toInt() ?? 0;
        if (previous == selected) {
          transaction.delete(reactionRef);
          if (previous == VentReaction.relate.name) relateCount--;
          if (previous == VentReaction.cheer.name) cheerCount--;
        } else {
          transaction.set(reactionRef, {
            'type': selected,
            'expiresAt': postData['expiresAt'],
          });
          if (previous == VentReaction.relate.name) relateCount--;
          if (previous == VentReaction.cheer.name) cheerCount--;
          if (selected == VentReaction.relate.name) relateCount++;
          if (selected == VentReaction.cheer.name) cheerCount++;
        }
        transaction.update(postRef, {
          'relateCount': relateCount,
          'cheerCount': cheerCount,
        });
      });
      return const LabOutcome.ok();
    } catch (error) {
      debugPrint('vent reaction failed: $error');
      if (error is StateError && error.message == 'own-vent') {
        return const LabOutcome.fail(LabFailure.selfVote);
      }
      return const LabOutcome.fail(LabFailure.offline);
    }
  }

  @override
  Future<LabOutcome> deleteVent(String postId) async {
    final me = await _ensureUser();
    if (me == null) return const LabOutcome.fail(LabFailure.offline);
    try {
      final ref = _db.collection('ventPosts').doc(postId);
      final doc = await ref.get();
      if (!doc.exists) return const LabOutcome.fail(LabFailure.invalid);
      final ownerRef = _db
          .collection('ventOwners')
          .doc(me)
          .collection('ventOwnerPosts')
          .doc(postId);
      if (!(await ownerRef.get()).exists) {
        return const LabOutcome.fail(LabFailure.forbidden);
      }
      final batch = _db.batch();
      batch.delete(ref);
      batch.delete(ownerRef);
      await batch.commit();
      return const LabOutcome.ok();
    } catch (error) {
      debugPrint('vent delete failed: $error');
      return const LabOutcome.fail(LabFailure.offline);
    }
  }

  @override
  Future<LabOutcome> reportVent(String postId) async {
    final me = await _ensureUser();
    if (me == null) return const LabOutcome.fail(LabFailure.offline);
    try {
      final post = await _db.collection('ventPosts').doc(postId).get();
      if (!post.exists) return const LabOutcome.fail(LabFailure.invalid);
      final owner = await _db
          .collection('ventOwners')
          .doc(me)
          .collection('ventOwnerPosts')
          .doc(postId)
          .get();
      if (owner.exists) {
        return const LabOutcome.fail(LabFailure.selfVote);
      }
      final reportRef = _db.collection('ventReports').doc('${postId}_$me');
      await reportRef.set({
        'postId': postId,
        'reporterUid': me,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': post.data()?['expiresAt'],
      });
      return const LabOutcome.ok();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied' || error.code == 'already-exists') {
        return const LabOutcome.fail(LabFailure.already);
      }
      debugPrint('vent report failed: $error');
      return const LabOutcome.fail(LabFailure.offline);
    } catch (error) {
      debugPrint('vent report failed: $error');
      return const LabOutcome.fail(LabFailure.offline);
    }
  }

  @override
  Future<void> deleteMyVents() async {
    final me = await _ensureUser();
    if (me == null) return;
    final owners = await _db
        .collection('ventOwners')
        .doc(me)
        .collection('ventOwnerPosts')
        .where(
          'expiresAt',
          isGreaterThan: Timestamp.fromDate(now().add(_ventExpiryReadBuffer)),
        )
        .get();
    for (var offset = 0; offset < owners.docs.length; offset += 5) {
      final batch = _db.batch();
      for (final owner in owners.docs.skip(offset).take(5)) {
        batch.delete(_db.collection('ventPosts').doc(owner.id));
        batch.delete(owner.reference);
      }
      await batch.commit();
    }
  }

  Future<({String name, String? avatarUrl})> _entryAuthor(String uid) async {
    final remote = await profileRemote?.fetch(uid);
    if (remote != null &&
        remote.nick.isNotEmpty &&
        validateLabNick(remote.nick) == null) {
      return (name: remote.nick, avatarUrl: remote.avatarUrl);
    }
    return (
      name: profileCache.displayNameFor(uid),
      avatarUrl: profileCache.avatarFor(uid),
    );
  }

  Future<String?> _ensureUser() async {
    final existing = auth.current;
    if (existing != null) return existing.uid;
    try {
      return (await auth.ensureSignedIn()).uid;
    } catch (error, stack) {
      LabFeedLog.event('auth.failed', {'error': error});
      debugPrint('lab auth failed: $error\n$stack');
      return null;
    }
  }

  Future<LabPrompt?> _loadPrompt(String id) async {
    try {
      final doc = await _prompts.doc(id).get();
      if (!doc.exists) return null;
      return _promptFrom(doc);
    } catch (_) {
      return null;
    }
  }

  PromptBoard _board(
    String promptId,
    LabPrompt? prompt,
    List<_RemoteEntry> entries,
    List<_Ballot> ballots,
    bool failed,
  ) {
    final me = uid;
    final voters = <String, Set<String>>{};
    for (final ballot in ballots) {
      voters.putIfAbsent(ballot.entryUid, () => {}).add(ballot.voterUid);
    }
    final view = [
      for (final entry in entries)
        LabEntry(
          uid: entry.uid,
          name: entry.name,
          text: entry.text,
          imageUrl: entry.imageUrl,
          avatarUrl: entry.avatarUrl,
          choiceIndex: entry.choiceIndex,
          createdAt: entry.createdAt,
          hidden: entry.hidden,
          votes: voters[entry.uid]?.length ?? 0,
          voted: me != null && (voters[entry.uid]?.contains(me) ?? false),
          mine: entry.uid == me,
        ),
    ]..sort(compareEntries);
    return PromptBoard(
      prompt: prompt?.copyWith(
        entryCount: view.where((entry) => !entry.hidden).length,
      ),
      entries: view,
      remoteFailed: failed,
    );
  }

  LabPrompt? _promptFrom(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    return parsePrompt(doc.id, _plain(data));
  }

  _RemoteEntry? _entryFrom(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = _plain(doc.data());
    final text = data['text'];
    final name = data['name'];
    final owner = data['uid'];
    if (text is! String || name is! String || owner is! String) return null;
    final image = data['imageUrl'];
    final avatar = data['avatarUrl'];
    final choice = data['choiceIndex'];
    final created = data['createdAt'];
    return _RemoteEntry(
      uid: owner,
      name: name,
      text: text,
      imageUrl: image is String && image.isNotEmpty ? image : null,
      avatarUrl: avatar is String && avatar.isNotEmpty ? avatar : null,
      choiceIndex: choice is int ? choice : null,
      createdAt: created is DateTime
          ? created
          : DateTime.fromMillisecondsSinceEpoch(0),
      hidden: data['hidden'] == true,
    );
  }

  _Ballot? _ballotFrom(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final voter = data['voterUid'];
    final entry = data['entryUid'];
    if (voter is! String || entry is! String) return null;
    return _Ballot(voter, entry);
  }

  LabProposal? _proposalFrom(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = _plain(doc.data());
    final title = data['title'];
    final body = data['body'];
    final author = data['authorUid'];
    final category = labCategoryFrom(data['category'] as String?);
    final format = labFormatFrom(data['format'] as String?);
    final status = proposalStatusFrom(data['status'] as String?);
    if (title is! String ||
        body is! String ||
        author is! String ||
        category == null ||
        format == null ||
        status == null) {
      return null;
    }
    final rawChoices = data['choices'];
    final correct = data['correctIndex'];
    final created = data['createdAt'];
    return LabProposal(
      id: doc.id,
      title: title,
      body: body,
      category: category,
      format: format,
      status: status,
      authorUid: author,
      createdAt: created is DateTime
          ? created
          : DateTime.fromMillisecondsSinceEpoch(0),
      choices: [
        for (final item in rawChoices is List ? rawChoices : const [])
          if (item is String) item,
      ],
      correctIndex: correct is int ? correct : null,
    );
  }

  LabReport? _reportFrom(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = _plain(doc.data());
    final promptId = data['promptId'];
    final entryUid = data['entryUid'];
    final reporter = data['reporterUid'];
    if (promptId is! String || entryUid is! String || reporter is! String)
      return null;
    final created = data['createdAt'];
    return LabReport(
      id: doc.id,
      promptId: promptId,
      entryUid: entryUid,
      reporterUid: reporter,
      createdAt: created is DateTime
          ? created
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, Object?> _plain(Map<String, dynamic> data) {
    return {
      for (final entry in data.entries)
        entry.key: entry.value is Timestamp
            ? (entry.value as Timestamp).toDate()
            : entry.value,
    };
  }
}

class _RemoteEntry {
  const _RemoteEntry({
    required this.uid,
    required this.name,
    required this.text,
    required this.createdAt,
    this.choiceIndex,
    this.hidden = false,
    this.imageUrl,
    this.avatarUrl,
  });

  final String uid;
  final String name;
  final String text;
  final String? imageUrl;
  final String? avatarUrl;
  final int? choiceIndex;
  final DateTime createdAt;
  final bool hidden;
}

class _Ballot {
  const _Ballot(this.voterUid, this.entryUid);

  final String voterUid;
  final String entryUid;
}
