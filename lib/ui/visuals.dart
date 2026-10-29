import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/domain/segments.dart';
import 'package:tick/ui/theme.dart';

enum ChickPose {
  normal,
  happy,
  cheer,
  back,
  tired,
  attention,
  notice,
  love,
  hungry,
  done,
  goodjob,
  surprise,
  sleep,
}

/// Pose for the ring timer. Break and a finished day win over the progress ladder.
ChickPose timerPose({
  required double ratio,
  required int remaining,
  required bool onBreak,
  required bool pastShift,
}) {
  if (onBreak) return ChickPose.sleep;
  if (ratio >= 1) return ChickPose.done;
  if (pastShift) return ChickPose.surprise;
  if (remaining <= 3) return ChickPose.attention;
  if (ratio >= 0.55) return ChickPose.cheer;
  if (ratio >= 0.25) return ChickPose.happy;
  return ChickPose.tired;
}

class TickMascot extends StatelessWidget {
  const TickMascot({
    super.key,
    this.progress = 0,
    this.size = 120,
    this.showFace = true,
    this.pose,
  });

  final double progress;
  final double size;
  final bool showFace;
  final ChickPose? pose;

  static const _assets = {
    ChickPose.normal: 'assets/images/character/main/normal.png',
    ChickPose.happy: 'assets/images/character/main/happy.png',
    ChickPose.cheer: 'assets/images/character/main/happy02.png',
    ChickPose.back: 'assets/images/character/main/back.png',
    ChickPose.tired: 'assets/images/character/main/tired.png',
    ChickPose.attention: 'assets/images/character/main/attention.png',
    ChickPose.notice: 'assets/images/character/main/notice.png',
    ChickPose.love: 'assets/images/character/main/love.png',
    ChickPose.hungry: 'assets/images/character/main/hungly.png',
    ChickPose.done: 'assets/images/character/main/done.png',
    ChickPose.goodjob: 'assets/images/character/main/goodjob.png',
    ChickPose.surprise: 'assets/images/character/main/surprise.png',
    ChickPose.sleep: 'assets/images/character/main/sleep.png',
  };

  ChickPose get _pose {
    if (pose != null) return pose!;
    final value = progress.clamp(0, 1);
    if (value >= 1) return ChickPose.done;
    if (value >= 0.75) return ChickPose.goodjob;
    if (value >= 0.45) return ChickPose.happy;
    return ChickPose.tired;
  }

  @override
  Widget build(BuildContext context) {
    if (!showFace) return SizedBox(width: size, height: size);
    return Image.asset(
      _assets[_pose]!,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class LivingMascot extends StatefulWidget {
  const LivingMascot({super.key, required this.pose, this.size = 120});

  final ChickPose pose;
  final double size;

  @override
  State<LivingMascot> createState() => _LivingMascotState();
}

class _LivingMascotState extends State<LivingMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: _span(widget.pose),
  )..repeat(reverse: true);

  @override
  void didUpdateWidget(LivingMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pose != widget.pose) _motion.duration = _span(widget.pose);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, child) => _move(widget.pose, _motion.value, child!),
        child: TickMascot(size: widget.size, pose: widget.pose),
      ),
    );
  }
}

Duration _span(ChickPose pose) {
  return switch (pose) {
    ChickPose.sleep => const Duration(milliseconds: 1800),
    ChickPose.tired || ChickPose.hungry => const Duration(milliseconds: 1500),
    ChickPose.surprise => const Duration(milliseconds: 700),
    ChickPose.cheer ||
    ChickPose.happy ||
    ChickPose.goodjob ||
    ChickPose.done ||
    ChickPose.love => const Duration(milliseconds: 680),
    ChickPose.back => const Duration(milliseconds: 520),
    _ => const Duration(milliseconds: 1100),
  };
}

Widget _move(ChickPose pose, double t, Widget child) {
  final wave = (t - 0.5) * 2;
  return switch (pose) {
    ChickPose.sleep => Transform.translate(
      offset: Offset(0, 4 * math.sin(t * math.pi)),
      child: child,
    ),
    ChickPose.back => Transform.translate(
      offset: Offset(7 * wave, -5 * (1 - wave.abs())),
      child: child,
    ),
    ChickPose.surprise => Transform.translate(
      offset: Offset(0, -14 * math.sin(t * math.pi)),
      child: child,
    ),
    ChickPose.tired => Transform.rotate(
      angle: 0.05 * wave,
      child: Transform.translate(offset: Offset(0, 4 * t), child: child),
    ),
    ChickPose.hungry => Transform.rotate(
      angle: 0.04 * wave,
      child: Transform.translate(offset: Offset(0, 5 * t), child: child),
    ),
    ChickPose.attention ||
    ChickPose.notice => Transform.rotate(angle: 0.07 * wave, child: child),
    ChickPose.cheer ||
    ChickPose.happy ||
    ChickPose.goodjob ||
    ChickPose.done ||
    ChickPose.love => Transform.translate(
      offset: Offset(0, -8 * math.sin(t * math.pi)),
      child: child,
    ),
    _ => Transform.translate(
      offset: Offset(0, -4 * math.sin(t * math.pi)),
      child: child,
    ),
  };
}

