import 'package:tick/lab/models.dart';

final DateTime _seededOn = DateTime.utc(2026, 10, 29);

List<LabPrompt> labSeeds(String languageCode) {
  final ja = languageCode == 'ja';
  return [
    _seed(
      id: 'seed-company',
      title: ja ? 'こんな会社は嫌だ' : 'A company you would hate',
      body: ja ? 'どんな会社？短く一つ。' : 'What kind? One short line.',
      category: LabCategory.stand,
      format: LabFormat.ogiri,
      featured: true,
    ),
    _seed(
      id: 'seed-doodle',
      title: ja ? '会議中の落書きに、タイトルを' : 'Title the meeting doodle',
      body: ja ? '描かなくていい。タイトルだけ置いていって。' : 'No drawing. Just leave a title.',
      category: LabCategory.sit,
      format: LabFormat.ogiri,
    ),
    _seed(
      id: 'seed-leave',
      title: ja ? '定時退社と、給料アップ' : 'Leave on time, or a raise',
      body: ja ? 'どっちを取る？' : 'Which one?',
      category: LabCategory.stand,
      format: LabFormat.choice,
      choices: ja
          ? const ['定時退社', '給料アップ']
          : const ['Leave on time', 'A raise'],
    ),
    _seed(
      id: 'seed-pan',
      title: ja ? '食べられないパンは？' : 'Which bread can you not eat?',
      body: ja ? 'なぞなぞ。一つ選ぶ。' : 'A riddle. Pick one.',
      category: LabCategory.quiet,
      format: LabFormat.quiz,
      choices: ja
          ? const ['フライパン', '食パン', 'フランスパン']
          : const ['A frying pan', 'A loaf', 'A baguette'],
      correctIndex: 0,
    ),
    _seed(
      id: 'seed-seen',
      title: ja ? '既読がつかない' : 'No read receipt',
      body: ja ? '相手は、どっちだと思う？' : 'What do you think they are doing?',
      category: LabCategory.quiet,
      format: LabFormat.choice,
      choices: ja ? const ['見てない', '見ている'] : const ['Not looking', 'Looking'],
    ),
  ];
}

LabPrompt? labSeedById(String languageCode, String id) {
  for (final prompt in labSeeds(languageCode)) {
    if (prompt.id == id) return prompt;
  }
  return null;
}

LabPrompt _seed({
  required String id,
  required String title,
  required String body,
  required LabCategory category,
  required LabFormat format,
  bool featured = false,
  List<String> choices = const [],
  int? correctIndex,
}) {
  return LabPrompt(
    id: id,
    title: title,
    body: body,
    category: category,
    format: format,
    phase: LabPhase.open,
    createdAt: _seededOn,
    featured: featured,
    choices: choices,
    correctIndex: correctIndex,
    seeded: true,
  );
}
