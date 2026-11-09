import 'package:flutter_test/flutter_test.dart';
import 'package:tick/lab/catalog.dart';
import 'package:tick/lab/draw_batch.dart';
import 'package:tick/lab/ogiri_batch.dart';
import 'package:tick/lab/pen_batch.dart';
import 'package:tick/lab/logic.dart';
import 'package:tick/lab/profile.dart';
import 'package:tick/lab/memory_lab.dart';
import 'package:tick/lab/models.dart';

void main() {
  test(
    'answers, votes, quizzes, and review stay within the lab rules',
    () async {
      final box = LabBox();
      for (final seed in labSeeds('ja')) {
        box.prompts[seed.id] = seed;
      }
      var next = 0;
      String id() => 'made-${next++}';
      final now = DateTime.utc(2026, 10, 29, 1);
      final a = MemoryLabStore(
        uid: 'user-a',
        newId: id,
        box: box,
        languageCode: () => 'ja',
        now: () => now,
        sharesWithOthers: true,
      );
      final b = MemoryLabStore(
        uid: 'user-b',
        newId: id,
        box: box,
        languageCode: () => 'ja',
        now: () => now,
        sharesWithOthers: true,
      );
      final admin = MemoryLabStore(
        uid: 'operator',
        newId: id,
        box: box,
        languageCode: () => 'ja',
        now: () => now,
        canReview: true,
        sharesWithOthers: true,
      );

      expect(labHasContact('hello@example.com'), isTrue);
      expect(labHasContact('090-1234-5678'), isTrue);
      expect(
        (await a.submitText('seed-company', '  ')).failure,
        LabFailure.empty,
      );
      expect(
        (await a.submitText('seed-company', 'mail me at a@b.co')).failure,
        LabFailure.contact,
      );
      expect(
        (await a.submitText('seed-pan', 'フライパン')).failure,
        LabFailure.invalid,
      );
      expect((await a.submitText('seed-company', '窓がない')).ok, isTrue);
      expect(
        (await a.submitText('seed-company', 'もう一つ')).failure,
        LabFailure.already,
      );
      expect(
        (await a.toggleVote('seed-company', a.uid)).failure,
        LabFailure.selfVote,
      );

      expect((await b.toggleVote('seed-company', a.uid)).ok, isTrue);
      var board = await b.watchBoard('seed-company').first;
      expect(board.entries.single.votes, 1);
      expect(board.entries.single.voted, isTrue);
      expect((await b.toggleVote('seed-company', a.uid)).ok, isTrue);
      board = await b.watchBoard('seed-company').first;
      expect(board.entries.single.votes, 0);

      expect((await a.submitChoice('seed-pan', 0)).ok, isTrue);
      expect((await b.submitChoice('seed-pan', 1)).ok, isTrue);
      final quiz = await a.watchBoard('seed-pan').first;
      expect(tallyChoices(quiz.entries, 3)[0], 1);
      expect(tallyChoices(quiz.entries, 3)[1], 1);
      expect(quiz.entries.singleWhere((entry) => entry.mine).choiceIndex, 0);

      expect((await b.report('seed-company', a.uid)).ok, isTrue);
      expect(
        (await b.report('seed-company', a.uid)).failure,
        LabFailure.already,
      );
      expect(
        (await b.setEntryHidden('seed-company', a.uid, true)).failure,
        LabFailure.forbidden,
      );
      expect(
        (await admin.setEntryHidden('seed-company', a.uid, true)).ok,
        isTrue,
      );
      expect((await b.watchBoard('seed-company').first).entries, isEmpty);
      expect(
        (await admin.watchBoard('seed-company').first).entries.single.hidden,
        isTrue,
      );

      final proposed = await a.propose(
        const LabDraft(
          title: '昼ごはん',
          body: '今日なに食べた？',
          category: LabCategory.quiet,
          format: LabFormat.ogiri,
        ),
      );
      expect(proposed.ok, isTrue);
      final pending = await a.watchProposals().first;
      expect(pending.single.status, ProposalStatus.pending);
      expect(
        (await a.publishProposal(
          pending.single.id,
          pending.single.toDraft(),
        )).failure,
        LabFailure.forbidden,
      );
      expect(
        (await admin.setProposalStatus(
          pending.single.id,
          ProposalStatus.accepted,
        )).ok,
        isTrue,
      );
      expect(
        (await admin.publishProposal(
          pending.single.id,
          pending.single.toDraft(featured: true),
        )).ok,
        isTrue,
      );
      final feed = await a.watchPrompts().first;
      expect(
        feed.prompts.any((prompt) => prompt.title == '昼ごはん' && prompt.featured),
        isTrue,
      );
      expect(todaysPrompt(feed.prompts)?.title, '昼ごはん');

      box.prompts['shut'] = LabPrompt(
        id: 'shut',
        title: '終了',
        body: 'もう閉めている',
        category: LabCategory.quiet,
        format: LabFormat.ogiri,
        phase: LabPhase.closed,
        createdAt: now,
      );
      expect((await a.submitText('shut', 'まだ')).failure, LabFailure.closed);
    },
  );

  test('ogiri batch upserts twenty prompts', () async {
    final box = LabBox();
    final admin = MemoryLabStore(
      uid: 'operator',
      newId: () => 'x',
      box: box,
      languageCode: () => 'ja',
      canReview: true,
    );
    expect(ogiriBatchDrafts(), hasLength(20));
    expect(await seedOgiriBatch(admin), 20);
    expect(box.prompts['seed-ogiri-01']?.featured, isTrue);
    expect(box.prompts['seed-ogiri-20']?.format, LabFormat.ogiri);
  });

  test('draw batch upserts twenty prompts', () async {
    final box = LabBox();
    final admin = MemoryLabStore(
      uid: 'operator',
      newId: () => 'x',
      box: box,
      languageCode: () => 'ja',
      canReview: true,
    );
    expect(drawBatchDrafts(), hasLength(20));
    expect(await seedDrawBatch(admin), 20);
    expect(box.prompts['seed-draw-01']?.format, LabFormat.draw);
    expect(box.prompts['seed-draw-09']?.category, LabCategory.sit);
    expect(box.prompts['seed-draw-19']?.category, LabCategory.quiet);
  });

  test('pen batch upserts twenty prompts', () async {
    final box = LabBox();
    final admin = MemoryLabStore(
      uid: 'operator',
      newId: () => 'x',
      box: box,
      languageCode: () => 'ja',
      canReview: true,
    );
    expect(penBatchDrafts(), hasLength(20));
    expect(await seedPenBatch(admin), 20);
    expect(box.prompts['seed-pen-01']?.format, LabFormat.pen);
    expect(box.prompts['seed-pen-20']?.title, '天下泰平');
  });

  test('lab nick validation rejects contact info', () {
    expect(validateLabNick(''), LabFailure.empty);
    expect(validateLabNick('a@b.co'), LabFailure.contact);
    expect(validateLabNick('たろう'), isNull);
  });

  test('draw prompt accepts a photo entry in memory store', () async {
    final box = LabBox();
    box.prompts['seed-draw-01'] = LabPrompt(
      id: 'seed-draw-01',
      title: '描いて',
      body: '自由に描いて。',
      category: LabCategory.stand,
      format: LabFormat.draw,
      phase: LabPhase.open,
      createdAt: DateTime.utc(2026, 10, 29),
    );
    final user = MemoryLabStore(
      uid: 'user-a',
      newId: () => 'x',
      box: box,
      languageCode: () => 'ja',
    );
    expect(
      (await user.submitPhoto('seed-draw-01', '/tmp/sketch.jpg')).ok,
      isTrue,
    );
    final board = await user.watchBoard('seed-draw-01').first;
    expect(board.entries.single.imageUrl, '/tmp/sketch.jpg');
  });
}
