import 'package:tick/lab/models.dart';

abstract class LabStore {
  String? get uid;

  bool get canReview;

  bool get sharesWithOthers;

  Stream<LabFeed> watchPrompts();

  Stream<PromptBoard> watchBoard(String promptId);

  Stream<List<LabProposal>> watchProposals();

  Stream<List<LabReport>> watchReports();

  Future<LabOutcome> submitText(String promptId, String text);

  Future<LabOutcome> submitChoice(String promptId, int index);

  Future<LabOutcome> toggleVote(String promptId, String entryUid);

  Future<LabOutcome> report(String promptId, String entryUid);

  Future<LabOutcome> propose(LabDraft draft);

  Future<LabOutcome> setProposalStatus(String id, ProposalStatus status);

  Future<LabOutcome> publishProposal(String id, LabDraft draft);

  Future<LabOutcome> publishPrompt(LabDraft draft);

  Future<LabOutcome> setEntryHidden(
    String promptId,
    String entryUid,
    bool hidden,
  );
}
