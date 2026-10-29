import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/domain/format.dart';
import 'package:tick/domain/schedule.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/theme.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final app = ref.watch(appControllerProvider);
    final labels = [l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat, l10n.sun];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.schedule)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.patterns, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final pattern in app.patterns) ...[
            PopCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(pattern.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${pattern.start.label} – ${pattern.end.label}${pattern.crossesMidnight ? ' (${l10n.nextDay})' : ''}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/pattern/${pattern.id}'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextButton(
            onPressed: () => context.push('/settings/pattern/new'),
            child: Text(l10n.newPattern),
          ),
          const SizedBox(height: 8),
          Text(l10n.weekdays, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var weekday = 1; weekday <= 7; weekday++)
                _DayDot(
                  label: labels[weekday - 1],
                  on: app.week.days[weekday] != null,
                  onTap: () {
                    final ids = <String?>[null, for (final pattern in app.patterns) pattern.id];
                    final index = ids.indexOf(app.week.days[weekday]);
                    final next = ids[(index < 0 ? 0 : index + 1) % ids.length];
                    ref.read(appControllerProvider.notifier).assignWeekday(weekday, next);
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(l10n.overrides, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          for (final override in app.overrides)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(dateKey(override.date)),
              subtitle: Text(override.holiday ? l10n.holiday : '${override.start?.label ?? ''} – ${override.end?.label ?? ''}'),
              trailing: IconButton(
                onPressed: () => ref.read(appControllerProvider.notifier).deleteOverride(override.id),
                icon: const Icon(Icons.close),
              ),
            ),
          TextButton(onPressed: () => _addOverride(context, ref), child: Text(l10n.addOverride)),
        ],
      ),
    );
  }

  Future<void> _addOverride(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final date = await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: DateTime.now());
    if (date == null || !context.mounted) return;
    final holiday = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addOverride),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.holiday)),
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.customDay)),
        ],
      ),
    );
    if (holiday == null) return;
    ClockTime? start;
    ClockTime? end;
    if (!holiday) {
      if (!context.mounted) return;
      final startTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
      if (startTime == null || !context.mounted) return;
      final endTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
      if (endTime == null) return;
      start = ClockTime(startTime.hour, startTime.minute);
      end = ClockTime(endTime.hour, endTime.minute);
    }
    final now = DateTime.now();
    ref.read(appControllerProvider.notifier).upsertOverride(
      DateOverride(
        id: '${date.year}-${date.month}-${date.day}',
        date: DateTime(date.year, date.month, date.day),
        holiday: holiday,
        name: holiday ? l10n.holiday : l10n.customDay,
        start: start,
        end: end,
        breaks: holiday
            ? const []
            : const [BreakTemplate(id: 'break', start: ClockTime(12, 0), end: ClockTime(13, 0))],
        updatedAt: now,
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? TickColors.yellow : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: on ? TickColors.yellow : TickColors.line),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: TickColors.ink)),
      ),
    );
  }
}