class ChickTalk extends StatefulWidget {
  const ChickTalk({super.key, required this.lines, this.onDark = false});

  final List<String> lines;
  final bool onDark;

  @override
  State<ChickTalk> createState() => _ChickTalkState();
}

class _ChickTalkState extends State<ChickTalk> {
  Timer? _timer;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || widget.lines.isEmpty) return;
      setState(() => _index++);
    });
  }

  @override
  void didUpdateWidget(ChickTalk oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lines.join('\n') != widget.lines.join('\n')) _index = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lines.isEmpty) return const SizedBox.shrink();
    final line = widget.lines[_index % widget.lines.length];
    final background = widget.onDark ? Colors.white : TickColors.navy;
    final foreground = widget.onDark ? TickColors.ink : Colors.white;
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: ConstrainedBox(
            key: ValueKey(line),
            constraints: const BoxConstraints(maxWidth: 280),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Text(
                  line,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -5),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: ColoredBox(
              color: background,
              child: const SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class SegmentBoard extends StatelessWidget {
  const SegmentBoard({
    super.key,
    required this.views,
    required this.visual,
    required this.showCharacter,
    required this.progress,
    this.labels = const [],
    this.starts = const [],
    this.intervalMinutes,
  });

  final List<SegmentView> views;
  final TimerVisual visual;
  final bool showCharacter;
  final double progress;
  final List<String> labels;
  final List<DateTime> starts;
  final int? intervalMinutes;

  @override
  Widget build(BuildContext context) {
    return switch (visual) {
      TimerVisual.tiles => _Tiles(
        views: views,
        labels: labels,
        starts: starts,
        intervalMinutes: intervalMinutes,
      ),
      TimerVisual.map => _Map(views: views),
      TimerVisual.character => _Character(
        views: views,
        progress: progress,
        showFace: showCharacter,
      ),
      TimerVisual.gauge => _Gauge(
        views: views,
        progress: progress,
        showCharacter: showCharacter,
      ),
    };
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles({
    required this.views,
    required this.labels,
    required this.starts,
    required this.intervalMinutes,
  });
  final List<SegmentView> views;
  final List<String> labels;
  final List<DateTime> starts;
  final int? intervalMinutes;

  @override
  Widget build(BuildContext context) {
    if (starts.length == views.length && starts.isNotEmpty)
      return _byHour(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: views.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) => _ChunkTile(
        view: views[index],
        label: index < labels.length ? labels[index] : '',
      ),
    );
  }

  Widget _byHour(BuildContext context) {
    final groups = <DateTime, List<int>>{};
    for (var i = 0; i < starts.length; i++) {
      final start = starts[i];
      final key = DateTime(start.year, start.month, start.day, start.hour);
      groups.putIfAbsent(key, () => []).add(i);
    }
    final columns = _columns(intervalMinutes);
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    return LayoutBuilder(
      builder: (context, constraints) {
        const labelWidth = 44.0;
        const gap = 8.0;
        final tile =
            ((constraints.maxWidth - labelWidth - gap * columns) / columns)
                .clamp(44, 78)
                .toDouble();
        return Column(
          children: [
            for (final entry in groups.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: labelWidth,
                      child: Text(
                        ja
                            ? '${entry.key.hour}時'
                            : entry.key.hour.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    for (final index in entry.value)
                      Padding(
                        padding: const EdgeInsets.only(right: gap),
                        child: SizedBox(
                          width: tile,
                          height: tile,
                          child: _ChunkTile(
                            view: views[index],
                            label:
                                ':${starts[index].minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  int _columns(int? minutes) {
    if (minutes != null && minutes > 0 && minutes <= 60 && 60 % minutes == 0) {
      return (60 ~/ minutes).clamp(1, 6);
    }
    return 4;
  }
}

class _ChunkTile extends StatelessWidget {
  const _ChunkTile({required this.view, required this.label});
  final SegmentView view;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = view.done
        ? TickColors.mint
        : view.current
        ? TickColors.yellow
        : TickColors.line;
    final ink = view.done ? Colors.white : TickColors.ink;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          if (view.current)
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: view.fraction.clamp(0.08, 1),
                widthFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (view.done) Icon(Icons.check_rounded, color: ink, size: 14),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: view.current
                        ? FontWeight.w800
                        : FontWeight.w700,
                    fontSize: 12,
                    color: ink,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HourProgress extends StatelessWidget {
  const HourProgress({
    super.key,
    required this.views,
    required this.starts,
    this.breaks = const [],
    this.onlyCurrent = false,
  });

  final List<SegmentView> views;
  final List<DateTime> starts;
  final List<bool> breaks;
  final bool onlyCurrent;

  @override
  Widget build(BuildContext context) {
    if (starts.length != views.length || starts.isEmpty)
      return const SizedBox.shrink();
    final groups = <DateTime, List<int>>{};
    for (var i = 0; i < starts.length; i++) {
      final start = starts[i];
      final key = DateTime(start.year, start.month, start.day, start.hour);
      groups.putIfAbsent(key, () => []).add(i);
    }
    final keys = groups.keys.toList();
    final currentAt = keys.indexWhere(
      (key) => groups[key]!.any((index) => views[index].current),
    );
    final focus = currentAt >= 0 ? currentAt : keys.length - 1;
    final ordered = onlyCurrent
        ? [keys[focus]]
        : currentAt < 0
        ? keys
        : [...keys.sublist(currentAt), ...keys.sublist(0, currentAt)];
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    return Column(
      children: [
        for (final key in ordered)
          _HourTrack(
            label: ja ? '${key.hour}時' : key.hour.toString().padLeft(2, '0'),
            views: views,
            starts: starts,
            breaks: breaks,
            indexes: groups[key]!,
          ),
      ],
    );
  }
}

class _HourTrack extends StatelessWidget {
  const _HourTrack({
    required this.label,
    required this.views,
    required this.starts,
    required this.breaks,
    required this.indexes,
  });

  final String label;
  final List<SegmentView> views;
  final List<DateTime> starts;
  final List<bool> breaks;
  final List<int> indexes;

  bool _breakAt(int index) => index < breaks.length && breaks[index];

  double _head(double width) {
    const gap = 3.0;
    final gaps = gap * (indexes.length - 1);
    final slice = indexes.isEmpty ? 0.0 : (width - gaps) / indexes.length;
    var cursor = 0.0;
    for (final index in indexes) {
      final view = views[index];
      if (view.current) return cursor + slice * view.fraction.clamp(0.0, 1.0);
      if (!view.done) return cursor;
      cursor += slice + gap;
    }
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final live = indexes.any((index) => views[index].current);
    final finished = indexes.every((index) => views[index].done);
    final liveBreak = indexes.any(
      (index) => views[index].current && _breakAt(index),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 42,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                label,
                style: TextStyle(
                  color: live
                      ? Colors.white
                      : finished
                      ? Colors.white38
                      : Colors.white60,
                  fontWeight: FontWeight.w800,
                  fontSize: live ? 15 : 13,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final head = _head(constraints.maxWidth);
                    return SizedBox(
                      height: live ? 58 : 14,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _track(),
                          ),
                          if (live)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                              left: (head - 22).clamp(
                                0.0,
                                constraints.maxWidth - 44,
                              ),
                              bottom: 6,
                              child: LivingMascot(
                                pose: liveBreak
                                    ? ChickPose.sleep
                                    : ChickPose.back,
                                size: 44,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    for (final index in indexes)
                      Expanded(child: _minute(index)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _track() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            for (var n = 0; n < indexes.length; n++) ...[
              if (n > 0) const SizedBox(width: 3),
              Expanded(child: _slice(indexes[n])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _slice(int index) {
    final view = views[index];
    final onBreak = _breakAt(index);
    final groove = onBreak ? const Color(0xFF1A2C3C) : const Color(0xFF1A2436);
    if (view.done) {
      return ColoredBox(
        color: onBreak ? const Color(0xFF24384A) : const Color(0xFF24342F),
      );
    }
    if (!view.current) return ColoredBox(color: groove);
    final ink = onBreak ? TickColors.sky : TickColors.yellow;
    return ColoredBox(
      color: groove,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: view.fraction.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, value, _) {
          return Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.06, 1.0),
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ink,
                  boxShadow: [
                    BoxShadow(color: ink.withValues(alpha: 0.8), blurRadius: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _minute(int index) {
    final view = views[index];
    final onBreak = _breakAt(index);
    final ink = view.current
        ? (onBreak ? TickColors.sky : TickColors.yellow)
        : view.done
        ? Colors.white38
        : Colors.white54;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (view.done && !onBreak) ...[
            Icon(Icons.check_rounded, size: 11, color: ink),
            const SizedBox(width: 1),
          ],
          if (onBreak) ...[
            Icon(Icons.coffee_rounded, size: 11, color: ink),
            const SizedBox(width: 1),
          ],
          Text(
            ':${starts[index].minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: ink,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _Map extends StatelessWidget {
  const _Map({required this.views});
  final List<SegmentView> views;

  @override
  Widget build(BuildContext context) {
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
                      color: views[i].done
                          ? TickColors.mint
                          : views[i].current
                          ? TickColors.yellow
                          : TickColors.line,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: views[i].done
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          )
                        : Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: TickColors.ink,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Character extends StatelessWidget {
  const _Character({
    required this.views,
    required this.progress,
    required this.showFace,
  });
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
                view.done
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: view.done ? TickColors.yellow : TickColors.line,
                size: view.current ? 22 : 16,
              ),
          ],
        ),
      ],
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.views,
    required this.progress,
    required this.showCharacter,
  });
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
          child: showCharacter
              ? TickMascot(progress: progress, size: 96)
              : Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
      ..color = TickColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = TickColors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = math.pi * 0.8;
    const sweep = math.pi * 1.4;
    canvas.drawArc(rect, start, sweep, false, base);
    canvas.drawArc(rect, start, sweep * progress.clamp(0, 1), false, arc);
    final tickPaint = Paint()
      ..color = TickColors.muted
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
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.ticks != ticks;
}
