import 'dart:convert';

import 'package:tick/domain/fake_call_policy.dart';
import 'package:tick/domain/format.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/domain/schedule.dart';

class PersistedState {
  PersistedState({
    required this.uid,
    required this.needsPull,
    required this.settings,
    required this.session,
    required this.sessionClearedAt,
    required this.runtimeUpdatedAt,
    required this.pendingFreedom,
    required this.freedomHistoryId,
    required this.dismissedShiftKey,
    required this.ringingCallerId,
    required this.history,
    required this.patterns,
    required this.week,
    required this.overrides,
    required this.callers,
    required this.scheduledCalls,
    required this.credits,
    required this.entitlement,
    required this.tombstones,
    this.dismissedUpdateBuild = 0,
  });

  String? uid;
  bool needsPull;
  AppSettings settings;
  TimerSession? session;
  DateTime? sessionClearedAt;
  DateTime runtimeUpdatedAt;
  bool pendingFreedom;
  String? freedomHistoryId;
  String? dismissedShiftKey;
  String? ringingCallerId;
  int dismissedUpdateBuild;
  List<WorkRecord> history;
  List<WorkPattern> patterns;
  WeekPlan week;
  List<DateOverride> overrides;
  List<Caller> callers;
  List<ScheduledFakeCall> scheduledCalls;
  List<CallCredit> credits;
  Entitlement entitlement;
  List<Tombstone> tombstones;

  factory PersistedState.seed({required String languageCode, String? uid, DateTime? now}) {
    final clock = now ?? DateTime.now();
    final ja = languageCode == 'ja';
    final pattern = WorkPattern(
      id: 'default',
      name: ja ? 'ふつうの一日' : 'Regular day',
      start: const ClockTime(9, 0),
      end: const ClockTime(18, 0),
      breaks: const [
        BreakTemplate(
          id: 'lunch',
          start: ClockTime(12, 0),
          end: ClockTime(13, 0),
        ),
      ],
      updatedAt: clock,
    );
    return PersistedState(
      uid: uid,
      needsPull: false,
      settings: AppSettings.initial(clock),
      session: null,
      sessionClearedAt: null,
      runtimeUpdatedAt: clock,
      pendingFreedom: false,
      freedomHistoryId: null,
      dismissedShiftKey: null,
      ringingCallerId: null,
      history: [],
      patterns: [pattern],
      week: WeekPlan(
        days: {1: pattern.id, 2: pattern.id, 3: pattern.id, 4: pattern.id, 5: pattern.id},
        updatedAt: clock,
      ),
      overrides: [],
      callers: [
        Caller(
          id: 'boss',
          name: ja ? '上司' : 'Boss',
          emoji: '🧑‍💼',
          presetKey: 'boss',
          photoPath: null,
          updatedAt: clock,
        ),
        Caller(
          id: 'family',
          name: ja ? '家族' : 'Family',
          emoji: '🏠',
          presetKey: 'family',
          photoPath: null,
          updatedAt: clock,
        ),
        Caller(
          id: 'client',
          name: ja ? '取引先' : 'Client',
          emoji: '💼',
          presetKey: 'client',
          photoPath: null,
          updatedAt: clock,
        ),
      ],
      scheduledCalls: [],
      credits: [],
      entitlement: Entitlement.free(),
      tombstones: [],
    );
  }

