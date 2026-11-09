import 'package:tick/lab/lab_store.dart';
import 'package:tick/lab/models.dart';

/// Official ogiri prompts (Japanese). IDs are stable for idempotent Firestore upsert.
const ogiriBatchDocIds = [
  'seed-ogiri-01',
  'seed-ogiri-02',
  'seed-ogiri-03',
  'seed-ogiri-04',
  'seed-ogiri-05',
  'seed-ogiri-06',
  'seed-ogiri-07',
  'seed-ogiri-08',
  'seed-ogiri-09',
  'seed-ogiri-10',
  'seed-ogiri-11',
  'seed-ogiri-12',
  'seed-ogiri-13',
  'seed-ogiri-14',
  'seed-ogiri-15',
  'seed-ogiri-16',
  'seed-ogiri-17',
  'seed-ogiri-18',
  'seed-ogiri-19',
  'seed-ogiri-20',
];

List<({String id, LabDraft draft})> ogiriBatchDrafts() {
  const body = '自由に答えて。';
  const category = LabCategory.stand;
  const format = LabFormat.ogiri;
  final titles = [
    'こんな会社は絶対に嫌だ。どんな会社？',
    '上司が突然「今日から俺、○○になるわ」。何になる？',
    '絶対に売れない自己啓発本のタイトルとは？',
    '「この人、仕事サボってるな」どうしてそう思った？',
    'こんな目覚まし時計は二度と使いたくない。どんな時計？',
    '桃太郎が鬼退治をやめた理由とは？',
    '1秒で信用を失う自己紹介をしてください。',
    '世界一やる気のないヒーロー。その必殺技は？',
    '面接官が「こいつ、只者じゃない」と思った回答とは？',
    '100円ショップで売っていたら嫌なものとは？',
    '「この会社、もうすぐ潰れるな」と思った瞬間とは？',
    '絶対に流行らない新しいスポーツとは？',
    '神様が人間界に来て、最初に後悔したこととは？',
    '仕事ができない人だけが持っている特殊能力とは？',
    '未来の教科書に載った、しょうもなさすぎる歴史的事件とは？',
    'コンビニ店員に言われた、予想外すぎる一言とは？',
    '「この人、前世は○○だな」。何だった？',
    '絶対に参加したくない飲み会のルールとは？',
    'AIが人類に反乱を起こした本当の理由とは？',
    '定時退社を阻止するために会社が導入した、とんでもない制度とは？',
  ];
  return [
    for (var i = 0; i < titles.length; i++)
      (
        id: ogiriBatchDocIds[i],
        draft: LabDraft(
          title: titles[i],
          body: body,
          category: category,
          format: format,
          featured: i == 0,
        ),
      ),
  ];
}

Future<int> seedOgiriBatch(LabStore store) async {
  var ok = 0;
  for (final item in ogiriBatchDrafts()) {
    final result = await store.upsertPrompt(item.id, item.draft);
    if (result.ok) ok++;
  }
  return ok;
}
