import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/domain/format.dart';
import 'package:tick/domain/schedule.dart';
import 'package:tick/domain/segments.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/theme.dart';
import 'package:tick/ui/visuals.dart';

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
    final interval = _interval ?? app.settings.lastIntervalMinutes;
    return NowBuilder(
      builder: (context, now) {
        final calendar = ScheduleCalendar(patterns: app.patterns, week: app.week, overrides: app.overrides);
        final covering = calendar.shiftCovering(now);
        final upcoming = calendar.upcomingOn(now);
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.appTitle, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, height: 1)),
                          const SizedBox(height: 4),
                          Text(l10n.tagline),
                        ],
                      ),
                    ),
                    TickMascot(progress: app.session == null ? 0.2 : 0.8, size: 84, showFace: app.settings.showCharacter),
                  ],
                ),
                const SizedBox(height: 18),
                if (app.prompt != null) _promptCard(context, app.prompt!, l10n),
                if (app.session != null) _running(context, app.session!, now, l10n) else _setup(context, now, covering, upcoming, interval, l10n),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _Shortcut(icon: Icons.phone_in_talk_rounded, label: l10n.fakeCall, onTap: () => context.push('/call'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Shortcut(
                        icon: Icons.visibility_off_rounded,
                        label: l10n.camouflage,
                        onTap: () => ref.read(appControllerProvider.notifier).setCamouflage(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _promptCard(BuildContext context, ResolvedShift shift, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PopCard(
        color: TickColors.sun,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.startPromptTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('${formatHm(shift.start)} – ${formatHm(shift.end)}  ${shift.label}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(onPressed: () => ref.read(appControllerProvider.notifier).acceptPrompt(), child: Text(l10n.startNow)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(onPressed: () => ref.read(appControllerProvider.notifier).dismissPrompt(), child: Text(l10n.notToday)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _running(BuildContext context, session, DateTime now, AppLocalizations l10n) {
    final segments = buildSegments(start: session.actualStart, end: session.plannedEnd, intervalMinutes: session.intervalMinutes);
    final progress = evaluateSegments(segments: segments, now: now, sessionEnd: session.plannedEnd);
    return PopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.running, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _Stats(remaining: formatHms(progress.remaining), done: progress.completed, total: progress.total, l10n: l10n),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => context.go('/timer'), child: Text(l10n.continueTimer)),
        ],
      ),
    );
  }

  Widget _setup(BuildContext context, DateTime now, ResolvedShift? covering, ResolvedShift? upcoming, int interval, AppLocalizations l10n) {
    final end = _resolvedEnd(now);
    final shift = covering ?? upcoming;
    return PopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l10n.endTimeMode)),
              ButtonSegment(value: true, label: Text(l10n.durationMode)),
            ],
            selected: {_byDuration},
            onSelectionChanged: (value) => setState(() => _byDuration = value.first),
          ),
          const SizedBox(height: 12),
          if (_byDuration)
            Row(
              children: [
                Expanded(child: _Stepper(label: l10n.hours, value: _hours, onChanged: (value) => setState(() => _hours = value.clamp(0, 23)))),
                const SizedBox(width: 8),
                Expanded(child: _Stepper(label: l10n.mins, value: _minutes, onChanged: (value) => setState(() => _minutes = value.clamp(0, 59)))),
              ],
            )
          else
            OutlinedButton(
              onPressed: () async {
                final picked = await showTimePicker(context: context, initialTime: _end);
                if (picked != null) setState(() => _end = picked);
              },
              child: Text('${l10n.pickEnd}  ${_end.format(context)}  ${_endIsTomorrow(now) ? l10n.tomorrow : l10n.today}'),
            ),
          const SizedBox(height: 12),
          Text(l10n.interval, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(l10n.intervalHelp, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final preset in [10, 15, 25, 30, 60])
                ChoiceChip(
                  label: Text('$preset'),
                  selected: interval == preset,
                  onSelected: (_) => setState(() => _interval = preset),
                ),
              ChoiceChip(
                label: Text(l10n.custom),
                selected: ![10, 15, 25, 30, 60].contains(interval),
                onSelected: (_) async {
                  final picked = await _askMinutes(context, l10n.customMinutes, interval);
                  if (picked != null) setState(() => _interval = picked);
                },
              ),
            ],
          ),
          if (shift != null) ...[
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(covering != null ? l10n.applyShift : l10n.useShift),
              subtitle: Text('${formatHm(shift.start)} – ${formatHm(shift.end)}${shift.end.day != shift.start.day ? ' (${l10n.nextDay})' : ''}'),
              value: _useShift,
              onChanged: (value) => setState(() => _useShift = value),
            ),
          ],
          if (upcoming != null && covering == null) ...[
            const SizedBox(height: 4),
            Text(l10n.upcomingAuto, style: const TextStyle(fontSize: 13)),
          ],
          const SizedBox(height: 8),
          Text(l10n.noShiftNeeded, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final selected = _useShift ? shift : null;
              final planned = selected != null && !_byDuration ? selected.end : (_byDuration ? now.add(Duration(hours: _hours, minutes: _minutes)) : end);
              ref.read(appControllerProvider.notifier).startManual(
                plannedEnd: planned,
                intervalMinutes: interval,
                anchorStart: selected != null && covering != null && _useShift ? selected.start : null,
                originalPlannedEnd: selected?.end,
                shiftKey: selected != null && _useShift ? selected.key : null,
                patternId: selected?.patternId,
                breaks: selected != null && _useShift ? selected.breaks : const [],
              );
              if (ref.read(appControllerProvider).session != null) context.go('/timer');
            },
            child: Text(l10n.start),
          ),
        ],
      ),
    );
  }

  DateTime _resolvedEnd(DateTime now) {
    var end = DateTime(now.year, now.month, now.day, _end.hour, _end.minute);
    if (!end.isAfter(now)) end = end.add(const Duration(days: 1));
    return end;
  }

  bool _endIsTomorrow(DateTime now) => _resolvedEnd(now).day != now.day;

  Future<int?> _askMinutes(BuildContext context, String title, int initial) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: '$initial');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, keyboardType: TextInputType.number, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value < 1) return;
              Navigator.pop(context, value);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.remaining, required this.done, required this.total, required this.l10n});
  final String remaining;
  final int done;
  final int total;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Stat(label: l10n.remaining, value: remaining)),
        const SizedBox(width: 8),
        Expanded(child: _Stat(label: l10n.chunks, value: '$done/$total')),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: TickColors.cream, borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: () => onChanged(value - 1), icon: const Icon(Icons.remove_circle_outline)),
        Expanded(child: Text('$value\n$label', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))),
        IconButton(onPressed: () => onChanged(value + 1), icon: const Icon(Icons.add_circle_outline)),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PopCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: TickColors.grape),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
  }
}