  factory PersistedState.blank({required String uid}) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return PersistedState(
      uid: uid,
      needsPull: true,
      settings: AppSettings.initial(epoch),
      session: null,
      sessionClearedAt: null,
      runtimeUpdatedAt: epoch,
      pendingFreedom: false,
      freedomHistoryId: null,
      dismissedShiftKey: null,
      ringingCallerId: null,
      history: [],
      patterns: [],
      week: WeekPlan(days: const {}, updatedAt: epoch),
      overrides: [],
      callers: [],
      scheduledCalls: [],
      credits: [],
      entitlement: Entitlement.free(),
      tombstones: [],
    );
  }

  bool get isBlank => patterns.isEmpty && history.isEmpty && callers.isEmpty && session == null;

  Map<String, dynamic> toJson() => {
    'schema': 1,
    'uid': uid,
    'needsPull': needsPull,
    'settings': settings.toJson(),
    'session': session?.toJson(),
    'sessionClearedAt': sessionClearedAt?.toIso8601String(),
    'runtimeUpdatedAt': runtimeUpdatedAt.toIso8601String(),
    'pendingFreedom': pendingFreedom,
    'freedomHistoryId': freedomHistoryId,
    'dismissedShiftKey': dismissedShiftKey,
    'ringingCallerId': ringingCallerId,
    'dismissedUpdateBuild': dismissedUpdateBuild,
    'history': history.map((item) => item.toJson()).toList(),
    'patterns': patterns.map((item) => item.toJson()).toList(),
    'week': week.toJson(),
    'overrides': overrides.map((item) => item.toJson()).toList(),
    'callers': callers.map((item) => item.toJson()).toList(),
    'scheduledCalls': scheduledCalls.map((item) => item.toJson()).toList(),
    'credits': credits.map((item) => item.toJson()).toList(),
    'entitlement': entitlement.toJson(),
    'tombstones': tombstones.map((item) => item.toJson()).toList(),
  };

  factory PersistedState.fromJson(Map<String, dynamic> json) {
    final seeded = PersistedState.seed(languageCode: 'en');
    return PersistedState(
      uid: json['uid'] as String?,
      needsPull: json['needsPull'] as bool? ?? false,
      settings: json['settings'] is Map
          ? AppSettings.fromJson((json['settings'] as Map).cast<String, dynamic>())
          : seeded.settings,
      session: json['session'] is Map
          ? TimerSession.fromJson((json['session'] as Map).cast<String, dynamic>())
          : null,
      sessionClearedAt: _dt(json['sessionClearedAt']),
      runtimeUpdatedAt: _dt(json['runtimeUpdatedAt']) ?? seeded.runtimeUpdatedAt,
      pendingFreedom: json['pendingFreedom'] as bool? ?? false,
      freedomHistoryId: json['freedomHistoryId'] as String?,
      dismissedShiftKey: json['dismissedShiftKey'] as String?,
      ringingCallerId: json['ringingCallerId'] as String?,
      dismissedUpdateBuild: (json['dismissedUpdateBuild'] as num?)?.toInt() ?? 0,
      history: _list(json['history'], WorkRecord.fromJson),
      patterns: _list(json['patterns'], WorkPattern.fromJson),
      week: json['week'] is Map
          ? WeekPlan.fromJson((json['week'] as Map).cast<String, dynamic>())
          : seeded.week,
      overrides: _list(json['overrides'], DateOverride.fromJson),
      callers: _list(json['callers'], Caller.fromJson),
      scheduledCalls: _list(json['scheduledCalls'], ScheduledFakeCall.fromJson),
      credits: _list(json['credits'], CallCredit.fromJson),
      entitlement: Entitlement.fromJson(
        json['entitlement'] is Map ? (json['entitlement'] as Map).cast<String, dynamic>() : null,
      ),
      tombstones: _list(json['tombstones'], Tombstone.fromJson),
    );
  }

  String encode() => jsonEncode(toJson());

  void bumpRuntime(DateTime now) => runtimeUpdatedAt = now;

  void removeWhere(String collection, String id, DateTime now) {
    switch (collection) {
      case 'history':
        history.removeWhere((item) => item.id == id);
      case 'patterns':
        patterns.removeWhere((item) => item.id == id);
      case 'overrides':
        overrides.removeWhere((item) => item.id == id);
      case 'callers':
        callers.removeWhere((item) => item.id == id);
      case 'calls':
        scheduledCalls.removeWhere((item) => item.id == id);
      case 'credits':
        credits.removeWhere((item) => item.id == id);
    }
    tombstones.removeWhere((item) => item.collection == collection && item.id == id);
    tombstones.add(Tombstone(collection: collection, id: id, deletedAt: now));
  }
}

DateTime? _dt(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) decode) {
  final items = raw as List? ?? const [];
  return [
    for (final item in items)
      if (item is Map) decode(item.cast<String, dynamic>()),
  ];
}

String workDateLabel(DateTime date) => dateKey(date);
