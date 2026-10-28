import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/domain/segments.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/ui/theme.dart';

class TickMascot extends StatelessWidget {
  const TickMascot({super.key, required this.progress, this.size = 120, this.showFace = true});

  final double progress;
  final double size;
  final bool showFace;

  @override
  Widget build(BuildContext context) {
    final scale = 0.82 + progress.clamp(0, 1) * 0.38;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MascotPainter(progress: progress.clamp(0, 1), showFace: showFace, scale: scale),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  _MascotPainter({required this.progress, required this.showFace, required this.scale});

  final double progress;
  final bool showFace;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 4);
    final radius = size.shortestSide * 0.34 * scale;
    final body = Paint()..color = Color.lerp(const Color(0xFFFFB4C0), TickColors.coral, progress)!;
    canvas.drawCircle(center, radius, body);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = TickColors.ink.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    if (!showFace) {
      final star = Paint()..color = TickColors.sun;
      canvas.drawCircle(center, radius * 0.28, star);
      return;
    }
    final eye = Paint()..color = TickColors.ink;
    canvas.drawCircle(center + Offset(-radius * 0.28, -radius * 0.12), radius * 0.08, eye);
    canvas.drawCircle(center + Offset(radius * 0.28, -radius * 0.12), radius * 0.08, eye);
    final smile = Path()
      ..moveTo(center.dx - radius * 0.28, center.dy + radius * 0.16)
      ..quadraticBezierTo(center.dx, center.dy + radius * (0.28 + progress * 0.2), center.dx + radius * 0.28, center.dy + radius * 0.16);
    canvas.drawPath(
      smile,
      Paint()
        ..color = TickColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    if (progress > 0.45) {
      canvas.drawCircle(center + Offset(0, -radius * 0.95), radius * 0.16, Paint()..color = TickColors.sun);
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.showFace != showFace;
}

class SegmentBoard extends StatelessWidget {
  const SegmentBoard({
    super.key,
    required this.views,
    required this.visual,
    required this.showCharacter,
    required this.progress,
  });

  final List<SegmentView> views;
  final TimerVisual visual;
  final bool showCharacter;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return switch (visual) {
      TimerVisual.tiles => _Tiles(views: views),
      TimerVisual.map => _Map(views: views),
      TimerVisual.character => _Character(views: views, progress: progress, showFace: showCharacter),
      TimerVisual.gauge => _Gauge(views: views, progress: progress, showCharacter: showCharacter),
    };
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles({required this.views});
  final List<SegmentView> views;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: views.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8),
      itemBuilder: (context, index) {
        final view = views[index];
        final color = view.done ? TickColors.mint : view.current ? TickColors.coral : Colors.white;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: view.done || view.current ? 1 : 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: view.current ? TickColors.ink : Colors.transparent, width: 2),
          ),
          child: Stack(
            children: [
              if (view.current)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: view.fraction.clamp(0.05, 1),
                    widthFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                      ),
                    ),
                  ),
                ),
              Center(
                child: view.done
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
                    : Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Map extends StatelessWidget {
  const _Map({required this.views});
  final List<SegmentView> views;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        for (var i = 0; i < views.length; i++)
          Align(
            alignment: i.isEven ? Alignment.centerLeft : Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: views[i].current ? 64 : 48,
                    height: views[i].current ? 64 : 48,
                    decoration: BoxDecoration(
                      color: views[i].done ? TickColors.sun : views[i].current ? TickColors.grape : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: TickColors.ink, width: views[i].current ? 3 : 1),
                    ),
                    alignment: Alignment.center,
                    child: views[i].done
                        ? const Icon(Icons.star_rounded, color: TickColors.ink)
                        : Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  if (views[i].current) ...[
                    const SizedBox(width: 8),
                    Text(l10n.stage, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Character extends StatelessWidget {
  const _Character({required this.views, required this.progress, required this.showFace});
  final List<SegmentView> views;
  final double progress;
  final bool showFace;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TickMascot(progress: progress, size: 180, showFace: showFace),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final view in views)
              Icon(
                view.done ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: view.done ? TickColors.coral : TickColors.ink.withValues(alpha: 0.35),
                size: view.current ? 22 : 16,
              ),
          ],
        ),
      ],
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({required this.views, required this.progress, required this.showCharacter});
  final List<SegmentView> views;
  final double progress;
  final bool showCharacter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: CustomPaint(
        painter: _GaugePainter(progress: progress, ticks: views.length),
        child: Center(
          child: showCharacter ? TickMascot(progress: progress, size: 96) : Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress, required this.ticks});
  final double progress;
  final int ticks;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.38;
    final base = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = TickColors.coral
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = math.pi * 0.8;
    const sweep = math.pi * 1.4;
    canvas.drawArc(rect, start, sweep, false, base);
    canvas.drawArc(rect, start, sweep * progress.clamp(0, 1), false, arc);
    final tickPaint = Paint()
      ..color = TickColors.ink.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    for (var i = 0; i < ticks; i++) {
      final t = ticks == 1 ? 1.0 : i / (ticks - 1);
      final angle = start + sweep * t;
      final inner = Offset(math.cos(angle), math.sin(angle)) * (radius - 18);
      final outer = Offset(math.cos(angle), math.sin(angle)) * (radius - 8);
      canvas.drawLine(center + inner, center + outer, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.ticks != ticks;
}
