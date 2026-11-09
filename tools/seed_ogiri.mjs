/**
 * Upserts the official ogiri batch into Firestore (tick-beta).
 * Requires: gcloud auth application-default login  OR  GOOGLE_APPLICATION_CREDENTIALS
 *
 *   node tools/seed_ogiri.mjs
 */
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const titles = [
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

initializeApp({
  credential: applicationDefault(),
  projectId: 'tick-beta',
});

const db = getFirestore();
const body = '自由に答えて。';

for (let i = 0; i < titles.length; i++) {
  const id = `seed-ogiri-${String(i + 1).padStart(2, '0')}`;
  await db
    .collection('labPrompts')
    .doc(id)
    .set(
      {
        title: titles[i],
        body,
        category: 'stand',
        format: 'ogiri',
        phase: 'open',
        featured: i === 0,
        choices: [],
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  console.log('upserted', id, titles[i]);
}

console.log('done:', titles.length, 'prompts');
