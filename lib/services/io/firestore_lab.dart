import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tick/lab/catalog.dart';
import 'package:tick/lab/lab_store.dart';
import 'package:tick/lab/logic.dart';
import 'package:tick/lab/models.dart';
import 'package:tick/services/gateways.dart';

class FirestoreLabStore implements LabStore {
  FirestoreLabStore({
    required this.auth,
    required this.newId,
    required this.languageCode,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final AuthGateway auth;
  final String Function() newId;
  final String Function() languageCode;
  final DateTime Function() now;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  String? get uid => auth.current?.uid;

  @override
  bool get canReview => labCanReview(auth.current?.email);

  @override
  bool get sharesWithOthers => true;

  Stream<LabFeed>? _promptStream;
  final _boardStreams = <String, Stream<PromptBoard>>{};
  Stream<List<LabProposal>>? _proposalStream;
  Stream<List<LabReport>>? _reportStream;

  CollectionReference<Map<String, dynamic>> get _prompts =>
      _db.collection('labPrompts');

  CollectionReference<Map<String, dynamic>> get _proposals =>
      _db.collection('labProposals');

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('labReports');

  @override
  Stream<LabFeed> watchPrompts() {
    return _promptStream ??= Stream<LabFeed>.multi((listener) {
      var cancelled = false;
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;
      listener.onCancel = () {
        cancelled = true;
        sub?.cancel();
      };
      scheduleMicrotask(() {
        if (!cancelled) {
          listener.add(
            LabFeed(prompts: mergePrompts(labSeeds(languageCode()), const [])),
          );
        }
      });
      unawaited(() async {
        await _ensureUser();
        if (cancelled) return;
        sub = _prompts.snapshots().listen(
          (snapshot) {
            unawaited(() async {
              final remote = <LabPrompt>[];
              for (final doc in snapshot.docs) {
                final prompt = _promptFrom(doc);
                if (prompt == null) continue;
                remote.add(await _withCount(prompt));
              }
              if (cancelled) return;
              listener.add(
                LabFeed(
                  prompts: mergePrompts(labSeeds(languageCode()), remote),
                ),
              );
            }());
          },
          onError: (Object error) {
            debugPrint('lab prompts failed: $error');
            if (cancelled) return;
            listener.add(
              LabFeed(
                prompts: mergePrompts(labSeeds(languageCode()), const []),
                remoteFailed: true,
              ),
            );
          },
        );
      }());
    });
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
        var gotBallots = false;
        var failed = false;
        LabPrompt? prompt = labSeedById(languageCode(), promptId);
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
          if (cancelled || !gotEntries || !gotBallots) return;
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
                  gotBallots = true;
                  emit();
                },
                onError: (Object error) {
                  debugPrint('lab ballots failed: $error');
                  failed = true;
                  gotBallots = true;
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
    if (prompt.format != LabFormat.ogiri)
      return const LabOutcome.fail(LabFailure.invalid);
    return _createEntry(prompt, text: text.trim(), choiceIndex: null);
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
    if (prompt.format == LabFormat.draw)
      return const LabOutcome.fail(LabFailure.draw);
    if (!isAccepting(prompt, now()))
      return const LabOutcome.fail(LabFailure.closed);
    final me = await _ensureUser();
    if (me == null) return const LabOutcome.fail(LabFailure.offline);
    final ref = _prompts.doc(prompt.id).collection('entries').doc(me);
    final existing = await ref.get();
    if (existing.exists) return const LabOutcome.fail(LabFailure.already);
    try {
      await ref.set({
        'uid': me,
        'name': labName(me),
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

  Future<String?> _ensureUser() async {
    final existing = auth.current;
    if (existing != null) return existing.uid;
    try {
      return (await auth.ensureSignedIn()).uid;
    } catch (error) {
      debugPrint('lab auth failed: $error');
      return null;
    }
  }

  Future<LabPrompt?> _loadPrompt(String id) async {
    final seed = labSeedById(languageCode(), id);
    try {
      final doc = await _prompts.doc(id).get();
      if (!doc.exists) return seed;
      return _promptFrom(doc) ?? seed;
    } catch (_) {
      return seed;
    }
  }

  Future<LabPrompt> _withCount(LabPrompt prompt) async {
    try {
      final count = await _prompts
          .doc(prompt.id)
          .collection('entries')
          .where('hidden', isEqualTo: false)
          .count()
          .get();
      return prompt.copyWith(entryCount: count.count ?? 0);
    } catch (_) {
      return prompt;
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
    final choice = data['choiceIndex'];
    final created = data['createdAt'];
    return _RemoteEntry(
      uid: owner,
      name: name,
      text: text,
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
  });

  final String uid;
  final String name;
  final String text;
  final int? choiceIndex;
  final DateTime createdAt;
  final bool hidden;
}

class _Ballot {
  const _Ballot(this.voterUid, this.entryUid);

  final String voterUid;
  final String entryUid;
}
