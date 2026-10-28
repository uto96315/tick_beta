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
    final showFace = ref.watch(appControllerProvider.select((state) => state.settings.showCharacter));
    return Scaffold(
      backgroundColor: TickColors.sun,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const TickMascot(progress: 1, size: 180),
              const SizedBox(height: 12),
              Text(l10n.freeTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, height: 1)),
              const SizedBox(height: 12),
              Text(l10n.freeBody, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
              if (!showFace) const SizedBox.shrink(),
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
