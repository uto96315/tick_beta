import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/account_page.dart';
import 'package:tick/ui/call_page.dart';
import 'package:tick/ui/camouflage_page.dart';
import 'package:tick/ui/camouflage_settings_page.dart';
import 'package:tick/ui/free_page.dart';
import 'package:tick/ui/history_page.dart';
import 'package:tick/ui/home_page.dart';
import 'package:tick/ui/lab/hub_page.dart';
import 'package:tick/ui/lab/prompt_list_page.dart';
import 'package:tick/ui/lab/prompt_page.dart';
import 'package:tick/ui/lab/propose_page.dart';
import 'package:tick/ui/lab/review_page.dart';
import 'package:tick/ui/pattern_page.dart';
import 'package:tick/ui/premium_page.dart';
import 'package:tick/ui/schedule_page.dart';
import 'package:tick/ui/settings_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _Refresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
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
      if (loc == '/incoming' || loc == '/in-call' || loc == '/camouflage')
        return '/';
      if (loc == '/home' || loc == '/timer') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomePage()),
      GoRoute(
        path: '/settings',
        pageBuilder: (_, state) => _slide(state, const SettingsPage()),
        routes: [
          GoRoute(
            path: 'schedule',
            pageBuilder: (_, state) => _slide(state, const SchedulePage()),
          ),
          GoRoute(
            path: 'pattern/:id',
            pageBuilder: (_, state) =>
                _slide(state, PatternPage(id: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: 'account',
            pageBuilder: (_, state) => _slide(state, const AccountPage()),
          ),
          GoRoute(
            path: 'premium',
            pageBuilder: (_, state) => _slide(state, const PremiumPage()),
          ),
          GoRoute(
            path: 'camouflage',
            pageBuilder: (_, state) =>
                _slide(state, const CamouflageSettingsPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/history',
        builder: (_, _) => const HistoryPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                HistoryDetailPage(id: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/lab',
        builder: (_, _) => const LabHubPage(),
        routes: [
          GoRoute(
            path: 'list',
            builder: (_, _) => const LabListPage(),
          ),
          GoRoute(
            path: 'prompt/:id',
            builder: (_, state) =>
                LabPromptPage(id: state.pathParameters['id']!),
          ),
          GoRoute(path: 'propose', builder: (_, _) => const LabProposePage()),
          GoRoute(path: 'review', builder: (_, _) => const LabReviewPage()),
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

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

class _Refresh extends ChangeNotifier {
  _Refresh(Ref ref) {
    ref.listen(appControllerProvider, (_, _) => notifyListeners());
  }
}
