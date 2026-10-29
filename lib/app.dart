import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/copy.dart';
import 'package:tick/ui/router.dart';
import 'package:tick/ui/theme.dart';
import 'package:tick/ui/tutorial_page.dart';
import 'package:tick/ui/update_gate.dart';
import 'package:tick/ui/visuals.dart';

class TickApp extends ConsumerWidget {
  const TickApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: router,
      theme: TickTheme.light(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => _Effects(child: child ?? const SizedBox.shrink()),
    );
  }
}

class _Effects extends ConsumerStatefulWidget {
  const _Effects({required this.child});
  final Widget child;

  @override
  ConsumerState<_Effects> createState() => _EffectsState();
}

class _EffectsState extends ConsumerState<_Effects> with WidgetsBindingObserver {
  int _burstSeen = 0;
  int _encourageSeen = 0;
  int _flashSeen = 0;
  String? _banner;
  ChickPose? _bannerPose;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appControllerProvider.notifier).setForeground(state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appControllerProvider, (previous, next) {
      final l10n = AppLocalizations.of(context);
      if (next.burstNonce != _burstSeen && next.burstCount > 0) {
        _burstSeen = next.burstNonce;
        final text = next.burstCount == 1 ? l10n.burstOne : '${next.burstCount} ${l10n.burstMany}';
        final pose = next.burstCount > 1 ? ChickPose.goodjob : ChickPose.notice;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _banner = text;
            _bannerPose = pose;
          });
        });
        Future<void>.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) {
            setState(() {
              _banner = null;
              _bannerPose = null;
            });
          }
        });
      }
      if (next.encouragementNonce != _encourageSeen && next.encouragementNonce > 0) {
        _encourageSeen = next.encouragementNonce;
      }
      if (next.flash != null && next.flash!.nonce != _flashSeen) {
        _flashSeen = next.flash!.nonce;
        final text = flashText(l10n, next.flash!.code, next.flash!.detail);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
        });
      }
      if (previous?.pendingFreedom != true && next.pendingFreedom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final router = ref.read(routerProvider);
          final id = next.freedomHistoryId;
          switch (next.settings.endAction) {
            case .celebration:
              router.go('/free');
            case .home:
              ref.read(appControllerProvider.notifier).acknowledgeFreedom();
              router.go('/');
            case .history:
              ref.read(appControllerProvider.notifier).acknowledgeFreedom();
              if (id != null) router.go('/history/$id');
          }
        });
      }
      if (previous?.offline != true && next.offline) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.offline)));
        });
      }
    });
    final tutorial = ref.watch(appControllerProvider.select((state) => state.ready && !state.settings.tutorialSeen && state.liveCall == null && !state.camouflage));
    return Stack(
      children: [
        widget.child,
        if (tutorial) const TutorialOverlay(),
        const Positioned.fill(child: UpdateGate()),
        if (_banner != null)
          Positioned(
            top: 72,
            left: 24,
            right: 24,
            child: Material(
              color: TickColors.navy,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Row(
                  children: [
                    if (_bannerPose != null) ...[
                      TickMascot(size: 56, pose: _bannerPose),
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: Text(_banner!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
