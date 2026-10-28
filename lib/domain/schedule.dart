import 'format.dart';

class ClockTime {
  const ClockTime(this.hour, this.minute);

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  String get label => formatClock(hour, minute);

  Map<String, dynamic> toJson() => {'h': hour, 'm': minute};

  factory ClockTime.fromJson(Map<String, dynamic> json) {
    return ClockTime((json['h'] as num?)?.toInt() ?? 9, (json['m'] as num?)?.toInt() ?? 0);
  }

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

class BreakTemplate {
  const BreakTemplate({required this.id, required this.start, required this.end});

  final String id;
  final ClockTime start;
  final ClockTime end;

  Map<String, dynamic> toJson() => {'id': id, 'start': start.toJson(), 'end': end.toJson()};

  factory BreakTemplate.fromJson(Map<String, dynamic> json) {
    return BreakTemplate(
      id: json['id'] as String? ?? 'break',
      start: ClockTime.fromJson((json['start'] as Map?)?.cast<String, dynamic>() ?? const {}),
      end: ClockTime.fromJson((json['end'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }
}

class WorkPattern {
  const WorkPattern({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.breaks,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final ClockTime start;
  final ClockTime end;
  final List<BreakTemplate> breaks;
  final DateTime updatedAt;

  bool get crossesMidnight => end.minutesOfDay <= start.minutesOfDay;

  WorkPattern copyWith({
    String? name,
    ClockTime? start,
    ClockTime? end,
    List<BreakTemplate>? breaks,
    DateTime? updatedAt,
  }) {
    return WorkPattern(
      id: id,
      name: name ?? this.name,
      start: start ?? this.start,
      end: end ?? this.end,
      breaks: breaks ?? this.breaks,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'start': start.toJson(),
    'end': end.toJson(),
    'breaks': breaks.map((item) => item.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory WorkPattern.fromJson(Map<String, dynamic> json) {
    final rawBreaks = json['breaks'] as List? ?? const [];
    return WorkPattern(
      id: json['id'] as String? ?? 'pattern',
      name: json['name'] as String? ?? '',
      start: ClockTime.fromJson((json['start'] as Map?)?.cast<String, dynamic>() ?? const {}),
      end: ClockTime.fromJson((json['end'] as Map?)?.cast<String, dynamic>() ?? const {}),
      breaks: [
        for (final item in rawBreaks)
          if (item is Map) BreakTemplate.fromJson(item.cast<String, dynamic>()),
      ],
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    );
  }
}

class DateOverride {
  const DateOverride({
    required this.id,
    required this.date,
    required this.holiday,
    required this.name,
    required this.start,
    required this.end,
    required this.breaks,
    required this.updatedAt,
  });

  final String id;
  final DateTime date;
  final bool holiday;
  final String name;
  final ClockTime? start;
  final ClockTime? end;
  final List<BreakTemplate> breaks;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': dateKey(date),
    'holiday': holiday,
    'name': name,
    'start': start?.toJson(),
    'end': end?.toJson(),
    'breaks': breaks.map((item) => item.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory DateOverride.fromJson(Map<String, dynamic> json) {
    final rawBreaks = json['breaks'] as List? ?? const [];
    final rawDate = json['date'] as String? ?? '1970-01-01';
    final parts = rawDate.split('-');
    final date = parts.length == 3
        ? DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]))
        : dateOnly(DateTime.now());
    return DateOverride(
      id: json['id'] as String? ?? rawDate,
      date: date,
      holiday: json['holiday'] as bool? ?? false,
      name: json['name'] as String? ?? '',
      start: json['start'] is Map
          ? ClockTime.fromJson((json['start'] as Map).cast<String, dynamic>())
          : null,
      end: json['end'] is Map
          ? ClockTime.fromJson((json['end'] as Map).cast<String, dynamic>())
          : null,
      breaks: [
        for (final item in rawBreaks)
          if (item is Map) BreakTemplate.fromJson(item.cast<String, dynamic>()),
      ],
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    );
  }
}

class WeekPlan {
  const WeekPlan({required this.days, required this.updatedAt});

  final Map<int, String?> days;
  final DateTime updatedAt;

  String? operator [](int weekday) => days[weekday];

  WeekPlan copyWith({Map<int, String?>? days, DateTime? updatedAt}) {
    return WeekPlan(days: days ?? this.days, updatedAt: updatedAt ?? this.updatedAt);
  }

  Map<String, dynamic> toJson() => {
    'days': {for (final entry in days.entries) '${entry.key}': entry.value},
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory WeekPlan.fromJson(Map<String, dynamic> json) {
    final raw = json['days'] as Map? ?? const {};
    final days = <int, String?>{};
    for (final entry in raw.entries) {
      final key = int.tryParse(entry.key.toString());
      if (key == null) continue;
      days[key] = entry.value as String?;
    }
    return WeekPlan(
      days: days,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    );
  }
}

class TimeRange {
  const TimeRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);
}

class ResolvedShift {
  const ResolvedShift({
    required this.workDate,
    required this.start,
    required this.end,
    required this.breaks,
    required this.patternId,
    required this.label,
  });

  final DateTime workDate;
  final DateTime start;
  final DateTime end;
  final List<TimeRange> breaks;
  final String? patternId;
  final String label;

  String get key => '${dateKey(workDate)}|${patternId ?? label}|${start.toIso8601String()}';
}

class ScheduleCalendar {
  const ScheduleCalendar({
    required this.patterns,
    required this.week,
    required this.overrides,
  });

  final List<WorkPattern> patterns;
  final WeekPlan week;
  final List<DateOverride> overrides;

  WorkPattern? patternById(String? id) {
    if (id == null) return null;
    for (final pattern in patterns) {
      if (pattern.id == id) return pattern;
    }
    return null;
  }

  ResolvedShift? shiftStartingOn(DateTime day) {
    final date = dateOnly(day);
    DateOverride? override;
    for (final item in overrides) {
      if (dateKey(item.date) == dateKey(date)) {
        override = item;
        break;
      }
    }
    if (override != null) {
      if (override.holiday || override.start == null || override.end == null) {
        return null;
      }
      return _resolve(
        date: date,
        start: override.start!,
        end: override.end!,
        breaks: override.breaks,
        patternId: null,
        label: override.name,
      );
    }
    final pattern = patternById(week[date.weekday]);
    if (pattern == null) return null;
    return _resolve(
      date: date,
      start: pattern.start,
      end: pattern.end,
      breaks: pattern.breaks,
      patternId: pattern.id,
      label: pattern.name,
    );
  }

  ResolvedShift? shiftCovering(DateTime now) {
    final today = dateOnly(now);
    for (final day in [today.subtract(const Duration(days: 1)), today]) {
      final shift = shiftStartingOn(day);
      if (shift == null) continue;
      if (!now.isBefore(shift.start) && now.isBefore(shift.end)) return shift;
    }
    return null;
  }

  ResolvedShift? upcomingOn(DateTime now) {
    final shift = shiftStartingOn(now);
    if (shift == null) return null;
    if (now.isBefore(shift.start)) return shift;
    return null;
  }
}

ResolvedShift _resolve({
  required DateTime date,
  required ClockTime start,
  required ClockTime end,
  required List<BreakTemplate> breaks,
  required String? patternId,
  required String label,
}) {
  final shiftStart = DateTime(date.year, date.month, date.day, start.hour, start.minute);
  var shiftEnd = DateTime(date.year, date.month, date.day, end.hour, end.minute);
  if (!shiftEnd.isAfter(shiftStart)) {
    shiftEnd = shiftEnd.add(const Duration(days: 1));
  }
  final ranges = <TimeRange>[];
  for (final item in breaks) {
    final rangeStart = _onShift(shiftStart, item.start);
    var rangeEnd = _onShift(shiftStart, item.end);
    if (!rangeEnd.isAfter(rangeStart)) {
      rangeEnd = rangeEnd.add(const Duration(days: 1));
    }
    final inside =
        !rangeStart.isBefore(shiftStart) &&
        !rangeEnd.isAfter(shiftEnd) &&
        rangeEnd.isAfter(rangeStart);
    if (inside) {
      ranges.add(TimeRange(start: rangeStart, end: rangeEnd));
    }
  }
  return ResolvedShift(
    workDate: date,
    start: shiftStart,
    end: shiftEnd,
    breaks: ranges,
    patternId: patternId,
    label: label,
  );
}

DateTime _onShift(DateTime shiftStart, ClockTime clock) {
  var value = DateTime(shiftStart.year, shiftStart.month, shiftStart.day, clock.hour, clock.minute);
  if (value.isBefore(shiftStart)) {
    value = value.add(const Duration(days: 1));
  }
  return value;
}
