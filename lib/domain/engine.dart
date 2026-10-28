import 'records.dart';
import 'schedule.dart';
import 'segments.dart';
import 'session_ops.dart';

sealed class TickCommand {
  const TickCommand();
}

class CompleteSession extends TickCommand {
  const CompleteSession(this.at);
  final DateTime at;
}

class CelebrateSegments extends TickCommand {
  const CelebrateSegments(this.completed);
  final int completed;
}

class AutoStartShift extends TickCommand {
  const AutoStartShift(this.shift);
  final ResolvedShift shift;
}

class AskStartShift extends TickCommand {
  const AskStartShift(this.shift);
  final ResolvedShift shift;
}

class FireFakeCall extends TickCommand {
  const FireFakeCall(this.callId);
  final String callId;
}

List<TickCommand> planTick({
  required DateTime now,
  required bool foreground,
  required DateTime? lastForegroundTick,
  required TimerSession? session,
  required ScheduleCalendar calendar,
  required bool autoStart,
  required String? dismissedShiftKey,
  required List<WorkRecord> history,
  required ResolvedShift? currentPrompt,
  required List<ScheduledFakeCall> calls,
  required bool callInProgress,
}) {
  final commands = <TickCommand>[];
  if (!callInProgress) {
    for (final call in calls) {
      if (!call.fired && !call.fireAt.isAfter(now)) {
        commands.add(FireFakeCall(call.id));
        break;
      }
    }
  }
  if (session != null) {
    if (!now.isBefore(session.plannedEnd)) {
      commands.add(CompleteSession(session.plannedEnd));
      return commands;
    }
    final segments = buildSegments(
      start: session.actualStart,
      end: session.plannedEnd,
      intervalMinutes: session.intervalMinutes,
    );
    final completed = evaluateSegments(
      segments: segments,
      now: now,
      sessionEnd: session.plannedEnd,
    ).completed;
    if (completed > session.celebratedCount) {
      commands.add(CelebrateSegments(completed));
    }
    return commands;
  }
  if (!autoStart) return commands;
  final shift = calendar.shiftCovering(now);
  if (shift == null) return commands;
  if (dismissedShiftKey == shift.key) return commands;
  if (shiftAlreadyLogged(history, shift)) return commands;
  if (currentPrompt?.key == shift.key) return commands;
  final crossedWhileOpen =
      foreground && lastForegroundTick != null && lastForegroundTick.isBefore(shift.start);
  if (crossedWhileOpen) {
    commands.add(AutoStartShift(shift));
  } else {
    commands.add(AskStartShift(shift));
  }
  return commands;
}
