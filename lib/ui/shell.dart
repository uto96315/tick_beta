import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/l10n/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex.clamp(0, shell.route.branches.length - 1),
        onDestinationSelected: (index) {
          if (index < 0 || index >= shell.route.branches.length) return;
          shell.goBranch(index, initialLocation: index == shell.currentIndex);
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_rounded), label: l10n.home),
          NavigationDestination(icon: const Icon(Icons.timer_rounded), label: l10n.timer),
          NavigationDestination(icon: const Icon(Icons.history_rounded), label: l10n.history),
          NavigationDestination(icon: const Icon(Icons.settings_rounded), label: l10n.settings),
        ],
      ),
    );
  }
}
