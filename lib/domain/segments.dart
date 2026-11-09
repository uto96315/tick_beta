class Segment {
  const Segment({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  Duration get length => end.difference(start);
}

class SegmentProgress {
  const SegmentProgress({
    required this.total,
    required this.completed,
    required this.currentIndex,
    required this.currentFraction,
    required this.remaining,
  });

  final int total;
  final int completed;
  final int? currentIndex;
  final double currentFraction;
  final Duration remaining;

  int get remainingCount => (total - completed).clamp(0, total);

  double get rate => total == 0 ? 0 : completed / total;
}

class SegmentView {
  const SegmentView({
    required this.done,
    required this.current,
    required this.fraction,
  });

  final bool done;
  final bool current;
  final double fraction;
}

/// Splits [start]..[end] into chunks of [intervalMinutes].
/// The last chunk is shortened so the segments cover the range exactly.
List<Segment> buildSegments({
  required DateTime start,
  required DateTime end,
  required int intervalMinutes,
}) {
  if (!end.isAfter(start)) {
    return [Segment(start: start, end: end.isBefore(start) ? start : end)];
  }
  final minutes = intervalMinutes < 1 ? 1 : intervalMinutes;
  final interval = Duration(minutes: minutes);
  final segments = <Segment>[];
  var cursor = start;
  while (cursor.isBefore(end)) {
    var next = cursor.add(interval);
    if (next.isAfter(end)) next = end;
    if (!next.isAfter(cursor)) break;
    segments.add(Segment(start: cursor, end: next));
    cursor = next;
  }
  return segments;
}

SegmentProgress evaluateSegments({
  required List<Segment> segments,
  required DateTime now,
  required DateTime sessionEnd,
}) {
  var completed = 0;
  int? current;
  var fraction = 0.0;
  for (var i = 0; i < segments.length; i++) {
    final segment = segments[i];
    if (!now.isBefore(segment.end)) {
      completed++;
      continue;
    }
    current ??= i;
    if (current == i) {
      final length = segment.end.difference(segment.start).inMilliseconds;
      if (length <= 0) {
        fraction = 1;
      } else {
        final elapsed = now.difference(segment.start).inMilliseconds;
        fraction = (elapsed / length).clamp(0, 1).toDouble();
      }
    }
  }
  final remaining = sessionEnd.difference(now);
  return SegmentProgress(
    total: segments.length,
    completed: completed,
    currentIndex: current,
    currentFraction: fraction,
    remaining: remaining.isNegative ? Duration.zero : remaining,
  );
}

/// Groups segment indexes by [Segment.start] hour (preserving order).
List<List<int>> segmentIndexesByHour(List<Segment> segments) {
  if (segments.isEmpty) return [];
  final groups = <List<int>>[];
  var hour = -1;
  var bucket = <int>[];
  for (var i = 0; i < segments.length; i++) {
    final h = segments[i].start.hour;
    if (bucket.isEmpty || h == hour) {
      hour = h;
      bucket.add(i);
    } else {
      groups.add(bucket);
      bucket = [i];
      hour = h;
    }
  }
  if (bucket.isNotEmpty) groups.add(bucket);
  return groups;
}

/// Segment indexes for the same clock hour as [now], or the current segment's hour.
List<int> hourSegmentIndexes(
  List<Segment> segments,
  DateTime now,
  int? currentIndex,
) {
  bool sameClockHour(Segment segment) {
    return segment.start.year == now.year &&
        segment.start.month == now.month &&
        segment.start.day == now.day &&
        segment.start.hour == now.hour;
  }

  final inHour = <int>[
    for (var i = 0; i < segments.length; i++)
      if (sameClockHour(segments[i])) i,
  ];
  if (inHour.isNotEmpty) return inHour;
  if (currentIndex == null ||
      currentIndex < 0 ||
      currentIndex >= segments.length) {
    return inHour;
  }
  final anchor = segments[currentIndex].start;
  return [
    for (var i = 0; i < segments.length; i++)
      if (segments[i].start.year == anchor.year &&
          segments[i].start.month == anchor.month &&
          segments[i].start.day == anchor.day &&
          segments[i].start.hour == anchor.hour)
        i,
  ];
}

List<SegmentView> segmentViews(List<Segment> segments, SegmentProgress progress) {
  return [
    for (var i = 0; i < segments.length; i++)
      SegmentView(
        done: i < progress.completed,
        current: i == progress.currentIndex,
        fraction: i < progress.completed
            ? 1
            : i == progress.currentIndex
            ? progress.currentFraction
            : 0,
      ),
  ];
}
