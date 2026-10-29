import 'records.dart';
import 'schedule.dart';
import 'segments.dart';

class SessionDraft {
  const SessionDraft({
    required this.id,
    required this.now,
    required this.actualStart,
    required this.plannedEnd,
    required this.originalPlannedEnd,
    required this.intervalMinutes,
    required this.breaks,
    required this.patternId,
    required this.shiftKey,
    required this.celebrateElapsed,
  });

  final String id;
  final DateTime now;
  final DateTime actualStart;
  final DateTime plannedEnd;
  final DateTime originalPlannedEnd;
  final int intervalMinutes;
  final List<TimeRange> breaks;
  final String? patternId;
  final String? shiftKey;
  final bool celebrateElapsed;
}

TimerSession buildSession(SessionDraft draft) {
  final segments = buildSegments(
    start: draft.actualStart,
    end: draft.plannedEnd,
    intervalMinutes: draft.intervalMinutes,
  );
  final progress = evaluateSegments(
    segments: segments,
    now: draft.now,
    sessionEnd: draft.plannedEnd,
  );
  return TimerSession(
    id: draft.id,
    workDate: draft.actualStart,
    actualStart: draft.actualStart,
    plannedEnd: draft.plannedEnd,
    originalPlannedEnd: draft.originalPlannedEnd,
    intervalMinutes: draft.intervalMinutes,
    breaks: [
      for (final range in draft.breaks)
        BreakSpan(
          id: '${draft.id}-${range.start.millisecondsSinceEpoch}',
          start: range.start,
          end: range.end,
          updatedAt: draft.now,
        ),
    ],
    extensions: const [],
    patternId: draft.patternId,
    shiftKey: draft.shiftKey,
    memo: '',
    celebratedCount: draft.celebrateElapsed ? 0 : progress.completed,
    updatedAt: draft.now,
  );
}

/// Applies a saved shift to a running session. Extra time already added stays on top of the new end.
TimerSession realignSession(TimerSession session, ResolvedShift shift, DateTime now) {
  final extra = session.plannedEnd.difference(session.originalPlannedEnd);
  final planned = shift.end.add(extra.isNegative ? Duration.zero : extra);
  if (!planned.isAfter(shift.start)) return session;
  final segments = buildSegments(start: shift.start, end: planned, intervalMinutes: session.intervalMinutes);
  final progress = evaluateSegments(segments: segments, now: now, sessionEnd: planned);
  return TimerSession(
    id: session.id,
    workDate: shift.workDate,
    actualStart: shift.start,
    plannedEnd: planned,
    originalPlannedEnd: shift.end,
    intervalMinutes: session.intervalMinutes,
    breaks: [
      for (final range in shift.breaks)
        BreakSpan(
          id: '${session.id}-${range.start.millisecondsSinceEpoch}',
          start: range.start,
          end: range.end,
          updatedAt: now,
        ),
    ],
    extensions: session.extensions,
    patternId: session.patternId,
    shiftKey: shift.key,
    memo: session.memo,
    celebratedCount: progress.completed,
    updatedAt: now,
  );
}

TimerSession changeInterval(TimerSession session, int minutes, DateTime now) {
  final interval = minutes.clamp(1, 240);
  final segments = buildSegments(start: session.actualStart, end: session.plannedEnd, intervalMinutes: interval);
  final progress = evaluateSegments(segments: segments, now: now, sessionEnd: session.plannedEnd);
  return session.copyWith(intervalMinutes: interval, celebratedCount: progress.completed, updatedAt: now);
}

TimerSession extendSession(TimerSession session, int minutes, DateTime now) {
  final previous = session.plannedEnd;
  final nextEnd = previous.add(Duration(minutes: minutes));
  return session.copyWith(
    plannedEnd: nextEnd,
    extensions: [
      ...session.extensions,
      ExtensionRecord(at: now, previousEnd: previous, newEnd: nextEnd, minutes: minutes),
    ],
    updatedAt: now,
  );
}

WorkRecord finishSession(TimerSession session, DateTime actualEnd, EndStatus status) {
  final segments = buildSegments(
    start: session.actualStart,
    end: session.plannedEnd,
    intervalMinutes: session.intervalMinutes,
  );
  final completed = status == EndStatus.completed
      ? segments.length
      : evaluateSegments(
          segments: segments,
          now: actualEnd,
          sessionEnd: session.plannedEnd,
        ).completed;
  final end = status == EndStatus.completed ? session.plannedEnd : actualEnd;
  return WorkRecord(
    id: session.id,
    workDate: session.workDate,
    actualStart: session.actualStart,
    actualEnd: end,
    originalPlannedEnd: session.originalPlannedEnd,
    intervalMinutes: session.intervalMinutes,
    breaks: session.breaks,
    segmentsCompleted: completed,
    segmentsTotal: segments.length,
    extensions: session.extensions,
    status: status,
    memo: session.memo,
    patternId: session.patternId,
    shiftKey: session.shiftKey,
    updatedAt: end,
  );
}

bool shiftAlreadyLogged(List<WorkRecord> history, ResolvedShift shift) {
  for (final record in history) {
    if (record.shiftKey == shift.key) return true;
    final sameDay = dateKeyOf(record.workDate) == dateKeyOf(shift.workDate);
    final overlaps =
        record.actualStart.isBefore(shift.end) && record.actualEnd.isAfter(shift.start);
    if (sameDay && overlaps) return true;
  }
  return false;
}

String dateKeyOf(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

BreakSpan withDuration(BreakSpan span, Duration duration, DateTime now) {
  final safe = duration < const Duration(minutes: 1) ? const Duration(minutes: 1) : duration;
  return span.copyWith(end: span.start.add(safe), updatedAt: now);
}
