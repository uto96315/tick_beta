import 'dart:async';

import 'package:flutter/material.dart';

class TickColors {
  static const sky = Color(0xFFBFE6FB);
  static const skySoft = Color(0xFFEAF6FD);
  static const paper = Color(0xFFF5FAFD);
  static const ink = Color(0xFF1B2A4A);
  static const muted = Color(0xFF7C8BA3);
  static const yellow = Color(0xFFFFD15C);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE3EEF6);
  static const navy = Color(0xFF101A2E);
  static const mint = Color(0xFF3DDC97);
}

class TickTheme {
  static ThemeData light() {
    const ink = TickColors.ink;
    final scheme = ColorScheme.light(
      primary: TickColors.yellow,
      onPrimary: ink,
      secondary: ink,
      onSecondary: Colors.white,
      surface: TickColors.card,
      onSurface: ink,
    );
    const label = TextStyle(fontFamily: 'Nunito', color: ink, fontWeight: FontWeight.w600);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: TickColors.paper,
      fontFamily: 'Nunito',
      textTheme: Typography.material2021().black.apply(bodyColor: ink, displayColor: ink, fontFamily: 'Nunito'),
      appBarTheme: const AppBarTheme(
        backgroundColor: TickColors.paper,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontFamily: 'Nunito', color: ink, fontSize: 17, fontWeight: FontWeight.w700),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: TickColors.card,
        indicatorColor: TickColors.yellow.withValues(alpha: 0.7),
        labelTextStyle: WidgetStateProperty.all(label.copyWith(fontSize: 12)),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? ink : TickColors.muted);
        }),
        height: 64,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: TickColors.card,
        selectedColor: TickColors.yellow,
        labelStyle: label,
        secondaryLabelStyle: label,
        side: const BorderSide(color: TickColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(color: TickColors.line, space: 1, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: TickColors.yellow,
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: TickColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: ink)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TickColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TickColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TickColors.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: ink, width: 1.4)),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x121B2A4A), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
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
