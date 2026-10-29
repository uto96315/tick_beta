import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/domain/format.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/domain/segments.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/copy.dart';
import 'package:tick/ui/interval_choices.dart';
import 'package:tick/ui/premium_offer.dart';
import 'package:tick/ui/theme.dart';
import 'package:tick/ui/visuals.dart';

class TimerPage extends ConsumerWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final app = ref.watch(appControllerProvider);
    final session = app.session;
    if (session == null) {
      return Scaffold(
        backgroundColor: TickColors.navy,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChickTalk(
                    lines: chickLines(
                      l10n,
                      ChickPose.normal,
                      voice: shownVoice(app.premium, app.settings.chickVoice),
                      custom: app.settings.customChickLine,
                    ),
                    onDark: true,
                  ),
                  const SizedBox(height: 4),
                  const LivingMascot(pose: ChickPose.normal, size: 160),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noSession,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/home'),
                    child: Text(l10n.startTimer),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return NowBuilder(
      builder: (context, now) {
        final segments = buildSegments(
          start: session.actualStart,
          end: session.plannedEnd,
          intervalMinutes: session.intervalMinutes,
        );
        final progress = evaluateSegments(
          segments: segments,
          now: now,
          sessionEnd: session.plannedEnd,
        );
        final views = segmentViews(segments, progress);
        final ratio = progress.total == 0
            ? 0.0
            : progress.completed / progress.total;
        final character = app.settings.visual == TimerVisual.gauge;
        final showBoard = !character;
        final pastShift = !now.isBefore(session.originalPlannedEnd);
        final current = progress.currentIndex == null
            ? null
            : segments[progress.currentIndex!];
        final labels = [
          for (final segment in segments) formatHm(segment.start),
        ];
        final starts = [for (final segment in segments) segment.start];
        final breakSlots = [
          for (final segment in segments) _midBreak(segment, session.breaks),
        ];
        final pose = timerPose(
          ratio: ratio,
          remaining: progress.remainingCount,
          onBreak: session.breaks.any(
            (span) => !now.isBefore(span.start) && now.isBefore(span.end),
          ),
          pastShift: pastShift,
        );
        final lines = chickLines(
          l10n,
          pose,
          voice: shownVoice(app.premium, app.settings.chickVoice),
          custom: app.settings.customChickLine,
        );
        return Scaffold(
          backgroundColor: TickColors.navy,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                    children: [
                      if (character && current != null)
                        Text(
                          '${l10n.nowChunk}  ${formatHm(current.start)} – ${formatHm(current.end)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if (character) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              l10n.todayProgress,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${progress.completed} / ${progress.total}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        HourProgress(
                          views: views,
                          starts: starts,
                          breaks: breakSlots,
                          onlyCurrent: true,
                        ),
                      ],
                      if (!character) ...[
                        Text(
                          '${l10n.remaining} ${progress.remainingCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (!character)
                        IntervalChoices(
                          minutes: session.intervalMinutes,
                          onDark: true,
                          onPreset: (value) => ref
                              .read(appControllerProvider.notifier)
                              .setInterval(value),
                          onCustom: () async {
                            final picked = await askChunkMinutes(
                              context,
                              l10n.customMinutes,
                              session.intervalMinutes,
                            );
                            if (picked != null)
                              ref
                                  .read(appControllerProvider.notifier)
                                  .setInterval(picked);
                          },
                        ),
                      if (!character && current != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.nowChunk}  ${formatHm(current.start)} – ${formatHm(current.end)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (showBoard)
                        SegmentBoard(
                          views: views,
                          visual: app.settings.visual,
                          showCharacter: app.settings.showCharacter,
                          progress: ratio,
                          labels: labels,
                          starts: starts,
                          intervalMinutes: session.intervalMinutes,
                        )
                      else ...[
                        if (app.settings.showCharacter) ...[
                          ChickTalk(lines: lines, onDark: true),
                          const SizedBox(height: 2),
                        ],
                        SizedBox(
                          height: 176,
                          child: CustomPaint(
                            painter: _RingPainter(progress: ratio),
                            child: Center(
                              child: app.settings.showCharacter
                                  ? LivingMascot(pose: pose, size: 118)
                                  : Text(
                                      '${(ratio * 100).round()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                      if (character) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.remaining,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${progress.remainingCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 10),
                        IntervalChoices(
                          minutes: session.intervalMinutes,
                          onDark: true,
                          onPreset: (value) => ref
                              .read(appControllerProvider.notifier)
                              .setInterval(value),
                          onCustom: () async {
                            final picked = await askChunkMinutes(
                              context,
                              l10n.customMinutes,
                              session.intervalMinutes,
                            );
                            if (picked != null)
                              ref
                                  .read(appControllerProvider.notifier)
                                  .setInterval(picked);
                          },
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          formatHms(progress.remaining),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            height: 1,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.plannedEnd} ${formatHm(session.plannedEnd)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (!character) ...[
                        const SizedBox(height: 22),
                        Text(
                          l10n.todayProgress,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final view in views)
                              Icon(
                                view.done ? Icons.check_circle : Icons.circle,
                                size: 18,
                                color: view.done
                                    ? TickColors.mint
                                    : Colors.white24,
                              ),
                          ],
                        ),
                        Text(
                          '${progress.completed} / ${progress.total}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                      const SizedBox(height: 22),
                      if (!character || pastShift) ...[
                        FilledButton(
                          onPressed: () => _extend(context, ref),
                          child: Text(l10n.extend),
                        ),
                        const SizedBox(height: 8),
                      ],
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        onPressed: () =>
                            ref.read(appControllerProvider.notifier).endEarly(),
                        child: Text(l10n.endEarly),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.breakLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (session.breaks.isEmpty)
                        Text(
                          l10n.noBreaks,
                          style: const TextStyle(color: Colors.white54),
                        ),
                      for (final span in session.breaks)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${formatHm(span.start)} – ${formatHm(span.end)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${l10n.breakTotal} ${formatLooseDuration(span.duration)}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _editSessionBreakDuration(
                                  context,
                                  ref,
                                  span,
                                ),
                                icon: const Icon(
                                  Icons.timelapse,
                                  color: Colors.white70,
                                ),
                              ),
                              IconButton(
                                onPressed: () => ref
                                    .read(appControllerProvider.notifier)
                                    .removeSessionBreak(span.id),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          onTap: () =>
                              _editSessionBreakTimes(context, ref, span),
                        ),
                      TextButton(
                        onPressed: () => ref
                            .read(appControllerProvider.notifier)
                            .addSessionBreak(),
                        child: Text(
                          l10n.addBreak,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _openSlack(context, ref),
                      icon: const Icon(Icons.phone_in_talk_outlined, size: 18),
                      label: Text(
                        l10n.slack,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
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

  Future<void> _extend(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF6E8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        var selected = 15;
        return StatefulBuilder(
          builder: (context, setSheet) => Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              20 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TickMascot(size: 120, pose: ChickPose.surprise),
                const SizedBox(height: 8),
                Text(
                  l10n.keepGoing,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: TickColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.extendChoose,
                  style: const TextStyle(color: TickColors.muted),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final minutes in [15, 30, 60])
                      ChoiceChip(
                        label: Text(
                          minutes == 60
                              ? '+1${l10n.hours}'
                              : '+$minutes${l10n.mins}',
                        ),
                        selected: selected == minutes,
                        onSelected: (_) => setSheet(() => selected = minutes),
                      ),
                    ChoiceChip(
                      label: Text(l10n.custom),
                      selected: ![15, 30, 60].contains(selected),
                      onSelected: (_) async {
                        final controller = TextEditingController();
                        final value = await showDialog<int>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.customExtend),
                            content: TextField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(
                                  context,
                                  int.tryParse(controller.text.trim()),
                                ),
                                child: Text(l10n.save),
                              ),
                            ],
                          ),
                        );
                        controller.dispose();
                        if (value != null && value > 0)
                          setSheet(() => selected = value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: Text(l10n.extend),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null && picked > 0)
      ref.read(appControllerProvider.notifier).extendBy(picked);
  }
}

Future<void> _editSessionBreakTimes(
  BuildContext context,
  WidgetRef ref,
  BreakSpan span,
) async {
  final start = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(span.start),
  );
  if (start == null || !context.mounted) return;
  final end = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(span.end),
  );
  if (end == null) return;
  final nextStart = DateTime(
    span.start.year,
    span.start.month,
    span.start.day,
    start.hour,
    start.minute,
  );
  var nextEnd = DateTime(
    span.end.year,
    span.end.month,
    span.end.day,
    end.hour,
    end.minute,
  );
  if (!nextEnd.isAfter(nextStart))
    nextEnd = nextEnd.add(const Duration(days: 1));
  ref
      .read(appControllerProvider.notifier)
      .updateSessionBreak(span.id, start: nextStart, end: nextEnd);
}

Future<void> _editSessionBreakDuration(
  BuildContext context,
  WidgetRef ref,
  BreakSpan span,
) async {
  final l10n = AppLocalizations.of(context);
  final field = TextEditingController(text: '${span.duration.inMinutes}');
  final minutes = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.breakTotal),
      content: TextField(
        controller: field,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: InputDecoration(suffixText: l10n.mins),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, int.tryParse(field.text.trim())),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  field.dispose();
  if (minutes == null || minutes < 1) return;
  ref
      .read(appControllerProvider.notifier)
      .updateSessionBreak(span.id, duration: Duration(minutes: minutes));
}

bool _midBreak(Segment segment, List<BreakSpan> breaks) {
  final mid = segment.start.add(
    Duration(microseconds: segment.length.inMicroseconds ~/ 2),
  );
  return breaks.any(
    (span) => !mid.isBefore(span.start) && mid.isBefore(span.end),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.42;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final base = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = TickColors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, base);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

Future<void> _openSlack(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final app = ref.read(appControllerProvider);
  final first = !app.settings.slackIntroSeen;
  if (first) {
    ref
        .read(appControllerProvider.notifier)
        .updateSettings(app.settings.copyWith(slackIntroSeen: true));
  }
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFFFFF6E8),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          16 + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TickMascot(size: 88, pose: ChickPose.notice),
            const SizedBox(height: 8),
            Text(
              l10n.slack,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: TickColors.ink,
              ),
            ),
            if (first) ...[
              const SizedBox(height: 8),
              Text(
                l10n.slackIntro,
                textAlign: TextAlign.center,
                style: const TextStyle(color: TickColors.ink, height: 1.45),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(sheetContext);
                ref.read(appControllerProvider.notifier).slackCall();
              },
              child: Text(l10n.slackCall),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(sheetContext);
                ref.read(appControllerProvider.notifier).setCamouflage(true);
              },
              child: Text(l10n.slackHide),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.slackWeekly,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TickColors.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(sheetContext);
                showPremiumOffer(context, ref);
              },
              child: const PremiumMark(size: 28),
            ),
          ],
        ),
      );
    },
  );
}
