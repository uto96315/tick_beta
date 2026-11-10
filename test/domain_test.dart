import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tick/data/chick_banter.dart';
import 'package:tick/domain/app_update.dart';
import 'package:tick/domain/engine.dart';
import 'package:tick/domain/fake_call_policy.dart';
import 'package:tick/domain/iso_week.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/domain/schedule.dart';
import 'package:tick/domain/segments.dart';
import 'package:tick/domain/session_ops.dart';
import 'package:tick/domain/sync_merge.dart';

void main() {
  test('last segment shrinks to the remainder', () {
    final start = DateTime(2026, 10, 26, 9);
    final end = DateTime(2026, 10, 26, 10, 10);
    final segments = buildSegments(start: start, end: end, intervalMinutes: 30);
    expect(segments, hasLength(3));
    expect(segments.last.end.difference(segments.last.start), const Duration(minutes: 10));
  });

  test('an interval longer than the shift is one segment', () {
    final start = DateTime(2026, 10, 26, 9);
    final end = DateTime(2026, 10, 26, 9, 20);
    final segments = buildSegments(start: start, end: end, intervalMinutes: 60);
    expect(segments, hasLength(1));
    expect(segments.single.end, end);
  });

  test('hour indexes follow the clock hour or the active segment', () {
    final segments = buildSegments(
      start: DateTime(2026, 10, 28, 9),
      end: DateTime(2026, 10, 28, 18),
      intervalMinutes: 30,
    );
    final at = DateTime(2026, 10, 28, 14, 20);
  final progress = evaluateSegments(
      segments: segments,
      now: at,
      sessionEnd: DateTime(2026, 10, 28, 18),
    );
    final indexes = hourSegmentIndexes(segments, at, progress.currentIndex);
    expect(indexes, [10, 11]);
    expect(segments[indexes.first].start.hour, 14);
  });

  test('hour groups keep consecutive segments in the same clock hour', () {
    final segments = buildSegments(
      start: DateTime(2026, 10, 28, 9, 0),
      end: DateTime(2026, 10, 28, 10, 30),
      intervalMinutes: 15,
    );
    final groups = segmentIndexesByHour(segments);
    expect(groups, hasLength(2));
    expect(groups[0], [0, 1, 2, 3]);
    expect(groups[1], [4, 5]);
    expect(segments[groups[0].first].start.hour, 9);
    expect(segments[groups[1].first].start.hour, 10);
  });

  test('progress counts only finished chunks', () {
    final start = DateTime(2026, 10, 26, 9);
    final end = DateTime(2026, 10, 26, 10);
    final segments = buildSegments(start: start, end: end, intervalMinutes: 15);
    final during = evaluateSegments(segments: segments, now: DateTime(2026, 10, 26, 9, 20), sessionEnd: end);
    expect(during.completed, 1);
    expect(during.currentIndex, 1);
    expect(during.remaining, const Duration(minutes: 40));
    final after = evaluateSegments(segments: segments, now: end, sessionEnd: end);
    expect(after.completed, 4);
    expect(after.remaining, Duration.zero);
  });

  test('overnight shift and a holiday override', () {
    final pattern = WorkPattern(
      id: 'night',
      name: 'Night',
      start: const ClockTime(22, 0),
      end: const ClockTime(7, 0),
      breaks: const [BreakTemplate(id: 'b', start: ClockTime(2, 0), end: ClockTime(3, 0))],
      updatedAt: DateTime(2026, 10, 1),
    );
    final week = WeekPlan(days: {1: 'night'}, updatedAt: DateTime(2026, 10, 1));
    final calendar = ScheduleCalendar(patterns: [pattern], week: week, overrides: const []);
    final monday = DateTime(2026, 10, 26);
    final shift = calendar.shiftStartingOn(monday)!;
    expect(shift.end, DateTime(2026, 10, 27, 7));
    expect(shift.breaks.single.start, DateTime(2026, 10, 27, 2));
    expect(calendar.shiftCovering(DateTime(2026, 10, 27, 1))?.key, shift.key);

    final holiday = ScheduleCalendar(
      patterns: [pattern],
      week: week,
      overrides: [
        DateOverride(
          id: 'off',
          date: monday,
          holiday: true,
          name: 'off',
          start: null,
          end: null,
          breaks: const [],
          updatedAt: DateTime(2026, 10, 1),
        ),
      ],
    );
    expect(holiday.shiftStartingOn(monday), isNull);
  });

  test('overtime uses the original end and breaks follow the edited times', () {
    final record = WorkRecord(
      id: '1',
      workDate: DateTime(2026, 10, 26),
      actualStart: DateTime(2026, 10, 26, 9),
      actualEnd: DateTime(2026, 10, 26, 19, 30),
      originalPlannedEnd: DateTime(2026, 10, 26, 18),
      intervalMinutes: 15,
      breaks: [
        BreakSpan(
          id: 'b',
          start: DateTime(2026, 10, 26, 12),
          end: DateTime(2026, 10, 26, 13),
          updatedAt: DateTime(2026, 10, 26, 12),
        ),
      ],
      segmentsCompleted: 1,
      segmentsTotal: 4,
      extensions: const [],
      status: EndStatus.completed,
      memo: '',
      patternId: null,
      shiftKey: null,
      updatedAt: DateTime(2026, 10, 26, 19, 30),
    );
    expect(overtimeOf(record), const Duration(hours: 1, minutes: 30));
    expect(record.achievementRate, 0.25);
    final edited = withDuration(record.breaks.single, const Duration(minutes: 45), DateTime(2026, 10, 26, 13));
    expect(edited.duration, const Duration(minutes: 45));
    expect(breakTotal([edited]), const Duration(minutes: 45));
  });

  test('extension keeps the original end', () {
    final now = DateTime(2026, 10, 26, 17);
    final session = buildSession(
      SessionDraft(
        id: 's',
        now: now,
        actualStart: DateTime(2026, 10, 26, 9),
        plannedEnd: DateTime(2026, 10, 26, 18),
        originalPlannedEnd: DateTime(2026, 10, 26, 18),
        intervalMinutes: 60,
        breaks: const [],
        patternId: null,
        shiftKey: null,
        celebrateElapsed: false,
      ),
    );
    final extended = extendSession(session, 30, now);
    expect(extended.originalPlannedEnd, DateTime(2026, 10, 26, 18));
    expect(extended.plannedEnd, DateTime(2026, 10, 26, 18, 30));
    final early = finishSession(extended, DateTime(2026, 10, 26, 17, 30), EndStatus.early);
    expect(early.segmentsCompleted, 8);
    expect(early.segmentsTotal, 10);
    expect(early.actualEnd, DateTime(2026, 10, 26, 17, 30));
    final done = finishSession(extended, extended.plannedEnd, EndStatus.completed);
    expect(done.actualEnd, extended.plannedEnd);
    expect(done.segmentsCompleted, done.segmentsTotal);
    expect(overtimeOf(done), const Duration(minutes: 30));
  });

  test('editing the shift updates the live end and keeps added time', () {
    final now = DateTime(2026, 10, 26, 15);
    final session = extendSession(
      buildSession(
        SessionDraft(
          id: 's',
          now: now,
          actualStart: DateTime(2026, 10, 26, 9),
          plannedEnd: DateTime(2026, 10, 26, 18),
          originalPlannedEnd: DateTime(2026, 10, 26, 18),
          intervalMinutes: 60,
          breaks: [TimeRange(start: DateTime(2026, 10, 26, 12), end: DateTime(2026, 10, 26, 13))],
          patternId: 'day',
          shiftKey: 'old',
          celebrateElapsed: false,
        ),
      ),
      30,
      now,
    );
    final shift = ResolvedShift(
      workDate: DateTime(2026, 10, 26),
      start: DateTime(2026, 10, 26, 10),
      end: DateTime(2026, 10, 26, 19),
      breaks: [TimeRange(start: DateTime(2026, 10, 26, 12, 30), end: DateTime(2026, 10, 26, 13, 30))],
      patternId: 'day',
      label: 'Day',
    );
    final aligned = realignSession(session, shift, now);
    expect(aligned.actualStart, DateTime(2026, 10, 26, 10));
    expect(aligned.originalPlannedEnd, DateTime(2026, 10, 26, 19));
    expect(aligned.plannedEnd, DateTime(2026, 10, 26, 19, 30));
    expect(aligned.breaks.single.start, DateTime(2026, 10, 26, 12, 30));
  });

  test('iso weeks and the free call allowance', () {
    expect(isoWeekKey(DateTime(2021, 1, 1)), '2020-W53');
    expect(isoWeekKey(DateTime(2021, 1, 4)), '2021-W01');
    final monday = DateTime(2026, 10, 26);
    final sunday = DateTime(2026, 11, 1);
    expect(isoWeekKey(monday), isoWeekKey(sunday));
    expect(FakeCallPolicy.canConsume(premium: false, credits: const [], when: monday), isTrue);
    final used = [CallCredit(id: 'a', when: monday, canceled: false, updatedAt: monday)];
    expect(FakeCallPolicy.canConsume(premium: false, credits: used, when: monday.add(const Duration(days: 1))), isFalse);
    expect(FakeCallPolicy.canConsume(premium: true, credits: used, when: monday), isTrue);
    expect(
      FakeCallPolicy.canConsume(premium: false, owner: true, credits: used, when: monday),
      isTrue,
    );
    expect(FakeCallPolicy.isOwner('Yuto.Mabe@gmail.com'), isTrue);
    expect(FakeCallPolicy.isOwner('other@example.com'), isFalse);
    expect(FakeCallPolicy.canConsume(premium: false, credits: used, when: DateTime(2026, 11, 2)), isTrue);
  });

  test('an open app starts the shift, a cold launch asks', () {
    final pattern = WorkPattern(
      id: 'day',
      name: 'Day',
      start: const ClockTime(9, 0),
      end: const ClockTime(18, 0),
      breaks: const [],
      updatedAt: DateTime(2026, 1, 1),
    );
    final calendar = ScheduleCalendar(
      patterns: [pattern],
      week: WeekPlan(days: {1: 'day'}, updatedAt: DateTime(2026, 1, 1)),
      overrides: const [],
    );
    final start = DateTime(2026, 10, 26, 9);
    final auto = planTick(
      now: start,
      foreground: true,
      lastForegroundTick: start.subtract(const Duration(seconds: 1)),
      session: null,
      calendar: calendar,
      autoStart: true,
      dismissedShiftKey: null,
      history: const [],
      currentPrompt: null,
      calls: const [],
      callInProgress: false,
    );
    expect(auto.whereType<AutoStartShift>(), isNotEmpty);

    final ask = planTick(
      now: DateTime(2026, 10, 26, 9, 30),
      foreground: true,
      lastForegroundTick: null,
      session: null,
      calendar: calendar,
      autoStart: true,
      dismissedShiftKey: null,
      history: const [],
      currentPrompt: null,
      calls: const [],
      callInProgress: false,
    );
    expect(ask.single, isA<AskStartShift>());
  });

  test('a newer record wins and a newer tombstone deletes it', () {
    final older = RemoteEntity(id: '1', updatedAt: DateTime(2026, 1, 1), json: const {'id': '1'});
    final newer = RemoteEntity(id: '1', updatedAt: DateTime(2026, 2, 1), json: const {'id': '1'});
    final kept = mergeCollection(
      collection: 'history',
      local: [newer],
      localTombstones: const [],
      remote: [older],
      remoteTombstones: const [],
    );
    expect(kept.entities.single.updatedAt, newer.updatedAt);
    expect(kept.upserts, isNotEmpty);

    final removed = mergeCollection(
      collection: 'history',
      local: const [],
      localTombstones: [Tombstone(collection: 'history', id: '1', deletedAt: DateTime(2026, 3, 1))],
      remote: [newer],
      remoteTombstones: const [],
    );
    expect(removed.entities, isEmpty);
    expect(removed.deletes, ['1']);
  });

  test('premium sticks and does not get wiped by a later free copy', () {
    final free = Entitlement(premium: false, updatedAt: DateTime(2026, 5, 1), source: 'none');
    final paid = Entitlement(premium: true, updatedAt: DateTime(2026, 1, 1), source: 'store');
    expect(mergeEntitlement(free, paid).premium, isTrue);
  });

  test('free accounts stay on the plain camouflage, voice, and ringtone', () {
    expect(shownLook(false, CamouflageLook.notes), CamouflageLook.home);
    expect(showsHomeShot(false, '/tmp/shot.jpg'), isFalse);
    expect(showsHomeShot(true, '/tmp/shot.jpg'), isTrue);
    expect(showsHomeShot(true, ''), isFalse);
    expect(shownLook(true, CamouflageLook.calendar), CamouflageLook.calendar);
    expect(shownVoice(false, ChickVoice.kansai), ChickVoice.plain);
    expect(shownVoice(true, ChickVoice.lazy), ChickVoice.lazy);
    expect(shownSound(false, CallSound.bright), CallSound.classic);
    final settings = AppSettings.fromJson({'tutorialSeen': true});
    expect(settings.camouflageLook, CamouflageLook.home);
    expect(settings.chickVoice, ChickVoice.plain);
    expect(settings.callSound, CallSound.classic);
    expect(settings.customChickLine, isEmpty);
    expect(settings.slackIntroSeen, isFalse);
    expect(settings.homeShot, isEmpty);
    expect(settings.mascot, MascotKind.chick);
  });

  test('build numbers choose a forced update, an optional one, or nothing', () {
    const url = 'https://example.com/tick';
    expect(
      decideUpdate(currentBuild: 2, minBuild: 9, latestBuild: 9, dismissedBuild: 9, url: url).kind,
      UpdateKind.required,
    );
    expect(
      decideUpdate(currentBuild: 2, minBuild: 0, latestBuild: 9, dismissedBuild: 0, url: url).kind,
      UpdateKind.optional,
    );
    expect(
      decideUpdate(currentBuild: 2, minBuild: 0, latestBuild: 9, dismissedBuild: 9, url: url).kind,
      UpdateKind.none,
    );
    expect(
      decideUpdate(currentBuild: 2, minBuild: 0, latestBuild: 9, dismissedBuild: 0, url: '').kind,
      UpdateKind.none,
    );
    expect(
      decideUpdate(currentBuild: 9, minBuild: 3, latestBuild: 9, dismissedBuild: 0, url: url).kind,
      UpdateKind.none,
    );
    expect(
      decideUpdate(currentBuild: 0, minBuild: 1, latestBuild: 1, dismissedBuild: 0, url: url).kind,
      UpdateKind.none,
    );
  });

  test('chick banter pool has 200 lines per locale', () {
    final now = DateTime(2026, 1, 1, 12);
    expect(chickBanterLines(const Locale('ja'), now), hasLength(200));
    expect(chickBanterLines(const Locale('en'), now), hasLength(200));
    final later = now.add(const Duration(hours: 1));
    expect(chickBanterLines(const Locale('ja'), later).first,
        isNot(chickBanterLines(const Locale('ja'), now).first));
  });
}
