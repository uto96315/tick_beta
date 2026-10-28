import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/domain/format.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/domain/segments.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
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
      return Scaffold(body: Center(child: Text(l10n.noSession, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))));
    }
    return NowBuilder(
      builder: (context, now) {
        final segments = buildSegments(start: session.actualStart, end: session.plannedEnd, intervalMinutes: session.intervalMinutes);
        final progress = evaluateSegments(segments: segments, now: now, sessionEnd: session.plannedEnd);
        final views = segmentViews(segments, progress);
        final ratio = progress.total == 0 ? 0.0 : progress.completed / progress.total;
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Text(l10n.timer, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _Big(label: l10n.remaining, value: formatHms(progress.remaining))),
                    const SizedBox(width: 8),
                    Expanded(child: _Big(label: l10n.chunks, value: '${progress.completed}/${progress.total}')),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${l10n.achievement} ${progress.remainingCount}  ·  ${formatHm(session.plannedEnd)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final visual in TimerVisual.values)
                      ChoiceChip(
                        label: Text(_visualLabel(l10n, visual)),
                        selected: app.settings.visual == visual,
                        onSelected: (_) => ref.read(appControllerProvider.notifier).updateSettings(app.settings.copyWith(visual: visual)),
                      ),
                    FilterChip(
                      label: Text(l10n.showCharacter),
                      selected: app.settings.showCharacter,
                      onSelected: (value) => ref.read(appControllerProvider.notifier).updateSettings(app.settings.copyWith(showCharacter: value)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PopCard(
                  child: SegmentBoard(views: views, visual: app.settings.visual, showCharacter: app.settings.showCharacter, progress: ratio),
                ),
                const SizedBox(height: 8),
                Text(l10n.breaksKeepGoing),
                Text(l10n.noPause),
                const SizedBox(height: 12),
                FilledButton(onPressed: () => _extend(context, ref), child: Text(l10n.extend)),
                const SizedBox(height: 8),
                TextButton(onPressed: () => ref.read(appControllerProvider.notifier).endEarly(), child: Text(l10n.endEarly)),
                const SizedBox(height: 8),
                Text(l10n.breakLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                if (session.breaks.isEmpty) Text(l10n.noBreaks),
                for (final span in session.breaks)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${formatHm(span.start)} – ${formatHm(span.end)}'),
                    subtitle: Text('${l10n.breakTotal} ${formatLooseDuration(span.duration)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _editSessionBreakDuration(context, ref, span),
                          icon: const Icon(Icons.timelapse),
                        ),
                        IconButton(
                          onPressed: () => ref.read(appControllerProvider.notifier).removeSessionBreak(span.id),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    onTap: () => _editSessionBreakTimes(context, ref, span),
                  ),
                TextButton(onPressed: () => ref.read(appControllerProvider.notifier).addSessionBreak(), child: Text(l10n.addBreak)),
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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final minutes in [15, 30, 60])
              ListTile(title: Text('$minutes ${l10n.mins}'), onTap: () => Navigator.pop(context, minutes)),
            ListTile(
              title: Text(l10n.custom),
              onTap: () async {
                final controller = TextEditingController();
                final value = await showDialog<int>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.customExtend),
                    content: TextField(controller: controller, keyboardType: TextInputType.number, autofocus: true),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
                      TextButton(
                        onPressed: () => Navigator.pop(context, int.tryParse(controller.text.trim())),
                        child: Text(l10n.save),
                      ),
                    ],
                  ),
                );
                controller.dispose();
                if (context.mounted) Navigator.pop(context, value);
              },
            ),
          ],
        ),
      ),
    );
    if (picked != null && picked > 0) ref.read(appControllerProvider.notifier).extendBy(picked);
  }
}

Future<void> _editSessionBreakTimes(BuildContext context, WidgetRef ref, BreakSpan span) async {
  final start = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(span.start));
  if (start == null || !context.mounted) return;
  final end = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(span.end));
  if (end == null) return;
  final nextStart = DateTime(span.start.year, span.start.month, span.start.day, start.hour, start.minute);
  var nextEnd = DateTime(span.end.year, span.end.month, span.end.day, end.hour, end.minute);
  if (!nextEnd.isAfter(nextStart)) nextEnd = nextEnd.add(const Duration(days: 1));
  ref.read(appControllerProvider.notifier).updateSessionBreak(span.id, start: nextStart, end: nextEnd);
}

Future<void> _editSessionBreakDuration(BuildContext context, WidgetRef ref, BreakSpan span) async {
  final l10n = AppLocalizations.of(context);
  final field = TextEditingController(text: '${span.duration.inMinutes}');
  final minutes = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.breakTotal),
      content: TextField(controller: field, keyboardType: TextInputType.number, autofocus: true, decoration: InputDecoration(suffixText: l10n.mins)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        TextButton(onPressed: () => Navigator.pop(context, int.tryParse(field.text.trim())), child: Text(l10n.save)),
      ],
    ),
  );
  field.dispose();
  if (minutes == null || minutes < 1) return;
  ref.read(appControllerProvider.notifier).updateSessionBreak(span.id, duration: Duration(minutes: minutes));
}

class _Big extends StatelessWidget {
  const _Big({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PopCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

String _visualLabel(AppLocalizations l10n, TimerVisual visual) {
  return switch (visual) {
    TimerVisual.tiles => l10n.visualTiles,
    TimerVisual.map => l10n.visualMap,
    TimerVisual.character => l10n.visualCharacter,
    TimerVisual.gauge => l10n.visualGauge,
  };
}
