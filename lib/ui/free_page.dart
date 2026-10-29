import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/theme.dart';
import 'package:tick/ui/visuals.dart';

class FreePage extends ConsumerWidget {
  const FreePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: TickColors.skySoft,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const TickMascot(size: 200, pose: ChickPose.love),
              const SizedBox(height: 16),
              Text(l10n.freeTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, height: 1, color: TickColors.ink)),
              const SizedBox(height: 12),
              Text(l10n.freeBody, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: TickColors.muted)),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  ref.read(appControllerProvider.notifier).acknowledgeFreedom();
                  context.go('/home');
                },
                child: Text(l10n.goHome),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  final id = ref.read(appControllerProvider).freedomHistoryId;
                  ref.read(appControllerProvider.notifier).acknowledgeFreedom();
                  if (id == null) {
                    context.go('/history');
                  } else {
                    context.go('/history/$id');
                  }
                },
                child: Text(l10n.seeHistory),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
