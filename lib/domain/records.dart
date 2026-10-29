import 'format.dart';

enum EndStatus { completed, early }

enum EndAction { celebration, home, history }

enum TimerVisual { tiles, map, character, gauge }

enum CamouflageTrigger { corner, longPress, swipe }

enum CamouflageLook { home, notes, calendar }

enum ChickVoice { plain, lazy, kansai, custom }

enum CallSound { classic, soft, bright }

enum ChickMood { heavy, tired, sleepy }

CamouflageLook shownLook(bool premium, CamouflageLook look) {
  if (premium || look == CamouflageLook.home) return look;
  return CamouflageLook.home;
}

ChickVoice shownVoice(bool premium, ChickVoice voice) {
  if (premium) return voice;
  return ChickVoice.plain;
}

CallSound shownSound(bool premium, CallSound sound) {
  if (premium) return sound;
  return CallSound.classic;
}

class BreakSpan {
  const BreakSpan({
    required this.id,
    required this.start,
    required this.end,
    required this.updatedAt,
  });

  final String id;
  final DateTime start;
  final DateTime end;
  final DateTime updatedAt;

  Duration get duration => end.difference(start);

  BreakSpan copyWith({DateTime? start, DateTime? end, DateTime? updatedAt}) {
    return BreakSpan(
      id: id,
      start: start ?? this.start,
      end: end ?? this.end,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory BreakSpan.fromJson(Map<String, dynamic> json) {
    final start = parseDate(json['start'] as String);
    final end = parseDate(json['end'] as String);
    return BreakSpan(
      id: json['id'] as String? ?? 'break',
      start: start,
      end: end,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ??
          end,
    );
  }
}

class ExtensionRecord {
  const ExtensionRecord({
    required this.at,
    required this.previousEnd,
    required this.newEnd,
    required this.minutes,
  });

  final DateTime at;
  final DateTime previousEnd;
  final DateTime newEnd;
  final int minutes;

  Map<String, dynamic> toJson() => {
    'at': at.toIso8601String(),
    'previousEnd': previousEnd.toIso8601String(),
    'newEnd': newEnd.toIso8601String(),
    'minutes': minutes,
  };

  factory ExtensionRecord.fromJson(Map<String, dynamic> json) {
    return ExtensionRecord(
      at: parseDate(json['at'] as String),
      previousEnd: parseDate(json['previousEnd'] as String),
      newEnd: parseDate(json['newEnd'] as String),
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
    );
  }
}

class TimerSession {
  const TimerSession({
    required this.id,
    required this.workDate,
    required this.actualStart,
    required this.plannedEnd,
    required this.originalPlannedEnd,
    required this.intervalMinutes,
    required this.breaks,
    required this.extensions,
    required this.patternId,
    required this.shiftKey,
    required this.memo,
    required this.celebratedCount,
    required this.updatedAt,
  });

  final String id;
  final DateTime workDate;
  final DateTime actualStart;
  final DateTime plannedEnd;
  final DateTime originalPlannedEnd;
  final int intervalMinutes;
  final List<BreakSpan> breaks;
  final List<ExtensionRecord> extensions;
  final String? patternId;
  final String? shiftKey;
  final String memo;
  final int celebratedCount;
  final DateTime updatedAt;

  TimerSession copyWith({
    DateTime? plannedEnd,
    int? intervalMinutes,
    List<BreakSpan>? breaks,
    List<ExtensionRecord>? extensions,
    String? memo,
    int? celebratedCount,
    DateTime? updatedAt,
  }) {
    return TimerSession(
      id: id,
      workDate: workDate,
      actualStart: actualStart,
      plannedEnd: plannedEnd ?? this.plannedEnd,
      originalPlannedEnd: originalPlannedEnd,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      breaks: breaks ?? this.breaks,
      extensions: extensions ?? this.extensions,
      patternId: patternId,
      shiftKey: shiftKey,
      memo: memo ?? this.memo,
      celebratedCount: celebratedCount ?? this.celebratedCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'workDate': dateKey(workDate),
    'actualStart': actualStart.toIso8601String(),
    'plannedEnd': plannedEnd.toIso8601String(),
    'originalPlannedEnd': originalPlannedEnd.toIso8601String(),
    'intervalMinutes': intervalMinutes,
    'breaks': breaks.map((item) => item.toJson()).toList(),
    'extensions': extensions.map((item) => item.toJson()).toList(),
    'patternId': patternId,
    'shiftKey': shiftKey,
    'memo': memo,
    'celebratedCount': celebratedCount,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TimerSession.fromJson(Map<String, dynamic> json) {
    return TimerSession(
      id: json['id'] as String? ?? 'session',
      workDate: _date(json['workDate'] as String?),
      actualStart: parseDate(json['actualStart'] as String),
      plannedEnd: parseDate(json['plannedEnd'] as String),
      originalPlannedEnd: parseDate(json['originalPlannedEnd'] as String),
      intervalMinutes: (json['intervalMinutes'] as num?)?.toInt() ?? 15,
      breaks: _spans(json['breaks']),
      extensions: [
        for (final item in json['extensions'] as List? ?? const [])
          if (item is Map)
            ExtensionRecord.fromJson(item.cast<String, dynamic>()),
      ],
      patternId: json['patternId'] as String?,
      shiftKey: json['shiftKey'] as String?,
      memo: json['memo'] as String? ?? '',
      celebratedCount: (json['celebratedCount'] as num?)?.toInt() ?? 0,
      updatedAt: parseDate(json['updatedAt'] as String),
    );
  }
}

class WorkRecord {
  const WorkRecord({
    required this.id,
    required this.workDate,
    required this.actualStart,
    required this.actualEnd,
    required this.originalPlannedEnd,
    required this.intervalMinutes,
    required this.breaks,
    required this.segmentsCompleted,
    required this.segmentsTotal,
    required this.extensions,
    required this.status,
    required this.memo,
    required this.patternId,
    required this.shiftKey,
    required this.updatedAt,
  });

  final String id;
  final DateTime workDate;
  final DateTime actualStart;
  final DateTime actualEnd;
  final DateTime originalPlannedEnd;
  final int intervalMinutes;
  final List<BreakSpan> breaks;
  final int segmentsCompleted;
  final int segmentsTotal;
  final List<ExtensionRecord> extensions;
  final EndStatus status;
  final String memo;
  final String? patternId;
  final String? shiftKey;
  final DateTime updatedAt;

  double get achievementRate =>
      segmentsTotal == 0 ? 0 : segmentsCompleted / segmentsTotal;

  WorkRecord copyWith({
    List<BreakSpan>? breaks,
    String? memo,
    DateTime? updatedAt,
  }) {
    return WorkRecord(
      id: id,
      workDate: workDate,
      actualStart: actualStart,
      actualEnd: actualEnd,
      originalPlannedEnd: originalPlannedEnd,
      intervalMinutes: intervalMinutes,
      breaks: breaks ?? this.breaks,
      segmentsCompleted: segmentsCompleted,
      segmentsTotal: segmentsTotal,
      extensions: extensions,
      status: status,
      memo: memo ?? this.memo,
      patternId: patternId,
      shiftKey: shiftKey,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'workDate': dateKey(workDate),
    'actualStart': actualStart.toIso8601String(),
    'actualEnd': actualEnd.toIso8601String(),
    'originalPlannedEnd': originalPlannedEnd.toIso8601String(),
    'intervalMinutes': intervalMinutes,
    'breaks': breaks.map((item) => item.toJson()).toList(),
    'segmentsCompleted': segmentsCompleted,
    'segmentsTotal': segmentsTotal,
    'extensions': extensions.map((item) => item.toJson()).toList(),
    'status': status.name,
    'memo': memo,
    'patternId': patternId,
    'shiftKey': shiftKey,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory WorkRecord.fromJson(Map<String, dynamic> json) {
    return WorkRecord(
      id: json['id'] as String? ?? 'record',
      workDate: _date(json['workDate'] as String?),
      actualStart: parseDate(json['actualStart'] as String),
      actualEnd: parseDate(json['actualEnd'] as String),
      originalPlannedEnd: parseDate(json['originalPlannedEnd'] as String),
      intervalMinutes: (json['intervalMinutes'] as num?)?.toInt() ?? 15,
      breaks: _spans(json['breaks']),
      segmentsCompleted: (json['segmentsCompleted'] as num?)?.toInt() ?? 0,
      segmentsTotal: (json['segmentsTotal'] as num?)?.toInt() ?? 0,
      extensions: [
        for (final item in json['extensions'] as List? ?? const [])
          if (item is Map)
            ExtensionRecord.fromJson(item.cast<String, dynamic>()),
      ],
      status: (json['status'] as String?) == EndStatus.early.name
          ? EndStatus.early
          : EndStatus.completed,
      memo: json['memo'] as String? ?? '',
      patternId: json['patternId'] as String?,
      shiftKey: json['shiftKey'] as String?,
      updatedAt: parseDate(json['updatedAt'] as String),
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.notifySegment,
    required this.notifyEnd,
    required this.notifySound,
    required this.notifyVibration,
    required this.endAction,
    required this.visual,
    required this.showCharacter,
    required this.autoStart,
    required this.camouflageTrigger,
    required this.camouflageLook,
    required this.chickVoice,
    required this.customChickLine,
    required this.callSound,
    required this.lastIntervalMinutes,
    required this.tutorialSeen,
    required this.slackIntroSeen,
    required this.updatedAt,
  });

  final bool notifySegment;
  final bool notifyEnd;
  final bool notifySound;
  final bool notifyVibration;
  final EndAction endAction;
  final TimerVisual visual;
  final bool showCharacter;
  final bool autoStart;
  final CamouflageTrigger camouflageTrigger;
  final CamouflageLook camouflageLook;
  final ChickVoice chickVoice;
  final String customChickLine;
  final CallSound callSound;
  final int lastIntervalMinutes;
  final bool tutorialSeen;
  final bool slackIntroSeen;
  final DateTime updatedAt;

  factory AppSettings.initial(DateTime now) {
    return AppSettings(
      notifySegment: true,
      notifyEnd: true,
      notifySound: true,
      notifyVibration: true,
      endAction: EndAction.celebration,
      visual: TimerVisual.gauge,
      showCharacter: true,
      autoStart: true,
      camouflageTrigger: CamouflageTrigger.corner,
      camouflageLook: CamouflageLook.home,
      chickVoice: ChickVoice.plain,
      customChickLine: '',
      callSound: CallSound.classic,
      lastIntervalMinutes: 15,
      tutorialSeen: false,
      slackIntroSeen: false,
      updatedAt: now,
    );
  }

  AppSettings copyWith({
    bool? notifySegment,
    bool? notifyEnd,
    bool? notifySound,
    bool? notifyVibration,
    EndAction? endAction,
    TimerVisual? visual,
    bool? showCharacter,
    bool? autoStart,
    CamouflageTrigger? camouflageTrigger,
    CamouflageLook? camouflageLook,
    ChickVoice? chickVoice,
    String? customChickLine,
    CallSound? callSound,
    int? lastIntervalMinutes,
    bool? tutorialSeen,
    bool? slackIntroSeen,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      notifySegment: notifySegment ?? this.notifySegment,
      notifyEnd: notifyEnd ?? this.notifyEnd,
      notifySound: notifySound ?? this.notifySound,
      notifyVibration: notifyVibration ?? this.notifyVibration,
      endAction: endAction ?? this.endAction,
      visual: visual ?? this.visual,
      showCharacter: showCharacter ?? this.showCharacter,
      autoStart: autoStart ?? this.autoStart,
      camouflageTrigger: camouflageTrigger ?? this.camouflageTrigger,
      camouflageLook: camouflageLook ?? this.camouflageLook,
      chickVoice: chickVoice ?? this.chickVoice,
      customChickLine: customChickLine ?? this.customChickLine,
      callSound: callSound ?? this.callSound,
      lastIntervalMinutes: lastIntervalMinutes ?? this.lastIntervalMinutes,
      tutorialSeen: tutorialSeen ?? this.tutorialSeen,
      slackIntroSeen: slackIntroSeen ?? this.slackIntroSeen,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'notifySegment': notifySegment,
    'notifyEnd': notifyEnd,
    'notifySound': notifySound,
    'notifyVibration': notifyVibration,
    'endAction': endAction.name,
    'visual': visual.name,
    'showCharacter': showCharacter,
    'autoStart': autoStart,
    'camouflageTrigger': camouflageTrigger.name,
    'camouflageLook': camouflageLook.name,
    'chickVoice': chickVoice.name,
    'customChickLine': customChickLine,
    'callSound': callSound.name,
    'lastIntervalMinutes': lastIntervalMinutes,
    'tutorialSeen': tutorialSeen,
    'slackIntroSeen': slackIntroSeen,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final initial = AppSettings.initial(
      DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
    return initial.copyWith(
      notifySegment: json['notifySegment'] as bool? ?? initial.notifySegment,
      notifyEnd: json['notifyEnd'] as bool? ?? initial.notifyEnd,
      notifySound: json['notifySound'] as bool? ?? initial.notifySound,
      notifyVibration:
          json['notifyVibration'] as bool? ?? initial.notifyVibration,
      endAction: EndAction.values.byNameOr(
        json['endAction'] as String?,
        initial.endAction,
      ),
      visual: TimerVisual.values.byNameOr(
        json['visual'] as String?,
        initial.visual,
      ),
      showCharacter: json['showCharacter'] as bool? ?? initial.showCharacter,
      autoStart: json['autoStart'] as bool? ?? initial.autoStart,
      camouflageTrigger: CamouflageTrigger.values.byNameOr(
        json['camouflageTrigger'] as String?,
        initial.camouflageTrigger,
      ),
      camouflageLook: CamouflageLook.values.byNameOr(
        json['camouflageLook'] as String?,
        initial.camouflageLook,
      ),
      chickVoice: ChickVoice.values.byNameOr(
        json['chickVoice'] as String?,
        initial.chickVoice,
      ),
      customChickLine: json['customChickLine'] as String? ?? '',
      callSound: CallSound.values.byNameOr(
        json['callSound'] as String?,
        initial.callSound,
      ),
      lastIntervalMinutes: (json['lastIntervalMinutes'] as num?)?.toInt() ?? 15,
      tutorialSeen: json['tutorialSeen'] as bool? ?? false,
      slackIntroSeen: json['slackIntroSeen'] as bool? ?? false,
      updatedAt: initial.updatedAt,
    );
  }
}

class Entitlement {
  const Entitlement({
    required this.premium,
    required this.updatedAt,
    required this.source,
  });

  final bool premium;
  final DateTime updatedAt;
  final String source;

  factory Entitlement.free() {
    return Entitlement(
      premium: false,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      source: 'none',
    );
  }

  Map<String, dynamic> toJson() => {
    'premium': premium,
    'updatedAt': updatedAt.toIso8601String(),
    'source': source,
  };

  factory Entitlement.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Entitlement.free();
    return Entitlement(
      premium: json['premium'] as bool? ?? false,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      source: json['source'] as String? ?? 'none',
    );
  }
}

class Caller {
  const Caller({
    required this.id,
    required this.name,
    required this.emoji,
    required this.presetKey,
    required this.photoPath,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String emoji;
  final String? presetKey;
  final String? photoPath;
  final DateTime updatedAt;

  bool get custom => presetKey == null;

  Caller copyWith({
    String? name,
    String? emoji,
    String? photoPath,
    bool clearPhoto = false,
    DateTime? updatedAt,
  }) {
    return Caller(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      presetKey: presetKey,
      photoPath: clearPhoto ? null : photoPath ?? this.photoPath,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'presetKey': presetKey,
    'photoPath': photoPath,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Caller.fromJson(Map<String, dynamic> json) {
    return Caller(
      id: json['id'] as String? ?? 'caller',
      name: json['name'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '📞',
      presetKey: json['presetKey'] as String?,
      photoPath: json['photoPath'] as String?,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ScheduledFakeCall {
  const ScheduledFakeCall({
    required this.id,
    required this.callerId,
    required this.fireAt,
    required this.fired,
    required this.updatedAt,
  });

  final String id;
  final String callerId;
  final DateTime fireAt;
  final bool fired;
  final DateTime updatedAt;

  ScheduledFakeCall copyWith({bool? fired, DateTime? updatedAt}) {
    return ScheduledFakeCall(
      id: id,
      callerId: callerId,
      fireAt: fireAt,
      fired: fired ?? this.fired,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'callerId': callerId,
    'fireAt': fireAt.toIso8601String(),
    'fired': fired,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ScheduledFakeCall.fromJson(Map<String, dynamic> json) {
    return ScheduledFakeCall(
      id: json['id'] as String? ?? 'call',
      callerId: json['callerId'] as String? ?? '',
      fireAt: parseDate(json['fireAt'] as String),
      fired: json['fired'] as bool? ?? false,
      updatedAt: parseDate(json['updatedAt'] as String),
    );
  }
}

class Tombstone {
  const Tombstone({
    required this.collection,
    required this.id,
    required this.deletedAt,
  });

  final String collection;
  final String id;
  final DateTime deletedAt;

  String get key => '$collection::$id';

  Map<String, dynamic> toJson() => {
    'collection': collection,
    'id': id,
    'deletedAt': deletedAt.toIso8601String(),
  };

  factory Tombstone.fromJson(Map<String, dynamic> json) {
    return Tombstone(
      collection: json['collection'] as String? ?? '',
      id: json['id'] as String? ?? '',
      deletedAt: parseDate(json['deletedAt'] as String),
    );
  }
}

class LiveCall {
  const LiveCall({
    required this.caller,
    required this.startedAt,
    required this.answered,
    required this.answeredAt,
    required this.muted,
  });

  final Caller caller;
  final DateTime startedAt;
  final bool answered;
  final DateTime? answeredAt;
  final bool muted;

  LiveCall copyWith({bool? answered, DateTime? answeredAt, bool? muted}) {
    return LiveCall(
      caller: caller,
      startedAt: startedAt,
      answered: answered ?? this.answered,
      answeredAt: answeredAt ?? this.answeredAt,
      muted: muted ?? this.muted,
    );
  }
}

Duration overtimeOf(WorkRecord record) {
  final delta = record.actualEnd.difference(record.originalPlannedEnd);
  return delta.isNegative ? Duration.zero : delta;
}

Duration earlyLeaveOf(WorkRecord record) {
  final delta = record.originalPlannedEnd.difference(record.actualEnd);
  return delta.isNegative ? Duration.zero : delta;
}

Duration breakTotal(List<BreakSpan> breaks) {
  return breaks.fold(Duration.zero, (total, item) => total + item.duration);
}

int extensionMinutes(List<ExtensionRecord> extensions) {
  return extensions.fold(0, (total, item) => total + item.minutes);
}

DateTime plannedEndOf(WorkRecord record) {
  if (record.extensions.isEmpty) return record.originalPlannedEnd;
  return record.extensions.last.newEnd;
}

DateTime _date(String? raw) {
  if (raw == null || raw.length < 10) return dateOnly(DateTime.now());
  final parts = raw.substring(0, 10).split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

List<BreakSpan> _spans(Object? raw) {
  final list = raw as List? ?? const [];
  return [
    for (final item in list)
      if (item is Map) BreakSpan.fromJson(item.cast<String, dynamic>()),
  ];
}

extension EnumByName<T extends Enum> on List<T> {
  T byNameOr(String? name, T fallback) {
    if (name == null) return fallback;
    for (final value in this) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
