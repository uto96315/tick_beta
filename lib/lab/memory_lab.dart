import 'dart:async';

import 'package:tick/lab/lab_store.dart';
import 'package:tick/lab/logic.dart';
import 'package:tick/lab/models.dart';
import 'package:tick/lab/profile.dart';

class LabBox {
  final prompts = <String, LabPrompt>{};
  final entries = <String, Map<String, _StoredEntry>>{};
  final votes = <String, Map<String, Set<String>>>{};
  final proposals = <String, LabProposal>{};
  final reports = <String, LabReport>{};
  final _listeners = <void Function()>{};

  void listen(void Function() listener) => _listeners.add(listener);

  void unlisten(void Function() listener) => _listeners.remove(listener);

  void notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }
}

class _StoredEntry {
  _StoredEntry({
    required this.uid,
    required this.name,
    required this.text,
    required this.createdAt,
    this.choiceIndex,
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
  bool hidden = false;
}

class MemoryLabStore implements LabStore {
  MemoryLabStore({
    required this.uid,
    required this.newId,
    required LabBox box,
    required this.languageCode,
    DateTime Function()? now,
    this.canReview = false,
    this.sharesWithOthers = false,
    LabProfileCache? profileCache,
  }) : _box = box,
       _profileCache = profileCache,
       now = now ?? DateTime.now;

  MemoryLabStore.solo({
    required String uid,
    required String Function() newId,
    String Function()? languageCode,
    DateTime Function()? now,
    bool canReview = false,
    bool sharesWithOthers = false,
    LabProfileCache? profileCache,
  }) : this(
         uid: uid,
         newId: newId,
         box: LabBox(),
         languageCode: languageCode ?? (() => 'ja'),
         now: now,
         canReview: canReview,
         sharesWithOthers: sharesWithOthers,
         profileCache: profileCache,
       );

  @override
  final String uid;

  final String Function() newId;
  final String Function() languageCode;
  final DateTime Function() now;
  final LabBox _box;
  final LabProfileCache? _profileCache;

  @override
  final bool canReview;

  @override
  final bool sharesWithOthers;

  LabFeed? _cachedFeed;
  Stream<LabFeed>? _prompts;

  @override
  LabFeed? get cachedPromptFeed => _cachedFeed;
  final _boards = <String, Stream<PromptBoard>>{};
  Stream<List<LabProposal>>? _proposals;
  Stream<List<LabReport>>? _reports;

  Stream<T> _live<T>(T Function() read) {
    return Stream<T>.multi((listener) {
      var cancelled = false;
      void emit() {
        if (cancelled) return;
        listener.add(read());
      }

      _box.listen(emit);
      listener.onCancel = () {
        cancelled = true;
        _box.unlisten(emit);
      };
      scheduleMicrotask(() {
        if (!cancelled) listener.add(read());
      });
    });
  }

  @override
  void refreshPromptFeed() {}

  @override
  @override
  Future<Map<String, int>> fetchEntryCounts(Iterable<String> promptIds) async {
    final counts = <String, int>{};
    for (final id in promptIds) {
      counts[id] = _visibleCount(id);
    }
    return counts;
  }

  @override
  Future<Set<String>> fetchJoinedPromptIds(Iterable<String> promptIds) async {
    final me = uid;
    if (me == null) return {};
    final joined = <String>{};
    for (final promptId in promptIds) {
      final entry = _box.entries[promptId]?[me];
      if (entry != null && !entry.hidden) joined.add(promptId);
    }
    return joined;
  }

  @override
  Stream<LabFeed> watchPrompts() {
    return _prompts ??= _live(() {
      final prompts = [
        for (final prompt in _box.prompts.values)
          prompt.copyWith(
            entryCount: _visibleCount(prompt.id),
            joined: () {
              final entry = _box.entries[prompt.id]?[uid];
              return entry != null && !entry.hidden;
            }(),
          ),
      ];
      final feed = LabFeed(prompts: sortLabPrompts(prompts));
      _cachedFeed = feed;
      return feed;
    });
  }

  @override
  Stream<PromptBoard> watchBoard(String promptId) {
    return _boards.putIfAbsent(promptId, () => _live(() => _board(promptId)));
  }

  @override
  Stream<List<LabProposal>> watchProposals() {
    return _proposals ??= _live(() {
      final items =
          _box.proposals.values
              .where((proposal) => canReview || proposal.authorUid == uid)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  @override
  Stream<List<LabReport>> watchReports() {
    return _reports ??= _live(() {
      if (!canReview) return const <LabReport>[];
      final items = _box.reports.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  int _visibleCount(String promptId) {
    final entries = _box.entries[promptId];
    if (entries == null) return 0;
    return entries.values.where((entry) => !entry.hidden).length;
  }

  LabPrompt? _prompt(String promptId) {
    return _box.prompts[promptId];
  }

  ({String name, String? avatarUrl}) _entryAuthor(String userId) {
    final cache = _profileCache;
    if (cache != null && userId == uid) {
      return (
        name: cache.displayNameFor(userId),
        avatarUrl: cache.avatarFor(userId),
      );
    }
    return (name: labName(userId), avatarUrl: null);
  }

  PromptBoard _board(String promptId) {
    final prompt = _prompt(promptId);
    final stored =
        _box.entries[promptId]?.values ?? const Iterable<_StoredEntry>.empty();
    final votes = _box.votes[promptId] ?? const <String, Set<String>>{};
    final entries = [
      for (final entry in stored)
        if (!entry.hidden || canReview)
          LabEntry(
            uid: entry.uid,
            name: entry.name,
            text: entry.text,
            imageUrl: entry.imageUrl,
            avatarUrl: entry.avatarUrl,
            choiceIndex: entry.choiceIndex,
            createdAt: entry.createdAt,
            hidden: entry.hidden,
            votes: votes[entry.uid]?.length ?? 0,
            voted: votes[entry.uid]?.contains(uid) ?? false,
            mine: entry.uid == uid,
          ),
    ]..sort(compareEntries);
    final shown = prompt?.copyWith(
      entryCount: entries.where((entry) => !entry.hidden).length,
    );
    return PromptBoard(prompt: shown, entries: entries);
  }

  @override
  Future<LabOutcome> submitText(String promptId, String text) async {
    final failure = validateAnswer(text);
    if (failure != null) return LabOutcome.fail(failure);
    return _submit(promptId, text: text.trim(), choiceIndex: null);
  }

  @override
  Future<LabOutcome> submitPhoto(String promptId, String localImagePath) async {
    if (localImagePath.trim().isEmpty) {
      return const LabOutcome.fail(LabFailure.photo);
    }
    final prompt = _prompt(promptId);
    if (prompt == null) return const LabOutcome.fail(LabFailure.invalid);
    if (!labTakesPhoto(prompt.format)) {
      return const LabOutcome.fail(LabFailure.invalid);
    }
    if (!isAccepting(prompt, now())) {
      return const LabOutcome.fail(LabFailure.closed);
    }
    final existing = _box.entries[promptId];
    if (existing != null && existing.containsKey(uid)) {
      return const LabOutcome.fail(LabFailure.already);
    }
    final author = _entryAuthor(uid);
    _box.entries.putIfAbsent(promptId, () => {})[uid] = _StoredEntry(
      uid: uid,
      name: author.name,
      text: '',
      imageUrl: localImagePath,
      avatarUrl: author.avatarUrl,
      choiceIndex: null,
      createdAt: now(),
    );
    _box.notify();
    return const LabOutcome.ok();
  }

  @override
  Future<LabOutcome> submitChoice(String promptId, int index) async {
    final prompt = _prompt(promptId);
    if (prompt == null) return const LabOutcome.fail(LabFailure.invalid);
    if (index < 0 || index >= prompt.choices.length)
      return const LabOutcome.fail(LabFailure.invalid);
    return _submit(promptId, text: prompt.choices[index], choiceIndex: index);
  }

  LabOutcome _submit(
    String promptId, {
    required String text,
    required int? choiceIndex,
  }) {
    final prompt = _prompt(promptId);
    if (prompt == null) return const LabOutcome.fail(LabFailure.invalid);
    if (labTakesPhoto(prompt.format)) {
      return const LabOutcome.fail(LabFailure.invalid);
    }
    if (!isAccepting(prompt, now()))
      return const LabOutcome.fail(LabFailure.closed);
    final writing = labTakesText(prompt.format);
    if (writing && choiceIndex != null) {
      return const LabOutcome.fail(LabFailure.invalid);
    }
    if (!writing && choiceIndex == null) {
      return const LabOutcome.fail(LabFailure.invalid);
    }
    final existing = _box.entries[promptId];
    if (existing != null && existing.containsKey(uid))
      return const LabOutcome.fail(LabFailure.already);
    final author = _entryAuthor(uid);
    _box.entries.putIfAbsent(promptId, () => {})[uid] = _StoredEntry(
      uid: uid,
      name: author.name,
      text: text,
      avatarUrl: author.avatarUrl,
      choiceIndex: choiceIndex,
      createdAt: now(),
    );
    _box.notify();
    return const LabOutcome.ok();
  }

  @override
  Future<LabOutcome> toggleVote(String promptId, String entryUid) async {
    if (entryUid == uid) return const LabOutcome.fail(LabFailure.selfVote);
    final entry = _box.entries[promptId]?[entryUid];
    if (entry == null || entry.hidden)
      return const LabOutcome.fail(LabFailure.invalid);
    final voters = _box.votes
        .putIfAbsent(promptId, () => {})
        .putIfAbsent(entryUid, () => {});
    if (!voters.add(uid)) voters.remove(uid);
    _box.notify();
    return const LabOutcome.ok();
  }

  @override
  Future<LabOutcome> report(String promptId, String entryUid) async {
    if (_box.entries[promptId]?[entryUid] == null)
      return const LabOutcome.fail(LabFailure.invalid);
    final id = '${promptId}_${entryUid}_$uid';
    if (_box.reports.containsKey(id))
      return const LabOutcome.fail(LabFailure.already);
    _box.reports[id] = LabReport(
      id: id,
      promptId: promptId,
      entryUid: entryUid,
      reporterUid: uid,
      createdAt: now(),
    );
    _box.notify();
    return const LabOutcome.ok();
  }

  @override
  Future<LabOutcome> propose(LabDraft draft) async {
    final failure = validateDraft(draft, publishing: false);
    if (failure != null) return LabOutcome.fail(failure);
    final id = newId();
    _box.proposals[id] = LabProposal(
      id: id,
      title: draft.title.trim(),
      body: draft.body.trim(),
      category: draft.category,
      format: draft.format,
      status: ProposalStatus.pending,
      authorUid: uid,
      createdAt: now(),
      choices: draft.cleanedChoices,
      correctIndex: draft.correctIndex,
    );
    _box.notify();
    return const LabOutcome.ok();
  }

  @override
  Future<LabOutcome> setProposalStatus(String id, ProposalStatus status) async {
    if (!canReview) return const LabOutcome.fail(LabFailure.forbidden);
    final proposal = _box.proposals[id];
    if (proposal == null) return const LabOutcome.fail(LabFailure.invalid);
    _box.proposals[id] = LabProposal(
      id: proposal.id,
      title: proposal.title,
      body: proposal.body,
      category: proposal.category,
      format: proposal.format,
      status: status,
      authorUid: proposal.authorUid,
      createdAt: proposal.createdAt,
      choices: proposal.choices,
      correctIndex: proposal.correctIndex,
    );
    _box.notify();
    return const LabOutcome.ok();
  }

  @override
  Future<LabOutcome> publishProposal(String id, LabDraft draft) async {
    if (!canReview) return const LabOutcome.fail(LabFailure.forbidden);
    if (_box.proposals[id] == null)
      return const LabOutcome.fail(LabFailure.invalid);
    final published = await publishPrompt(draft);
    if (!published.ok) return published;
    return setProposalStatus(id, ProposalStatus.accepted);
  }

  @override
  Future<LabOutcome> publishPrompt(LabDraft draft) async {
    if (!canReview) return const LabOutcome.fail(LabFailure.forbidden);
    final failure = validateDraft(draft, publishing: true);
    if (failure != null) return LabOutcome.fail(failure);
    final id = newId();
    _box.prompts[id] = LabPrompt(
      id: id,
      title: draft.title.trim(),
      body: draft.body.trim(),
      category: draft.category,
      format: draft.format,
      phase: LabPhase.open,
      createdAt: now(),
      featured: draft.featured,
      choices: draft.cleanedChoices,
      correctIndex: draft.format == LabFormat.quiz ? draft.correctIndex : null,
    );
    _box.notify();
    return const LabOutcome.ok();
  }

  @override
  Future<LabOutcome> upsertPrompt(String id, LabDraft draft) async {
    if (!canReview) return const LabOutcome.fail(LabFailure.forbidden);
    final failure = validateDraft(draft, publishing: true);
    if (failure != null) return LabOutcome.fail(failure);
    final existing = _box.prompts[id];
    _box.prompts[id] = LabPrompt(
      id: id,
      title: draft.title.trim(),
      body: draft.body.trim(),
      category: draft.category,
      format: draft.format,
      phase: LabPhase.open,
      createdAt: existing?.createdAt ?? now(),
      featured: draft.featured,
      choices: draft.cleanedChoices,
      correctIndex: draft.format == LabFormat.quiz ? draft.correctIndex : null,
      entryCount: existing?.entryCount ?? 0,
      seeded: id.startsWith('seed-'),
    );
    _box.notify();
    return const LabOutcome.ok();
  }

  @override
  Future<LabOutcome> setEntryHidden(
    String promptId,
    String entryUid,
    bool hidden,
  ) async {
    if (!canReview) return const LabOutcome.fail(LabFailure.forbidden);
    final entry = _box.entries[promptId]?[entryUid];
    if (entry == null) return const LabOutcome.fail(LabFailure.invalid);
    entry.hidden = hidden;
    if (hidden) _box.votes[promptId]?[entryUid]?.clear();
    _box.notify();
    return const LabOutcome.ok();
  }

  @override
  Future<LabOutcome> deleteEntry(String promptId, String entryUid) async {
    if (!canReview) return const LabOutcome.fail(LabFailure.forbidden);
    final bucket = _box.entries[promptId];
    if (bucket == null || !bucket.containsKey(entryUid)) {
      return const LabOutcome.fail(LabFailure.invalid);
    }
    bucket.remove(entryUid);
    _box.votes[promptId]?.remove(entryUid);
    _box.notify();
    return const LabOutcome.ok();
  }
}
