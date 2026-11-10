import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/domain/format.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/domain/schedule.dart';
import 'package:tick/domain/segments.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/lab/logic.dart';
import 'package:tick/lab/models.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/camouflage_page.dart';
import 'package:tick/ui/lab/lab_widgets.dart';
import 'package:tick/ui/copy.dart';
import 'package:tick/ui/interval_choices.dart';
import 'package:tick/ui/theme.dart';
import 'package:tick/ui/visuals.dart';

const _cream = Color(0xFFFFF6E8);

/// Ozio の唯一のメイン画面（タイマー未開始・計測中ともここだけ）。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  var _byDuration = false;
  var _useShift = true;
  TimeOfDay _end = const TimeOfDay(hour: 18, minute: 0);
  int _hours = 8;
  int _minutes = 0;
  int? _interval;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = ref.watch(appControllerProvider);
    return NowBuilder(
      builder: (context, now) {
        final calendar = ScheduleCalendar(
          patterns: app.patterns,
          week: app.week,
          overrides: app.overrides,
        );
        final covering = calendar.shiftCovering(now);
        final upcoming = calendar.upcomingOn(now);
        final session = app.session;
        final running = session != null;
        final interval = _interval ?? app.settings.lastIntervalMinutes;
        final shiftEnd = running
            ? session.plannedEnd
            : (covering ?? upcoming)?.end ?? _resolvedEnd(now);
        final segments = running
            ? buildSegments(
                start: session.actualStart,
                end: session.plannedEnd,
                intervalMinutes: session.intervalMinutes,
              )
            : const <Segment>[];
        final progress = running
            ? evaluateSegments(
                segments: segments,
                now: now,
                sessionEnd: session.plannedEnd,
              )
            : null;
        final views = progress == null
            ? const <SegmentView>[]
            : segmentViews(segments, progress);
        final remainCount = progress?.remainingCount ?? 0;
        final shownShift = covering ?? upcoming;
        final idleAfterShift = _idleAfterScheduledEnd(
          calendar,
          now,
          running,
        );
        final rangeStart =
            shownShift?.start ?? (running ? session.actualStart : now);
        final rangeEnd =
            shownShift?.end ?? (running ? session.plannedEnd : shiftEnd);
        final remaining = running
            ? _chunkLeft(context, remainCount)
            : l10n.notRunning;
        final hourIndexes = running
            ? hourSegmentIndexes(segments, now, progress?.currentIndex)
            : const <int>[];
        final variety = poseVarietySlot(
          now,
          extra: running ? progress!.remainingCount : 0,
        );
        final pose = app.mood != null
            ? moodPose(app.mood!)
            : running
            ? timerPose(
                ratio: progress!.rate,
                remaining: progress.remainingCount,
                onBreak: session.breaks.any(
                  (span) => !now.isBefore(span.start) && now.isBefore(span.end),
                ),
                pastShift: !now.isBefore(session.originalPlannedEnd),
                slot: variety,
              )
            : idlePose(now);
        final lines = app.mood != null
            ? moodLines(l10n, app.mood!)
            : chickLines(
                l10n,
                pose,
                voice: shownVoice(app.premium, app.settings.chickVoice),
                custom: app.settings.customChickLine,
                now: now,
              );
        final shiftPromptShowing = app.prompt != null && !running;
        final showManualStart = !running && app.prompt == null;
        final mascotFlex = running
            ? 4
            : showManualStart
            ? 2
            : shiftPromptShowing
            ? 3
            : 4;
        return Scaffold(
          backgroundColor: _cream,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 8, 0),
                  child: Row(
                    children: [
                      Text(
                        l10n.appTitle,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: TickColors.ink,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: TickColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (idleAfterShift)
                          _IdleAfterShiftCard(
                            l10n: l10n,
                            onSchedule: () =>
                                context.push('/settings/schedule'),
                          )
                        else
                          _TimeCard(
                            start: formatHm(rangeStart),
                            end: formatHm(rangeEnd),
                            remaining: remaining,
                            onStart: () => _editShiftBound(
                              context,
                              now,
                              editingStart: true,
                            ),
                            onEnd: () => _editShiftBound(
                              context,
                              now,
                              editingStart: false,
                            ),
                            interval: running
                                ? _IntervalMenu(
                                    minutes: session.intervalMinutes,
                                    onPick: (minutes) => ref
                                        .read(appControllerProvider.notifier)
                                        .setInterval(minutes),
                                  )
                                : null,
                          ),
                        if (progress != null) ...[
                          const SizedBox(height: 4),
                          _DayDots(
                            title: l10n.todaySoFar,
                            completed: progress.completed,
                            total: progress.total,
                          ),
                        ],
                        if (shiftPromptShowing) ...[
                          const SizedBox(height: 6),
                          _prompt(context, app.prompt!, l10n),
                        ],
                        SizedBox(height: shiftPromptShowing ? 4 : 8),
                        Expanded(
                          flex: mascotFlex,
                          child: _MascotZone(
                            lines: lines,
                            pose: pose,
                            onTap: () => _pickMood(context, app.mood),
                          ),
                        ),
                        if (running && hourIndexes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _HourCard(
                            l10n: l10n,
                            segments: segments,
                            views: views,
                            indexes: hourIndexes,
                            dayCompleted: progress!.completed,
                            dayTotal: progress.total,
                            onOpenDay: () => _showDaySegments(
                              context,
                              l10n,
                              segments,
                              views,
                              progress.completed,
                              progress.total,
                            ),
                          ),
                        ],
                        if (!running) ...[
                          const SizedBox(height: 4),
                          _ToolRow(
                            l10n: l10n,
                            onCall: () => context.push('/call'),
                            onLab: () => context.push('/lab'),
                            onAway: () => openCamouflage(context, ref),
                          ),
                          const SizedBox(height: 4),
                          const _TodayPromptBanner(),
                          if (showManualStart) ...[
                            const SizedBox(height: 6),
                            Text(
                              l10n.interval,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            IntervalChoices(
                              minutes: interval,
                              onPreset: (value) => _rememberInterval(value),
                              onCustom: () async {
                                final picked = await askChunkMinutes(
                                  context,
                                  l10n.customMinutes,
                                  interval,
                                );
                                if (picked != null) {
                                  _rememberInterval(picked);
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: TickColors.ink,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                onPressed: () => _openStart(
                                  context,
                                  now,
                                  covering,
                                  upcoming,
                                ),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text(l10n.startTimer),
                              ),
                            ),
                          ],
                        ] else ...[
                          const SizedBox(height: 6),
                          _ToolRow(
                            l10n: l10n,
                            onCall: () => context.push('/call'),
                            onLab: () => context.push('/lab'),
                            onAway: () => openCamouflage(context, ref),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _prompt(
    BuildContext context,
    ResolvedShift shift,
    AppLocalizations l10n,
  ) {
    return PopCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.startPromptTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatHm(shift.start)} – ${formatHm(shift.end)}',
              style: const TextStyle(color: TickColors.muted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        ref.read(appControllerProvider.notifier).acceptPrompt(),
                    child: Text(l10n.startNow),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(appControllerProvider.notifier)
                        .dismissPrompt(),
                    child: Text(l10n.notToday),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }

  Future<void> _openStart(
    BuildContext context,
    DateTime now,
    ResolvedShift? covering,
    ResolvedShift? upcoming,
  ) async {
    final l10n = AppLocalizations.of(context);
    final shift = covering ?? upcoming;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TickColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheet) {
            void update(VoidCallback change) {
              setState(change);
              setSheet(() {});
            }

            final interval =
                _interval ??
                ref.read(appControllerProvider).settings.lastIntervalMinutes;
            final end = _resolvedEnd(now);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20 + MediaQuery.paddingOf(sheetContext).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: TickColors.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(l10n.endTimeMode),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(l10n.durationMode),
                      ),
                    ],
                    selected: {_byDuration},
                    onSelectionChanged: (value) =>
                        update(() => _byDuration = value.first),
                  ),
                  const SizedBox(height: 8),
                  if (_byDuration)
                    Row(
                      children: [
                        Expanded(
                          child: _Stepper(
                            label: l10n.hours,
                            value: _hours,
                            onChanged: (value) =>
                                update(() => _hours = value.clamp(0, 23)),
                          ),
                        ),
                        Expanded(
                          child: _Stepper(
                            label: l10n.mins,
                            value: _minutes,
                            onChanged: (value) =>
                                update(() => _minutes = value.clamp(0, 59)),
                          ),
                        ),
                      ],
                    )
                  else
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.pickEnd),
                      trailing: Text(
                        '${_end.format(context)}  ${_endIsTomorrow(now) ? l10n.tomorrow : l10n.today}',
                        style: const TextStyle(color: TickColors.muted),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: sheetContext,
                          initialTime: _end,
                        );
                        if (picked != null) update(() => _end = picked);
                      },
                    ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.interval,
                    style: const TextStyle(
                      color: TickColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  IntervalChoices(
                    minutes: interval,
                    onPreset: (value) {
                      _rememberInterval(value);
                      setSheet(() {});
                    },
                    onCustom: () async {
                      final picked = await askChunkMinutes(
                        sheetContext,
                        l10n.customMinutes,
                        interval,
                      );
                      if (picked != null) {
                        _rememberInterval(picked);
                        setSheet(() {});
                      }
                    },
                  ),
                  if (shift != null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        covering != null ? l10n.applyShift : l10n.useShift,
                      ),
                      subtitle: Text(
                        '${formatHm(shift.start)} – ${formatHm(shift.end)}',
                      ),
                      value: _useShift,
                      onChanged: (value) => update(() => _useShift = value),
                    ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      final selected = _useShift ? shift : null;
                      final planned = selected != null && !_byDuration
                          ? selected.end
                          : (_byDuration
                                ? now.add(
                                    Duration(hours: _hours, minutes: _minutes),
                                  )
                                : end);
                      ref
                          .read(appControllerProvider.notifier)
                          .startManual(
                            plannedEnd: planned,
                            intervalMinutes: interval,
                            anchorStart:
                                selected != null &&
                                    covering != null &&
                                    _useShift
                                ? selected.start
                                : null,
                            originalPlannedEnd: selected?.end,
                            shiftKey: selected != null && _useShift
                                ? selected.key
                                : null,
                            patternId: selected?.patternId,
                            breaks: selected != null && _useShift
                                ? selected.breaks
                                : const [],
                          );
                      Navigator.pop(sheetContext);
                    },
                    child: Text(l10n.startTimer),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDaySegments(
    BuildContext context,
    AppLocalizations l10n,
    List<Segment> segments,
    List<SegmentView> views,
    int dayCompleted,
    int dayTotal,
  ) {
    final hourGroups = segmentIndexesByHour(segments);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TickColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final padding = MediaQuery.paddingOf(sheetContext);
        final sheetHeight = MediaQuery.sizeOf(sheetContext).height * 0.78;
        return SafeArea(
          child: SizedBox(
            height: sheetHeight,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, padding.bottom + 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: TickColors.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.todaySoFar,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '$dayCompleted / $dayTotal',
                        style: const TextStyle(
                          color: TickColors.muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: hourGroups.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, groupIndex) {
                        final indexes = hourGroups[groupIndex];
                        return _DayHourStrip(
                          l10n: l10n,
                          segments: segments,
                          views: views,
                          indexes: indexes,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _rememberInterval(int minutes) {
    setState(() => _interval = minutes);
    final settings = ref.read(appControllerProvider).settings;
    ref
        .read(appControllerProvider.notifier)
        .updateSettings(settings.copyWith(lastIntervalMinutes: minutes));
  }

  DateTime _resolvedEnd(DateTime now) {
    var end = DateTime(now.year, now.month, now.day, _end.hour, _end.minute);
    if (!end.isAfter(now)) end = end.add(const Duration(days: 1));
    return end;
  }

  bool _endIsTomorrow(DateTime now) => _resolvedEnd(now).day != now.day;

  bool _idleAfterScheduledEnd(
    ScheduleCalendar calendar,
    DateTime now,
    bool running,
  ) {
    if (running) return false;
    if (calendar.shiftCovering(now) != null) return false;
    if (calendar.upcomingOn(now) != null) return false;
    final today = dateOnly(now);
    final todayShift = calendar.shiftStartingOn(today);
    if (todayShift != null) {
      return !now.isBefore(todayShift.end);
    }
    final defaultEnd = DateTime(
      today.year,
      today.month,
      today.day,
      _end.hour,
      _end.minute,
    );
    return !now.isBefore(defaultEnd);
  }

  Future<void> _editShiftBound(
    BuildContext context,
    DateTime now, {
    required bool editingStart,
  }) async {
    final l10n = AppLocalizations.of(context);
    final app = ref.read(appControllerProvider);
    final calendar = ScheduleCalendar(
      patterns: app.patterns,
      week: app.week,
      overrides: app.overrides,
    );
    final shift = calendar.shiftCovering(now) ?? calendar.upcomingOn(now);
    final pattern = calendar.patternById(shift?.patternId);
    if (pattern != null) {
      final current = editingStart ? pattern.start : pattern.end;
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
        helpText: editingStart ? l10n.shiftFrom : l10n.shiftTo,
      );
      if (picked == null) return;
      final clock = ClockTime(picked.hour, picked.minute);
      ref.read(appControllerProvider.notifier).upsertPattern(
        pattern.copyWith(
          start: editingStart ? clock : null,
          end: editingStart ? null : clock,
        ),
      );
      return;
    }
    DateOverride? override;
    if (shift != null) {
      final key = dateKey(shift.workDate);
      for (final item in app.overrides) {
        if (!item.holiday && dateKey(item.date) == key) {
          override = item;
          break;
        }
      }
    }
    final bound = editingStart ? override?.start : override?.end;
    if (override != null && bound != null) {
      if (!context.mounted) return;
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: bound.hour, minute: bound.minute),
        helpText: editingStart ? l10n.shiftFrom : l10n.shiftTo,
      );
      if (picked == null) return;
      final clock = ClockTime(picked.hour, picked.minute);
      ref.read(appControllerProvider.notifier).upsertOverride(
        DateOverride(
          id: override.id,
          date: override.date,
          holiday: override.holiday,
          name: override.name,
          start: editingStart ? clock : override.start,
          end: editingStart ? override.end : clock,
          breaks: override.breaks,
          updatedAt: override.updatedAt,
        ),
      );
      return;
    }
    if (ref.read(appControllerProvider).session != null) {
      if (!context.mounted) return;
      context.push('/settings/schedule');
      return;
    }
    if (!context.mounted) return;
    if (editingStart) {
      _openStart(
        context,
        now,
        calendar.shiftCovering(now),
        calendar.upcomingOn(now),
      );
      return;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: _end,
      helpText: l10n.pickEnd,
    );
    if (picked != null) setState(() => _end = picked);
  }

  void _pickMood(BuildContext context, ChickMood? mood) {
    final notifier = ref.read(appControllerProvider.notifier);
    showChickMoodPicker(
      context,
      current: mood,
      onPick: (picked) {
        if (picked == null) {
          notifier.clearMood();
        } else {
          notifier.setMood(picked);
        }
      },
    );
  }
}

String _chunkLeft(BuildContext context, int count) {
  final ja = Localizations.localeOf(context).languageCode == 'ja';
  if (ja) return '残り $countコマ';
  return '$count left';
}

class _MascotZone extends StatelessWidget {
  const _MascotZone({
    required this.lines,
    required this.pose,
    required this.onTap,
  });

  final List<String> lines;
  final ChickPose pose;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final bubbleW = (w * 0.88).clamp(200.0, 320.0);
        const bubbleH = 44.0;
        const fontSize = 13.0;
        const gapAboveMascot = 2.0;
        const bubbleBlock = bubbleH + 15;
        final mascotRoom =
            (h - bubbleBlock - gapAboveMascot - 6).clamp(48.0, 152.0);
        final mascot = math.min(w * 0.54, mascotRoom);
        if (!h.isFinite || h <= 0 || !w.isFinite || w <= 0) {
          return const SizedBox.shrink();
        }
        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: w,
            height: h,
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChickTalk(
                      lines: lines,
                      width: bubbleW,
                      height: bubbleH,
                      fontSize: fontSize,
                      cornerRadius: 16,
                    ),
                    const SizedBox(height: gapAboveMascot),
                    LivingMascot(pose: pose, size: mascot),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IdleAfterShiftCard extends StatelessWidget {
  const _IdleAfterShiftCard({
    required this.l10n,
    required this.onSchedule,
  });

  final AppLocalizations l10n;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return PopCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.idleAfterShiftStatus,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: TickColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.idleAfterShiftBody,
            style: const TextStyle(
              color: TickColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onSchedule,
              child: Text(l10n.idleAfterShiftAction),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.start,
    required this.end,
    required this.remaining,
    required this.onStart,
    required this.onEnd,
    this.interval,
  });

  final String start;
  final String end;
  final String remaining;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final Widget? interval;

  @override
  Widget build(BuildContext context) {
    return PopCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.hardEdge,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ShiftTime(label: start, onTap: onStart),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '–',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    _ShiftTime(label: end, onTap: onEnd),
                  ],
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    remaining,
                    key: ValueKey(remaining),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: TickColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            if (interval != null)
              Positioned(right: 0, top: 0, child: interval!),
          ],
        ),
      ),
    );
  }
}

class _ShiftTime extends StatelessWidget {
  const _ShiftTime({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFBF4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TickColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntervalMenu extends StatelessWidget {
  const _IntervalMenu({required this.minutes, required this.onPick});

  final int minutes;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<int>(
      initialValue: minutes == 15 || minutes == 30 || minutes == 60
          ? minutes
          : 0,
      onSelected: (value) async {
        if (value == 0) {
          final picked = await askChunkMinutes(
            context,
            l10n.customMinutes,
            minutes,
          );
          if (picked != null) onPick(picked);
          return;
        }
        onPick(value);
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 15, child: Text('15${l10n.mins}')),
        PopupMenuItem(value: 30, child: Text('30${l10n.mins}')),
        PopupMenuItem(value: 60, child: Text('1${l10n.hours}')),
        PopupMenuItem(value: 0, child: Text(l10n.intervalCustom)),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TickColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                minutes == 60
                    ? '1${l10n.hours}'
                    : minutes == 15 || minutes == 30
                    ? '$minutes${l10n.mins}'
                    : chunkLengthLabel(l10n, minutes),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const Icon(Icons.arrow_drop_down_rounded, color: TickColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}

String _hourSectionTitle(
  BuildContext context,
  List<Segment> segments,
  List<int> indexes,
) {
  if (indexes.isEmpty) return '';
  final first = segments[indexes.first];
  final last = segments[indexes.last];
  return '${formatHm(first.start)} – ${formatHm(last.end)}';
}

String _hourGroupTitle(List<Segment> segments, List<int> indexes) {
  if (indexes.isEmpty) return '';
  final first = segments[indexes.first];
  final last = segments[indexes.last];
  return '${formatHm(first.start)} – ${formatHm(last.end)}';
}

class _DayHourStrip extends StatelessWidget {
  const _DayHourStrip({
    required this.l10n,
    required this.segments,
    required this.views,
    required this.indexes,
  });

  final AppLocalizations l10n;
  final List<Segment> segments;
  final List<SegmentView> views;
  final List<int> indexes;

  @override
  Widget build(BuildContext context) {
    final title = _hourGroupTitle(segments, indexes);
    final hasCurrent = indexes.any((i) => views[i].current);
    return Material(
      color: hasCurrent ? TickColors.yellow.withValues(alpha: 0.35) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var n = 0; n < indexes.length; n++) ...[
                  if (n > 0) const SizedBox(width: 4),
                  Expanded(
                    child: _DayChunkMark(view: views[indexes[n]]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (var n = 0; n < indexes.length; n++) ...[
                  if (n > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _chunkMinuteLabel(segments[indexes[n]]),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: TickColors.muted,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _chunkMinuteLabel(Segment segment) {
  final m = segment.start.minute;
  return m.toString().padLeft(2, '0');
}

class _DayChunkMark extends StatelessWidget {
  const _DayChunkMark({required this.view});

  final SegmentView view;

  static const _size = 34.0;

  @override
  Widget build(BuildContext context) {
    final done = view.done;
    final current = view.current;
    final border = done || current ? TickColors.yellow : TickColors.line;
    final fillH = current ? _size * view.fraction.clamp(0.1, 1) : 0.0;
    return Center(
      child: SizedBox(
        width: _size,
        height: _size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: done ? TickColors.yellow : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: current ? 2 : 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (current && fillH > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: fillH,
                    child: ColoredBox(
                      color: TickColors.yellow.withValues(alpha: 0.42),
                    ),
                  ),
                Icon(
                  done ? Icons.check_rounded : Icons.circle_outlined,
                  size: done ? 20 : 17,
                  color: done || current ? TickColors.ink : TickColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HourCard extends StatelessWidget {
  const _HourCard({
    required this.l10n,
    required this.segments,
    required this.views,
    required this.indexes,
    required this.dayCompleted,
    required this.dayTotal,
    required this.onOpenDay,
  });

  final AppLocalizations l10n;
  final List<Segment> segments;
  final List<SegmentView> views;
  final List<int> indexes;
  final int dayCompleted;
  final int dayTotal;
  final VoidCallback onOpenDay;

  @override
  Widget build(BuildContext context) {
    final title = _hourSectionTitle(context, segments, indexes);
    return PopCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpenDay,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '$dayCompleted / $dayTotal',
                        style: const TextStyle(
                          color: TickColors.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.unfold_more_rounded,
                        size: 20,
                        color: TickColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final gaps = 8.0 * (indexes.length - 1).clamp(0, 999);
                final tileWidth = indexes.length <= 4
                    ? (constraints.maxWidth - gaps) / indexes.length
                    : 76.0;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var n = 0; n < indexes.length; n++) ...[
                        if (n > 0) const SizedBox(width: 8),
                        SizedBox(
                          width: tileWidth,
                          height: 76,
                          child: _ChunkTile(
                            l10n: l10n,
                            segment: segments[indexes[n]],
                            view: views[indexes[n]],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChunkTile extends StatelessWidget {
  const _ChunkTile({
    required this.l10n,
    required this.segment,
    required this.view,
  });

  final AppLocalizations l10n;
  final Segment segment;
  final SegmentView view;

  @override
  Widget build(BuildContext context) {
    final done = view.done;
    final borderColor =
        done || view.current ? TickColors.yellow : TickColors.line;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: done ? TickColors.yellow : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            if (view.current)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: view.fraction.clamp(0.05, 1)),
                  duration: const Duration(milliseconds: 750),
                  curve: Curves.easeOutCubic,
                  builder: (context, level, _) => _ChunkWaterWave(level: level),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(
                children: [
                  Icon(
                    done ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: done ? TickColors.ink : TickColors.muted,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatHm(segment.start),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (done)
                    Text(
                      l10n.chunkDone,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: TickColors.ink,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChunkWaterWave extends StatefulWidget {
  const _ChunkWaterWave({required this.level});

  final double level;

  @override
  State<_ChunkWaterWave> createState() => _ChunkWaterWaveState();
}

class _ChunkWaterWaveState extends State<_ChunkWaterWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _wave,
      builder: (context, _) {
        return CustomPaint(
          painter: _ChunkWaterPainter(
            level: widget.level,
            phase: _wave.value * 2 * math.pi,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _ChunkWaterPainter extends CustomPainter {
  _ChunkWaterPainter({required this.level, required this.phase});

  final double level;
  final double phase;

  static const _deep = TickColors.yellow;
  static const _shallow = Color(0xFFFFF0C8);
  static const _foam = Color(0xFFFFE9A3);

  @override
  void paint(Canvas canvas, Size size) {
    if (level <= 0 || !size.height.isFinite || size.height <= 0) return;
    final top = size.height * (1 - level.clamp(0.04, 1));
    final body = Rect.fromLTWH(0, top, size.width, size.height - top);

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [_deep, _shallow],
      ).createShader(body);
    final wavePath = Path()..moveTo(0, size.height);
    const waves = 2.2;
    const amp = 3.0;
    for (var x = 0.0; x <= size.width; x++) {
      final y = top +
          math.sin((x / size.width * waves * 2 * math.pi) + phase) * amp;
      wavePath.lineTo(x, y);
    }
    wavePath
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(wavePath, fill);

    final foamPath = Path()..moveTo(0, top);
    for (var x = 0.0; x <= size.width; x++) {
      final y = top +
          math.sin((x / size.width * waves * 2 * math.pi) + phase + 0.6) * amp * 0.65 -
          1.5;
      foamPath.lineTo(x, y);
    }
    canvas.drawPath(
      foamPath,
      Paint()
        ..color = _foam.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ChunkWaterPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.phase != phase;
  }
}

class _TodayPromptBanner extends ConsumerWidget {
  const _TodayPromptBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(labStoreProvider);
    return StreamBuilder<LabFeed>(
      initialData: store.cachedPromptFeed,
      stream: store.watchPrompts(),
      builder: (context, snapshot) {
        final feed = labEffectiveFeed(snapshot, store);
        if (feed == null || labFeedPending(feed)) {
          return _TodayPromptTile(
            title: l10n.labToday,
            subtitle: l10n.labTodayEmpty,
            onTap: () => context.push('/lab'),
          );
        }
        final today = todaysPrompt(feed.prompts);
        if (today == null) {
          return _TodayPromptTile(
            title: l10n.labToday,
            subtitle: l10n.labTodayEmpty,
            onTap: () => context.push('/lab'),
          );
        }
        return _TodayPromptTile(
          title: l10n.labToday,
          subtitle: today.title,
          onTap: () => context.push('/lab/prompt/${today.id}'),
        );
      },
    );
  }
}

class _TodayPromptTile extends StatelessWidget {
  const _TodayPromptTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TickColors.yellow.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: TickColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: TickColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: TickColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.l10n,
    required this.onCall,
    required this.onLab,
    required this.onAway,
  });

  final AppLocalizations l10n;
  final VoidCallback onCall;
  final VoidCallback onLab;
  final VoidCallback onAway;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Tool(
          icon: Icons.phone_in_talk_rounded,
          tint: const Color(0xFFE7F6EA),
          ink: const Color(0xFF3C8F55),
          label: l10n.toolCall,
          onTap: onCall,
        ),
        const SizedBox(width: 8),
        _Tool(
          key: const ValueKey('lab-entry'),
          tint: TickColors.yellow,
          ink: TickColors.ink,
          label: l10n.toolLab,
          onTap: onLab,
          face: const TickMascot(pose: ChickPose.happy, size: 28),
        ),
        const SizedBox(width: 8),
        _Tool(
          icon: Icons.smartphone_rounded,
          tint: const Color(0xFFF3EEFF),
          ink: const Color(0xFF8A74C9),
          label: l10n.toolAway,
          onTap: onAway,
        ),
      ],
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({
    super.key,
    this.icon,
    this.face,
    required this.tint,
    required this.ink,
    required this.label,
    required this.onTap,
  });

  final IconData? icon;
  final Widget? face;
  final Color tint;
  final Color ink;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: TickColors.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: face ?? Icon(icon!, color: ink, size: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: TickColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayDots extends StatelessWidget {
  const _DayDots({
    required this.title,
    required this.completed,
    required this.total,
  });

  final String title;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            Text(
              '$completed / $total',
              style: const TextStyle(
                color: TickColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : completed / total,
            minHeight: 8,
            backgroundColor: const Color(0xFFF0EBE0),
            color: TickColors.yellow,
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Expanded(
          child: Text(
            '$value\n$label',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
