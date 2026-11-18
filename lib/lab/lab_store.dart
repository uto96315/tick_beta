import 'package:tick/lab/models.dart';

abstract class LabStore {
  String? get uid;

  bool get canReview;

  bool get sharesWithOthers;

  Stream<LabFeed> watchPrompts();

  /// Last prompt feed event (for new [StreamBuilder]s on the same stream).
  LabFeed? get cachedPromptFeed;

  /// Drop cached prompt stream so the next [watchPrompts] subscribes fresh.
  void refreshPromptFeed();

  /// Visible entry counts for list / today card (only requested ids).
  Future<Map<String, int>> fetchEntryCounts(Iterable<String> promptIds);

  /// Which of [promptIds] the user has posted to (list UI).
  Future<Set<String>> fetchJoinedPromptIds(Iterable<String> promptIds);

  Stream<PromptBoard> watchBoard(String promptId);

  Stream<List<LabProposal>> watchProposals();

  Stream<List<LabReport>> watchReports();

  Future<LabOutcome> submitText(String promptId, String text);

  Future<LabOutcome> submitPhoto(String promptId, String localImagePath);

  Future<LabOutcome> submitChoice(String promptId, int index);

  Future<LabOutcome> toggleVote(String promptId, String entryUid);

  Future<LabOutcome> report(String promptId, String entryUid);

  Future<LabOutcome> propose(LabDraft draft);

  Future<LabOutcome> setProposalStatus(String id, ProposalStatus status);

  Future<LabOutcome> publishProposal(String id, LabDraft draft);

  Future<LabOutcome> publishPrompt(LabDraft draft);

  Future<LabOutcome> upsertPrompt(String id, LabDraft draft);

  Future<LabOutcome> setEntryHidden(
    String promptId,
    String entryUid,
    bool hidden,
  );

  Future<LabOutcome> deleteEntry(String promptId, String entryUid);

  Stream<VentFeed> watchVents();

  Future<LabOutcome> submitVent(String text);

  Future<LabOutcome> toggleVentReaction(String postId, VentReaction reaction);

  Future<LabOutcome> deleteVent(String postId);

  Future<LabOutcome> reportVent(String postId);

  Stream<Set<String>> watchBlockedVentAuthors();

  Future<LabOutcome> blockVentAuthor(String authorKey);

  Future<LabOutcome> unblockVentAuthor(String authorKey);

  Future<void> deleteMyCommunityData();
}
