import 'dart:async';

import 'package:tick/lab/catalog.dart';
import 'package:tick/lab/lab_store.dart';
import 'package:tick/lab/logic.dart';
import 'package:tick/lab/models.dart';

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
  });

  final String uid;
  final String name;
  final String text;
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
  }) : _box = box,
       now = now ?? DateTime.now;

  MemoryLabStore.solo({
    required String uid,
    required String Function() newId,
    String Function()? languageCode,
    DateTime Function()? now,
    bool canReview = false,
    bool sharesWithOthers = false,
  }) : this(
         uid: uid,
         newId: newId,
         box: LabBox(),
         languageCode: languageCode ?? (() => 'ja'),
         now: now,
         canReview: canReview,
         sharesWithOthers: sharesWithOthers,
       );

  @override
  final String uid;

  final String Function() newId;
  final String Function() languageCode;
  final DateTime Function() now;
  final LabBox _box;

  @override
  final bool canReview;

  @override
  final bool sharesWithOthers;

  Stream<LabFeed>? _prompts;
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
  Stream<LabFeed> watchPrompts() {
    return _prompts ??= _live(() {
      final remote = _box.prompts.values.map((prompt) {
        return prompt.copyWith(entryCount: _visibleCount(prompt.id));
      }).toList();
      final seeds = [
        for (final seed in labSeeds(languageCode()))
          seed.copyWith(entryCount: _visibleCount(seed.id)),
      ];
      return LabFeed(prompts: mergePrompts(seeds, remote));
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
    return _box.prompts[promptId] ?? labSeedById(languageCode(), promptId);
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
    if (prompt.format == LabFormat.draw)
      return const LabOutcome.fail(LabFailure.draw);
    if (!isAccepting(prompt, now()))
      return const LabOutcome.fail(LabFailure.closed);
    if (prompt.format == LabFormat.ogiri && choiceIndex != null) {
      return const LabOutcome.fail(LabFailure.invalid);
    }
    if (prompt.format != LabFormat.ogiri && choiceIndex == null) {
      return const LabOutcome.fail(LabFailure.invalid);
    }
    final existing = _box.entries[promptId];
    if (existing != null && existing.containsKey(uid))
      return const LabOutcome.fail(LabFailure.already);
    _box.entries.putIfAbsent(promptId, () => {})[uid] = _StoredEntry(
      uid: uid,
      name: labName(uid),
      text: text,
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
}
