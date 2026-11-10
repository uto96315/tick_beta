import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/domain/schedule.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/theme.dart';

class ScheduleSetupOverlay extends ConsumerStatefulWidget {
  const ScheduleSetupOverlay({super.key});

  @override
  ConsumerState<ScheduleSetupOverlay> createState() =>
      _ScheduleSetupOverlayState();
}

class _ScheduleSetupOverlayState extends ConsumerState<ScheduleSetupOverlay> {
  ClockTime _start = const ClockTime(9, 0);
  ClockTime _end = const ClockTime(18, 0);
  var _saturday = false;
  var _sunday = false;
  var _loaded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final patterns = ref.watch(
      appControllerProvider.select((state) => state.patterns),
    );
    if (!_loaded) {
      WorkPattern? seed;
      for (final pattern in patterns) {
        if (pattern.id == 'default') {
          seed = pattern;
          break;
        }
      }
      seed ??= patterns.isNotEmpty ? patterns.first : null;
      if (seed != null) {
        _start = seed.start;
        _end = seed.end;
      }
      _loaded = true;
    }

    return Material(
      color: TickColors.cream,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.scheduleSetupTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: TickColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.scheduleSetupBody,
                style: const TextStyle(
                  color: TickColors.muted,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              PopCard(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(l10n.startTime),
                      trailing: Text(
                        _start.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onTap: () => _pickTime(start: true),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(l10n.endTime),
                      trailing: Text(
                        _end.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onTap: () => _pickTime(start: false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.scheduleSetupDaysOptional,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.sat),
                value: _saturday,
                onChanged: (value) => setState(() => _saturday = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.sun),
                value: _sunday,
                onChanged: (value) => setState(() => _sunday = value),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _save,
                child: Text(l10n.scheduleSetupSave),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime({required bool start}) async {
    final initial = start ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (picked == null) return;
    setState(() {
      final clock = ClockTime(picked.hour, picked.minute);
      if (start) {
        _start = clock;
      } else {
        _end = clock;
      }
    });
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final notifier = ref.read(appControllerProvider.notifier);
    final existing = ref.read(appControllerProvider).patterns;
    WorkPattern? prior;
    for (final pattern in existing) {
      if (pattern.id == 'default') {
        prior = pattern;
        break;
      }
    }
    prior ??= existing.isNotEmpty ? existing.first : null;
    final id = prior?.id ?? 'default';
    final name = prior?.name ??
        (Localizations.localeOf(context).languageCode == 'ja'
            ? 'ふつうの一日'
            : 'Regular day');
    notifier.upsertPattern(
      WorkPattern(
        id: id,
        name: name,
        start: _start,
        end: _end,
        breaks: prior?.breaks ??
            const [
              BreakTemplate(
                id: 'lunch',
                start: ClockTime(12, 0),
                end: ClockTime(13, 0),
              ),
            ],
        updatedAt: now,
      ),
    );
    final days = <int, String?>{
      1: id,
      2: id,
      3: id,
      4: id,
      5: id,
      if (_saturday) 6: id,
      if (_sunday) 7: id,
    };
    for (final entry in days.entries) {
      notifier.assignWeekday(entry.key, entry.value);
    }
    notifier.completeScheduleSetup();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.scheduleSetupDone)),
    );
  }
}
