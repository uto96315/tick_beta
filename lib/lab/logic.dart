import 'package:tick/lab/models.dart';

/// Same address as `firestore.rules`. Anonymous accounts are not reviewers.
const labAdminEmails = {'yuto.mabe@gmail.com'};

const labTitleMax = 40;
const labBodyMax = 200;
const labAnswerMax = 80;
const labChoiceMax = 24;

bool labCanReview(String? email) {
  if (email == null) return false;
  return labAdminEmails.contains(email.toLowerCase());
}

String labName(String uid) {
  final tail = uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  final end = tail.length <= 4 ? tail : tail.substring(tail.length - 4);
  return 'ひよこ$end';
}

bool labHasContact(String text) {
  if (RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}')
      .hasMatch(text)) {
    return true;
  }
  final digits = text.replaceAll(RegExp(r'[\s-]'), '');
  return RegExp(r'\d{10,}').hasMatch(digits);
}

List<String> splitChoices(String raw) {
  return [
    for (final line in raw.split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];
}

LabCategory? labCategoryFrom(String? raw) => switch (raw) {
  'sit' => LabCategory.sit,
  'stand' => LabCategory.stand,
  'quiet' => LabCategory.quiet,
  _ => null,
};

LabFormat? labFormatFrom(String? raw) => switch (raw) {
  'ogiri' => LabFormat.ogiri,
  'quiz' => LabFormat.quiz,
  'choice' => LabFormat.choice,
  'draw' => LabFormat.draw,
  _ => null,
};

LabPhase? labPhaseFrom(String? raw) => switch (raw) {
  'open' => LabPhase.open,
  'closed' => LabPhase.closed,
  _ => null,
};

ProposalStatus? proposalStatusFrom(String? raw) => switch (raw) {
  'pending' => ProposalStatus.pending,
  'accepted' => ProposalStatus.accepted,
  'rejected' => ProposalStatus.rejected,
  _ => null,
};

LabPrompt? parsePrompt(String id, Map<String, Object?> map) {
  final category = labCategoryFrom(map['category'] as String?);
  final format = labFormatFrom(map['format'] as String?);
  final phase = labPhaseFrom(map['phase'] as String?);
  final title = map['title'];
  final body = map['body'];
  if (category == null ||
      format == null ||
      phase == null ||
      title is! String ||
      body is! String) {
    return null;
  }
  final rawChoices = map['choices'];
  final choices = [
    for (final item in rawChoices is List ? rawChoices : const [])
      if (item is String) item,
  ];
  final correct = map['correctIndex'];
  final created = map['createdAt'];
  final closes = map['closesAt'];
  return LabPrompt(
    id: id,
    title: title,
    body: body,
    category: category,
    format: format,
    phase: phase,
    createdAt: created is DateTime
        ? created
        : DateTime.fromMillisecondsSinceEpoch(0),
    featured: map['featured'] == true,
    closesAt: closes is DateTime ? closes : null,
    choices: choices,
    correctIndex: correct is int ? correct : null,
  );
}

bool isAccepting(LabPrompt prompt, DateTime now) {
  if (prompt.phase != LabPhase.open) return false;
  if (prompt.format == LabFormat.draw) return false;
  final closes = prompt.closesAt;
  if (closes != null && !now.isBefore(closes)) return false;
  return true;
}

LabFailure? validateAnswer(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return LabFailure.empty;
  if (trimmed.length > labAnswerMax) return LabFailure.tooLong;
  if (labHasContact(trimmed)) return LabFailure.contact;
  return null;
}

LabFailure? validateDraft(LabDraft draft, {required bool publishing}) {
  final title = draft.title.trim();
  final body = draft.body.trim();
  if (title.isEmpty || body.isEmpty) return LabFailure.empty;
  if (title.length > labTitleMax || body.length > labBodyMax)
    return LabFailure.tooLong;
  if (labHasContact(title) || labHasContact(body)) return LabFailure.contact;
  if (draft.format == LabFormat.quiz || draft.format == LabFormat.choice) {
    final choices = draft.cleanedChoices;
    if (choices.length < 2 || choices.length > 4) return LabFailure.invalid;
    if (choices.any(
      (choice) => choice.length > labChoiceMax || labHasContact(choice),
    )) {
      return LabFailure.invalid;
    }
    if (draft.format == LabFormat.quiz && publishing) {
      final index = draft.correctIndex;
      if (index == null || index < 0 || index >= choices.length)
        return LabFailure.invalid;
    }
  }
  return null;
}

List<LabPrompt> mergePrompts(List<LabPrompt> seeds, List<LabPrompt> remote) {
  final byId = {for (final prompt in seeds) prompt.id: prompt};
  for (final prompt in remote) {
    byId[prompt.id] = prompt;
  }
  final merged = byId.values
      .where(
        (prompt) =>
            prompt.phase == LabPhase.open || prompt.phase == LabPhase.closed,
      )
      .toList();
  merged.sort((a, b) {
    if (a.featured != b.featured) return a.featured ? -1 : 1;
    return b.createdAt.compareTo(a.createdAt);
  });
  return merged;
}

LabPrompt? todaysPrompt(List<LabPrompt> prompts) {
  final featured =
      prompts
          .where((prompt) => prompt.featured && prompt.phase == LabPhase.open)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  if (featured.isEmpty) return null;
  return featured.first;
}

Map<int, int> tallyChoices(Iterable<LabEntry> entries, int choiceCount) {
  final counts = {for (var index = 0; index < choiceCount; index++) index: 0};
  for (final entry in entries) {
    final index = entry.choiceIndex;
    if (index == null || !counts.containsKey(index)) continue;
    counts[index] = counts[index]! + 1;
  }
  return counts;
}

int compareEntries(LabEntry a, LabEntry b) {
  final byVotes = b.votes.compareTo(a.votes);
  if (byVotes != 0) return byVotes;
  return a.createdAt.compareTo(b.createdAt);
}
