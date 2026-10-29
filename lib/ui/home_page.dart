import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/domain/format.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/domain/schedule.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/copy.dart';
import 'package:tick/ui/interval_choices.dart';
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
    return NowBuilder(
      builder: (context, now) {
        final calendar = ScheduleCalendar(patterns: app.patterns, week: app.week, overrides: app.overrides);
        final covering = calendar.shiftCovering(now);
        final upcoming = calendar.upcomingOn(now);
        final running = app.session != null;
        final interval = _interval ?? app.settings.lastIntervalMinutes;
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [TickColors.sky, TickColors.skySoft, TickColors.paper],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(l10n.appTitle, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1)),
                    ),
                  ),
                  const Spacer(),
                  ChickTalk(
                    lines: chickLines(
                      l10n,
                      running ? ChickPose.back : ChickPose.normal,
                      voice: shownVoice(app.premium, app.settings.chickVoice),
                      custom: app.settings.customChickLine,
                    ),
                  ),
                  const SizedBox(height: 2),
                  LivingMascot(pose: running ? ChickPose.back : ChickPose.normal, size: 180),
                  const SizedBox(height: 12),
                  Text(l10n.interval, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  IntervalChoices(
                    minutes: interval,
                    onPreset: (value) => _rememberInterval(value),
                    onCustom: () async {
                      final picked = await askChunkMinutes(context, l10n.customMinutes, interval);
                      if (picked != null) _rememberInterval(picked);
                    },
                  ),
                  const Spacer(),
                  if (app.prompt != null) _prompt(context, app.prompt!, l10n),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: FilledButton.icon(
                      onPressed: () {
                        if (running) {
                          context.go('/timer');
                          return;
                        }
                        _openStart(context, now, covering, upcoming);
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(running ? l10n.continueTimer : l10n.startTimer),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _prompt(BuildContext context, ResolvedShift shift, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: PopCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.startPromptTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${formatHm(shift.start)} – ${formatHm(shift.end)}', style: const TextStyle(color: TickColors.muted)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: FilledButton(onPressed: () => ref.read(appControllerProvider.notifier).acceptPrompt(), child: Text(l10n.startNow))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: () => ref.read(appControllerProvider.notifier).dismissPrompt(), child: Text(l10n.notToday))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStart(BuildContext context, DateTime now, ResolvedShift? covering, ResolvedShift? upcoming) async {
    final l10n = AppLocalizations.of(context);
    final shift = covering ?? upcoming;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TickColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheet) {
            void update(VoidCallback change) {
              setState(change);
              setSheet(() {});
            }

            final interval = _interval ?? ref.read(appControllerProvider).settings.lastIntervalMinutes;
            final end = _resolvedEnd(now);
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.paddingOf(sheetContext).bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: TickColors.line, borderRadius: BorderRadius.circular(4)))),
                  const SizedBox(height: 16),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, label: Text(l10n.endTimeMode)),
                      ButtonSegment(value: true, label: Text(l10n.durationMode)),
                    ],
                    selected: {_byDuration},
                    onSelectionChanged: (value) => update(() => _byDuration = value.first),
                  ),
                  const SizedBox(height: 8),
                  if (_byDuration)
                    Row(
                      children: [
                        Expanded(child: _Stepper(label: l10n.hours, value: _hours, onChanged: (value) => update(() => _hours = value.clamp(0, 23)))),
                        Expanded(child: _Stepper(label: l10n.mins, value: _minutes, onChanged: (value) => update(() => _minutes = value.clamp(0, 59)))),
                      ],
                    )
                  else
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.pickEnd),
                      trailing: Text('${_end.format(context)}  ${_endIsTomorrow(now) ? l10n.tomorrow : l10n.today}', style: const TextStyle(color: TickColors.muted)),
                      onTap: () async {
                        final picked = await showTimePicker(context: sheetContext, initialTime: _end);
                        if (picked != null) update(() => _end = picked);
                      },
                    ),
                  const SizedBox(height: 4),
                  Text(l10n.interval, style: const TextStyle(color: TickColors.muted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  IntervalChoices(
                    minutes: interval,
                    onPreset: (value) {
                      _rememberInterval(value);
                      setSheet(() {});
                    },
                    onCustom: () async {
                      final picked = await askChunkMinutes(sheetContext, l10n.customMinutes, interval);
                      if (picked != null) {
                        _rememberInterval(picked);
                        setSheet(() {});
                      }
                    },
                  ),
                  if (shift != null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(covering != null ? l10n.applyShift : l10n.useShift),
                      subtitle: Text('${formatHm(shift.start)} – ${formatHm(shift.end)}'),
                      value: _useShift,
                      onChanged: (value) => update(() => _useShift = value),
                    ),
                  const SizedBox(height: 8),
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
                      Navigator.pop(sheetContext);
                      if (ref.read(appControllerProvider).session != null) context.go('/timer');
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
    ref.read(appControllerProvider.notifier).updateSettings(settings.copyWith(lastIntervalMinutes: minutes));
  }

  DateTime _resolvedEnd(DateTime now) {
    var end = DateTime(now.year, now.month, now.day, _end.hour, _end.minute);
    if (!end.isAfter(now)) end = end.add(const Duration(days: 1));
    return end;
  }

  bool _endIsTomorrow(DateTime now) => _resolvedEnd(now).day != now.day;

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
        Expanded(child: Text('$value\n$label', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
        IconButton(onPressed: () => onChanged(value + 1), icon: const Icon(Icons.add_circle_outline)),
      ],
    );
  }
}
