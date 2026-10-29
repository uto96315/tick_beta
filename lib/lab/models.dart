enum LabCategory { sit, stand, quiet }

enum LabFormat { ogiri, quiz, choice, draw }

enum LabPhase { open, closed }

enum ProposalStatus { pending, accepted, rejected }

enum LabFailure {
  empty,
  tooLong,
  already,
  closed,
  selfVote,
  forbidden,
  offline,
  invalid,
  draw,
  contact,
}

class LabOutcome {
  const LabOutcome.ok() : failure = null;

  const LabOutcome.fail(this.failure);

  final LabFailure? failure;

  bool get ok => failure == null;
}

class LabPrompt {
  const LabPrompt({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.format,
    required this.phase,
    required this.createdAt,
    this.featured = false,
    this.closesAt,
    this.choices = const [],
    this.correctIndex,
    this.entryCount = 0,
    this.seeded = false,
  });

  final String id;
  final String title;
  final String body;
  final LabCategory category;
  final LabFormat format;
  final LabPhase phase;
  final DateTime createdAt;
  final bool featured;
  final DateTime? closesAt;
  final List<String> choices;
  final int? correctIndex;
  final int entryCount;
  final bool seeded;

  LabPrompt copyWith({int? entryCount, LabPhase? phase}) {
    return LabPrompt(
      id: id,
      title: title,
      body: body,
      category: category,
      format: format,
      phase: phase ?? this.phase,
      createdAt: createdAt,
      featured: featured,
      closesAt: closesAt,
      choices: choices,
      correctIndex: correctIndex,
      entryCount: entryCount ?? this.entryCount,
      seeded: seeded,
    );
  }
}

class LabEntry {
  const LabEntry({
    required this.uid,
    required this.name,
    required this.text,
    required this.createdAt,
    required this.votes,
    required this.voted,
    required this.mine,
    this.choiceIndex,
    this.hidden = false,
  });

  final String uid;
  final String name;
  final String text;
  final int? choiceIndex;
  final DateTime createdAt;
  final int votes;
  final bool voted;
  final bool mine;
  final bool hidden;
}

class LabFeed {
  const LabFeed({required this.prompts, this.remoteFailed = false});

  final List<LabPrompt> prompts;
  final bool remoteFailed;
}

class PromptBoard {
  const PromptBoard({
    required this.prompt,
    required this.entries,
    this.remoteFailed = false,
  });

  final LabPrompt? prompt;
  final List<LabEntry> entries;
  final bool remoteFailed;
}

class LabDraft {
  const LabDraft({
    required this.title,
    required this.body,
    required this.category,
    required this.format,
    this.choices = const [],
    this.correctIndex,
    this.featured = false,
  });

  final String title;
  final String body;
  final LabCategory category;
  final LabFormat format;
  final List<String> choices;
  final int? correctIndex;
  final bool featured;

  List<String> get cleanedChoices => [
    for (final choice in choices)
      if (choice.trim().isNotEmpty) choice.trim(),
  ];
}

class LabProposal {
  const LabProposal({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.format,
    required this.status,
    required this.authorUid,
    required this.createdAt,
    this.choices = const [],
    this.correctIndex,
  });

  final String id;
  final String title;
  final String body;
  final LabCategory category;
  final LabFormat format;
  final ProposalStatus status;
  final String authorUid;
  final DateTime createdAt;
  final List<String> choices;
  final int? correctIndex;

  LabDraft toDraft({bool featured = false}) {
    return LabDraft(
      title: title,
      body: body,
      category: category,
      format: format,
      choices: choices,
      correctIndex: correctIndex,
      featured: featured,
    );
  }
}

class LabReport {
  const LabReport({
    required this.id,
    required this.promptId,
    required this.entryUid,
    required this.reporterUid,
    required this.createdAt,
  });

  final String id;
  final String promptId;
  final String entryUid;
  final String reporterUid;
  final DateTime createdAt;
}
