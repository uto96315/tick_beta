import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/account_page.dart';
import 'package:tick/ui/call_page.dart';
import 'package:tick/ui/camouflage_page.dart';
import 'package:tick/ui/free_page.dart';
import 'package:tick/ui/history_page.dart';
import 'package:tick/ui/home_page.dart';
import 'package:tick/ui/pattern_page.dart';
import 'package:tick/ui/premium_page.dart';
import 'package:tick/ui/schedule_page.dart';
import 'package:tick/ui/settings_page.dart';
import 'package:tick/ui/shell.dart';
import 'package:tick/ui/timer_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _Refresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final app = ref.read(appControllerProvider);
      final loc = state.matchedLocation;
      final call = app.liveCall;
      if (call != null) {
        final target = call.answered ? '/in-call' : '/incoming';
        return loc == target ? null : target;
      }
      if (app.camouflage) return loc == '/camouflage' ? null : '/camouflage';
      if (loc == '/incoming' || loc == '/in-call' || loc == '/camouflage') {
        return app.session != null ? '/timer' : '/home';
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/timer', builder: (_, _) => const TimerPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (_, _) => const HistoryPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => HistoryDetailPage(id: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsPage(),
                routes: [
                  GoRoute(path: 'schedule', builder: (_, _) => const SchedulePage()),
                  GoRoute(
                    path: 'pattern/:id',
                    builder: (_, state) => PatternPage(id: state.pathParameters['id']!),
                  ),
                  GoRoute(path: 'account', builder: (_, _) => const AccountPage()),
                  GoRoute(path: 'premium', builder: (_, _) => const PremiumPage()),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/call', builder: (_, _) => const CallPage()),
      GoRoute(path: '/incoming', builder: (_, _) => const IncomingPage()),
      GoRoute(path: '/in-call', builder: (_, _) => const InCallPage()),
      GoRoute(path: '/camouflage', builder: (_, _) => const CamouflagePage()),
      GoRoute(path: '/free', builder: (_, _) => const FreePage()),
    ],
  );
});

class _Refresh extends ChangeNotifier {
  _Refresh(Ref ref) {
    ref.listen(appControllerProvider, (_, _) => notifyListeners());
  }
}
