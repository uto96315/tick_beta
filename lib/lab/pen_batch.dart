import 'package:tick/lab/lab_store.dart';
import 'package:tick/lab/models.dart';

/// Official penmanship prompts (Japanese). IDs are stable for idempotent Firestore upsert.
const penBatchDocIds = [
  'seed-pen-01',
  'seed-pen-02',
  'seed-pen-03',
  'seed-pen-04',
  'seed-pen-05',
  'seed-pen-06',
  'seed-pen-07',
  'seed-pen-08',
  'seed-pen-09',
  'seed-pen-10',
  'seed-pen-11',
  'seed-pen-12',
  'seed-pen-13',
  'seed-pen-14',
  'seed-pen-15',
  'seed-pen-16',
  'seed-pen-17',
  'seed-pen-18',
  'seed-pen-19',
  'seed-pen-20',
];

List<({String id, LabDraft draft})> penBatchDrafts() {
  const body = '達筆で書いて、写真で投稿。';
  const format = LabFormat.pen;
  final titles = [
    '龍',
    '鳳凰',
    '天下無双',
    '疾風迅雷',
    '花鳥風月',
    '森羅万象',
    '桜花爛漫',
    '明鏡止水',
    '百花繚乱',
    '風林火山',
    '天翔',
    '覇道',
    '無限',
    '絶影',
    '神威',
    '幽玄',
    '煉獄',
    '迅雷',
    '不撓不屈',
    '天下泰平',
  ];
  const categories = [
    LabCategory.stand,
    LabCategory.quiet,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.quiet,
    LabCategory.stand,
    LabCategory.quiet,
    LabCategory.quiet,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.quiet,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.quiet,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.quiet,
  ];
  return [
    for (var i = 0; i < titles.length; i++)
      (
        id: penBatchDocIds[i],
        draft: LabDraft(
          title: titles[i],
          body: body,
          category: categories[i],
          format: format,
          featured: false,
        ),
      ),
  ];
}

Future<int> seedPenBatch(LabStore store) async {
  var ok = 0;
  for (final item in penBatchDrafts()) {
    final result = await store.upsertPrompt(item.id, item.draft);
    if (result.ok) ok++;
  }
  return ok;
}
