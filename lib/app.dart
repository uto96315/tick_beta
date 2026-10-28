import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/copy.dart';
import 'package:tick/ui/router.dart';
import 'package:tick/ui/theme.dart';

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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _banner = text);
        });
        Future<void>.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) setState(() => _banner = null);
        });
      }
      if (next.encouragementNonce != _encourageSeen && next.encouragementNonce > 0) {
        _encourageSeen = next.encouragementNonce;
        final message = encouragement(l10n, next.encouragementIndex);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.extend),
              content: Text(message),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close))],
            ),
          );
        });
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
              router.go('/home');
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
    return Stack(
      children: [
        widget.child,
        if (_banner != null)
          Positioned(
            top: 72,
            left: 24,
            right: 24,
            child: Material(
              color: TickColors.grape,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Text(_banner!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              ),
            ),
          ),
      ],
    );
  }
}
