import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/domain/schedule.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/theme.dart';

/// Lets the user pick a work pattern (or day off) for [weekday] (1 = Mon … 7 = Sun).
Future<void> pickWeekdayPattern(
  BuildContext context,
  WidgetRef ref,
  int weekday, {
  String? title,
}) async {
  final l10n = AppLocalizations.of(context);
  final patterns = ref.read(appControllerProvider).patterns;
  final current = ref.read(appControllerProvider).week.days[weekday];

  final selection = await showModalBottomSheet<({bool apply, String? id})>(
    context: context,
    backgroundColor: TickColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title ?? l10n.pickWeekdayPattern,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  current == null ? Icons.check_circle : Icons.circle_outlined,
                  color: current == null ? TickColors.ink : TickColors.muted,
                ),
                title: Text(l10n.dayOff),
                onTap: () =>
                    Navigator.pop(context, (apply: true, id: null)),
              ),
              for (final pattern in patterns)
                ListTile(
                  leading: Icon(
                    current == pattern.id
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color:
                        current == pattern.id ? TickColors.ink : TickColors.muted,
                  ),
                  title: Text(
                    pattern.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${pattern.start.label} – ${pattern.end.label}',
                  ),
                  onTap: () =>
                      Navigator.pop(context, (apply: true, id: pattern.id)),
                ),
              if (patterns.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.noPatternsYet,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: TickColors.muted),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  if (!context.mounted || selection == null || !selection.apply) return;
  if (selection.id == current) return;
  ref.read(appControllerProvider.notifier).assignWeekday(weekday, selection.id);
}

String weekdayPatternSubtitle(
  AppLocalizations l10n,
  List<WorkPattern> patterns,
  String? patternId,
) {
  if (patternId == null) return l10n.dayOff;
  for (final pattern in patterns) {
    if (pattern.id == patternId) {
      return '${pattern.name} · ${pattern.start.label} – ${pattern.end.label}';
    }
  }
  return l10n.dayOff;
}
