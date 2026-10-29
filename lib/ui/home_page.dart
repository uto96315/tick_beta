import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/domain/format.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/domain/schedule.dart';
import 'package:tick/domain/segments.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/copy.dart';
import 'package:tick/ui/interval_choices.dart';
import 'package:tick/ui/theme.dart';
import 'package:tick/ui/visuals.dart';

const _cream = Color(0xFFFFF6E8);

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
        final remainCount =
            progress?.remainingCount ??
            (shiftEnd.isAfter(now)
                ? buildSegments(
                    start: now,
                    end: shiftEnd,
                    intervalMinutes: interval,
                  ).length
                : 0);
        final hourIndexes = [
          for (var i = 0; i < segments.length; i++)
            if (segments[i].start.hour == now.hour &&
                segments[i].start.day == now.day)
              i,
        ];
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
              )
            : ChickPose.tired;
        final lines = app.mood != null
            ? moodLines(l10n, app.mood!)
            : chickLines(
                l10n,
                pose,
                voice: shownVoice(app.premium, app.settings.chickVoice),
                custom: app.settings.customChickLine,
              );
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    children: [
                      _TimeCard(
                        label: l10n.shiftClock,
                        clock: formatHm(shiftEnd),
                        remaining: _chunkLeft(context, remainCount),
                        onTap: running
                            ? null
                            : () =>
                                  _openStart(context, now, covering, upcoming),
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: 12),
                        _DayDots(
                          title: l10n.todaySoFar,
                          completed: progress.completed,
                          total: progress.total,
                          views: views,
                        ),
                      ],
                      const SizedBox(height: 8),
                      ChickTalk(lines: lines),
                      const SizedBox(height: 2),
                      Center(child: LivingMascot(pose: pose, size: 168)),
                      if (running && hourIndexes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _HourCard(
                          l10n: l10n,
                          segments: segments,
                          views: views,
                          indexes: hourIndexes,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _ToolRow(
                        l10n: l10n,
                        onCall: () => context.push('/call'),
                        onBreak: running
                            ? () => ref
                                  .read(appControllerProvider.notifier)
                                  .addSessionBreak()
                            : null,
                        onExcuse: () => _openExcuses(context, l10n),
                        onAway: () => ref
                            .read(appControllerProvider.notifier)
                            .setCamouflage(true),
                      ),
                      const SizedBox(height: 12),
                      _MoodCard(
                        l10n: l10n,
                        mood: app.mood,
                        onPick: (mood) => ref
                            .read(appControllerProvider.notifier)
                            .setMood(mood),
                      ),
                      if (app.prompt != null) ...[
                        const SizedBox(height: 12),
                        _prompt(context, app.prompt!, l10n),
                      ],
                      if (!running) ...[
                        const SizedBox(height: 16),
                        Text(
                          l10n.interval,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        IntervalChoices(
                          minutes: interval,
                          onPreset: (value) => _rememberInterval(value),
                          onCustom: () async {
                            final picked = await askChunkMinutes(
                              context,
                              l10n.customMinutes,
                              interval,
                            );
                            if (picked != null) _rememberInterval(picked);
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: TickColors.ink,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onPressed: () =>
                                _openStart(context, now, covering, upcoming),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(l10n.startTimer),
                          ),
                        ),
                      ],
                    ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: PopCard(
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

  Future<void> _openExcuses(BuildContext context, AppLocalizations l10n) async {
    final lines = [
      l10n.excuse1,
      l10n.excuse2,
      l10n.excuse3,
      l10n.excuse4,
      l10n.excuse5,
    ];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            8,
            16,
            8,
            12 + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.excuseTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              for (final line in lines)
                ListTile(
                  title: Text(line),
                  trailing: const Icon(Icons.copy_rounded, size: 18),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: line));
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.excuseCopied)));
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

String _chunkLeft(BuildContext context, int count) {
  final ja = Localizations.localeOf(context).languageCode == 'ja';
  if (ja) return '残り $countコマ';
  return '$count left';
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.label,
    required this.clock,
    required this.remaining,
    this.onTap,
  });

  final String label;
  final String clock;
  final String remaining;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PopCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$label $clock',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remaining,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: TickColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: TickColors.muted),
          ],
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
  });

  final AppLocalizations l10n;
  final List<Segment> segments;
  final List<SegmentView> views;
  final List<int> indexes;

  @override
  Widget build(BuildContext context) {
    final done = indexes.where((index) => views[index].done).length;
    return PopCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.hourNow(indexes.length),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '$done / ${indexes.length}',
                style: const TextStyle(
                  color: TickColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final gaps = 8.0 * (indexes.length - 1);
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
    final endMinute =
        segment.end.minute == 0 && segment.end.hour != segment.start.hour
        ? 60
        : segment.end.minute;
    final range = '${segment.start.minute}-$endMinute';
    final done = view.done;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: done ? TickColors.yellow : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done || view.current ? TickColors.yellow : TickColors.line,
        ),
      ),
      child: Padding(
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
              done ? l10n.chunkDone : range,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            if (done)
              Text(
                range,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: TickColors.ink,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.l10n,
    required this.onCall,
    required this.onBreak,
    required this.onExcuse,
    required this.onAway,
  });

  final AppLocalizations l10n;
  final VoidCallback onCall;
  final VoidCallback? onBreak;
  final VoidCallback onExcuse;
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
        _Tool(
          icon: Icons.coffee_rounded,
          tint: const Color(0xFFFFF1E4),
          ink: const Color(0xFFD4894C),
          label: l10n.toolBreak,
          onTap: onBreak,
        ),
        _Tool(
          icon: Icons.chat_bubble_outline_rounded,
          tint: const Color(0xFFEAF2FF),
          ink: const Color(0xFF6E8CB8),
          label: l10n.toolExcuse,
          onTap: onExcuse,
        ),
        _Tool(
          icon: Icons.directions_walk_rounded,
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
    required this.icon,
    required this.tint,
    required this.ink,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final Color ink;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: onTap == null ? TickColors.line : tint,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(
                    icon,
                    color: onTap == null ? TickColors.muted : ink,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({
    required this.l10n,
    required this.mood,
    required this.onPick,
  });

  final AppLocalizations l10n;
  final ChickMood? mood;
  final ValueChanged<ChickMood> onPick;

  @override
  Widget build(BuildContext context) {
    const faces = [
      (ChickMood.heavy, ChickPose.tired),
      (ChickMood.sleepy, ChickPose.sleep),
      (ChickMood.hungry, ChickPose.hungry),
      (ChickMood.cheer, ChickPose.goodjob),
      (ChickMood.fine, ChickPose.happy),
      (ChickMood.away, ChickPose.back),
    ];
    return PopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.moodTitle,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final face in faces)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => onPick(face.$1),
                      borderRadius: BorderRadius.circular(16),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: mood == face.$1
                              ? TickColors.yellow
                              : const Color(0xFFFFFBF4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SizedBox(
                          width: 76,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              children: [
                                TickMascot(pose: face.$2, size: 44),
                                const SizedBox(height: 2),
                                Text(
                                  _moodLabel(l10n, face.$1),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _moodLabel(AppLocalizations l10n, ChickMood mood) {
  return switch (mood) {
    ChickMood.heavy => l10n.moodHeavy,
    ChickMood.sleepy => l10n.moodSleepy,
    ChickMood.hungry => l10n.moodHungry,
    ChickMood.cheer => l10n.moodCheer,
    ChickMood.fine => l10n.moodFine,
    ChickMood.away => l10n.moodAway,
  };
}

class _DayDots extends StatelessWidget {
  const _DayDots({
    required this.title,
    required this.completed,
    required this.total,
    required this.views,
  });

  final String title;
  final int completed;
  final int total;
  final List<SegmentView> views;

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
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final view in views)
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: view.done || view.current
                        ? TickColors.yellow
                        : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: view.done || view.current
                          ? TickColors.yellow
                          : TickColors.line,
                    ),
                  ),
                ),
              const Icon(
                Icons.flag_rounded,
                size: 16,
                color: TickColors.yellow,
              ),
            ],
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
