import 'package:tick/lab/lab_store.dart';
import 'package:tick/lab/models.dart';

/// Official draw prompts (Japanese). IDs are stable for idempotent Firestore upsert.
const drawBatchDocIds = [
  'seed-draw-01',
  'seed-draw-02',
  'seed-draw-03',
  'seed-draw-04',
  'seed-draw-05',
  'seed-draw-06',
  'seed-draw-07',
  'seed-draw-08',
  'seed-draw-09',
  'seed-draw-10',
  'seed-draw-11',
  'seed-draw-12',
  'seed-draw-13',
  'seed-draw-14',
  'seed-draw-15',
  'seed-draw-16',
  'seed-draw-17',
  'seed-draw-18',
  'seed-draw-19',
  'seed-draw-20',
];

List<({String id, LabDraft draft})> drawBatchDrafts() {
  const body = '自由に描いて。';
  const format = LabFormat.draw;
  final titles = [
    '何も見ずにドラえもんを描いて',
    '記憶だけでピカチュウを描いて',
    '人生で一番やる気のない猫を描いて',
    '史上最弱のヒーローを描いて',
    'こんなナマケモノは嫌だ、どんな姿？',
    '世界一腹の立つ顔を描いて',
    'めちゃくちゃ偉そうな犬を描いて',
    '寝坊した人間を描いて',
    '仕事中に魂が抜けた人を描いて',
    '未来のロボットを描いて',
    '絶対に乗りたくない乗り物を描いて',
    '世界一弱そうなラスボスを描いて',
    '100年後のスマートフォンを描いて',
    '怒っているのに全然怖くない鬼を描いて',
    '宇宙人が考えた「人間」の絵を描いて',
    '史上最も不器用な忍者を描いて',
    '絶対に売れないゆるキャラを描いて',
    '月曜日の朝の自分を描いて',
    '世界一幸せそうなゴキブリを描いて',
    '会社の上司をモンスターにして描いて',
  ];
  const categories = [
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.sit,
    LabCategory.sit,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.stand,
    LabCategory.sit,
    LabCategory.quiet,
    LabCategory.sit,
  ];
  return [
    for (var i = 0; i < titles.length; i++)
      (
        id: drawBatchDocIds[i],
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

Future<int> seedDrawBatch(LabStore store) async {
  var ok = 0;
  for (final item in drawBatchDrafts()) {
    final result = await store.upsertPrompt(item.id, item.draft);
    if (result.ok) ok++;
  }
  return ok;
}
