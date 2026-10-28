import 'dart:async';

import 'package:flutter/material.dart';

class TickColors {
  static const cream = Color(0xFFFFF3E4);
  static const ink = Color(0xFF2A2140);
  static const coral = Color(0xFFFF5D6C);
  static const grape = Color(0xFF6C5CE7);
  static const mint = Color(0xFF2ED9A5);
  static const sun = Color(0xFFFFC857);
  static const card = Color(0xFFFFFBF7);
}

class TickTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: TickColors.coral, primary: TickColors.coral, secondary: TickColors.grape);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: TickColors.cream,
      fontFamily: 'Nunito',
      textTheme: Typography.material2021().black.apply(bodyColor: TickColors.ink, displayColor: TickColors.ink, fontFamily: 'Nunito'),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: TickColors.card,
        indicatorColor: TickColors.coral.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: TickColors.coral,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}

class PopCard extends StatelessWidget {
  const PopCard({super.key, required this.child, this.color = TickColors.card, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: child,
    );
  }
}

class NowBuilder extends StatefulWidget {
  const NowBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<NowBuilder> createState() => _NowBuilderState();
}

class _NowBuilderState extends State<NowBuilder> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}

