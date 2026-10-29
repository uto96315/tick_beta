import 'package:tick/data/persisted_state.dart';
import 'package:tick/domain/fake_call_policy.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/domain/schedule.dart';
import 'package:tick/domain/sync_merge.dart';

class RuntimeSnapshot {
  const RuntimeSnapshot({
    required this.session,
    required this.clearedAt,
    required this.runtimeUpdatedAt,
    required this.pendingFreedom,
    required this.freedomHistoryId,
    required this.dismissedShiftKey,
  });

  final TimerSession? session;
  final DateTime? clearedAt;
  final DateTime runtimeUpdatedAt;
  final bool pendingFreedom;
  final String? freedomHistoryId;
  final String? dismissedShiftKey;

  Map<String, dynamic> toJson() => {
    'session': session?.toJson(),
    'clearedAt': clearedAt?.toIso8601String(),
    'runtimeUpdatedAt': runtimeUpdatedAt.toIso8601String(),
    'pendingFreedom': pendingFreedom,
    'freedomHistoryId': freedomHistoryId,
    'dismissedShiftKey': dismissedShiftKey,
    'updatedAt': runtimeUpdatedAt.toIso8601String(),
  };

  factory RuntimeSnapshot.fromState(PersistedState state) {
    return RuntimeSnapshot(
      session: state.session,
      clearedAt: state.sessionClearedAt,
      runtimeUpdatedAt: state.runtimeUpdatedAt,
      pendingFreedom: state.pendingFreedom,
      freedomHistoryId: state.freedomHistoryId,
      dismissedShiftKey: state.dismissedShiftKey,
    );
  }

  factory RuntimeSnapshot.fromJson(Map<String, dynamic> json) {
    return RuntimeSnapshot(
      session: json['session'] is Map
          ? TimerSession.fromJson((json['session'] as Map).cast<String, dynamic>())
          : null,
      clearedAt: _dt(json['clearedAt']),
      runtimeUpdatedAt: _dt(json['runtimeUpdatedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      pendingFreedom: json['pendingFreedom'] as bool? ?? false,
      freedomHistoryId: json['freedomHistoryId'] as String?,
      dismissedShiftKey: json['dismissedShiftKey'] as String?,
    );
  }
}

class RemoteSnapshot {
  const RemoteSnapshot({
    this.found = false,
    this.settings,
    this.runtime,
    this.week,
    this.entitlement,
    this.history = const [],
    this.patterns = const [],
    this.overrides = const [],
    this.callers = const [],
    this.calls = const [],
    this.credits = const [],
    this.tombstones = const [],
  });

  final bool found;
  final AppSettings? settings;
  final RuntimeSnapshot? runtime;
  final WeekPlan? week;
  final Entitlement? entitlement;
  final List<WorkRecord> history;
  final List<WorkPattern> patterns;
  final List<DateOverride> overrides;
  final List<Caller> callers;
  final List<ScheduledFakeCall> calls;
  final List<CallCredit> credits;
  final List<Tombstone> tombstones;
}

class DocPut {
  const DocPut({required this.collection, required this.id, required this.json});

  final String collection;
  final String id;
  final Map<String, dynamic> json;
}

class StateSyncPlan {
  const StateSyncPlan({
    required this.state,
    required this.writeSettings,
    required this.writeRuntime,
    required this.writeWeek,
    required this.writeEntitlement,
    required this.puts,
    required this.deletes,
    required this.tombstones,
  });

  final PersistedState state;
  final bool writeSettings;
  final bool writeRuntime;
  final bool writeWeek;
  final bool writeEntitlement;
  final List<DocPut> puts;
  final List<DocPut> deletes;
  final List<Tombstone> tombstones;
}

StateSyncPlan planStateSync(PersistedState local, RemoteSnapshot remote) {
  if (local.needsPull && !remote.found) {
    return StateSyncPlan(
      state: local,
      writeSettings: false,
      writeRuntime: false,
      writeWeek: false,
      writeEntitlement: false,
      puts: const [],
      deletes: const [],
      tombstones: const [],
    );
  }

  final settings = remote.settings == null
      ? local.settings
      : pickNewer(local.settings, local.settings.updatedAt, remote.settings!, remote.settings!.updatedAt);
  final week = remote.week == null
      ? local.week
      : pickNewer(local.week, local.week.updatedAt, remote.week!, remote.week!.updatedAt);
  final entitlement = remote.entitlement == null
      ? local.entitlement
      : mergeEntitlement(local.entitlement, remote.entitlement!);
  final runtime = _runtime(local, remote.runtime);

  final history = _mergeRecords(
    collection: 'history',
    local: local.history,
    remote: remote.history,
    localTombstones: local.tombstones,
    remoteTombstones: remote.tombstones,
    id: (item) => item.id,
    updatedAt: (item) => item.updatedAt,
    toJson: (item) => item.toJson(),
    fromEntity: (entity) => WorkRecord.fromJson(entity.json),
  );
  final patterns = _mergeRecords(
    collection: 'patterns',
    local: local.patterns,
    remote: remote.patterns,
    localTombstones: local.tombstones,
    remoteTombstones: remote.tombstones,
    id: (item) => item.id,
    updatedAt: (item) => item.updatedAt,
    toJson: (item) => item.toJson(),
    fromEntity: (entity) => WorkPattern.fromJson(entity.json),
  );
  final overrides = _mergeRecords(
    collection: 'overrides',
    local: local.overrides,
    remote: remote.overrides,
    localTombstones: local.tombstones,
    remoteTombstones: remote.tombstones,
    id: (item) => item.id,
    updatedAt: (item) => item.updatedAt,
    toJson: (item) => item.toJson(),
    fromEntity: (entity) => DateOverride.fromJson(entity.json),
  );
  final callers = _mergeRecords(
    collection: 'callers',
    local: local.callers,
    remote: remote.callers,
    localTombstones: local.tombstones,
    remoteTombstones: remote.tombstones,
    id: (item) => item.id,
    updatedAt: (item) => item.updatedAt,
    toJson: (item) => item.toJson(),
    fromEntity: (entity) => Caller.fromJson(entity.json),
  );
  final calls = _mergeRecords(
    collection: 'calls',
    local: local.scheduledCalls,
    remote: remote.calls,
    localTombstones: local.tombstones,
    remoteTombstones: remote.tombstones,
    id: (item) => item.id,
    updatedAt: (item) => item.updatedAt,
    toJson: (item) => item.toJson(),
    fromEntity: (entity) => ScheduledFakeCall.fromJson(entity.json),
  );
  final credits = _mergeRecords(
    collection: 'credits',
    local: local.credits,
    remote: remote.credits,
    localTombstones: local.tombstones,
    remoteTombstones: remote.tombstones,
    id: (item) => item.id,
    updatedAt: (item) => item.updatedAt,
    toJson: (item) => item.toJson(),
    fromEntity: (entity) => CallCredit.fromJson(entity.json),
  );

  final merged = PersistedState(
    uid: local.uid,
    needsPull: false,
    settings: settings,
    session: runtime.session,
    sessionClearedAt: runtime.clearedAt,
    runtimeUpdatedAt: runtime.runtimeUpdatedAt,
    pendingFreedom: runtime.pendingFreedom,
    freedomHistoryId: runtime.freedomHistoryId,
    dismissedShiftKey: runtime.dismissedShiftKey,
    ringingCallerId: local.ringingCallerId,
    dismissedUpdateBuild: local.dismissedUpdateBuild,
    history: history.entities,
    patterns: patterns.entities,
    week: week,
    overrides: overrides.entities,
    callers: callers.entities,
    scheduledCalls: calls.entities,
    credits: credits.entities,
    entitlement: entitlement,
    tombstones: [
      ...history.tombstones,
      ...patterns.tombstones,
      ...overrides.tombstones,
      ...callers.tombstones,
      ...calls.tombstones,
      ...credits.tombstones,
    ],
  );

  final remoteTombstones = {for (final item in remote.tombstones) item.key: item};
  final tombstoneWrites = [
    for (final item in merged.tombstones)
      if (!remoteTombstones.containsKey(item.key) ||
          item.deletedAt.isAfter(remoteTombstones[item.key]!.deletedAt))
        item,
  ];

  return StateSyncPlan(
    state: merged,
    writeSettings: remote.settings == null || settings.updatedAt.isAfter(remote.settings!.updatedAt),
    writeRuntime:
        remote.runtime == null || runtime.runtimeUpdatedAt.isAfter(remote.runtime!.runtimeUpdatedAt),
    writeWeek: remote.week == null || week.updatedAt.isAfter(remote.week!.updatedAt),
    writeEntitlement: remote.entitlement == null || !_sameEntitlement(entitlement, remote.entitlement!),
    puts: [
      ...history.puts,
      ...patterns.puts,
      ...overrides.puts,
      ...callers.puts,
      ...calls.puts,
      ...credits.puts,
    ],
    deletes: [
      ...history.deletes,
      ...patterns.deletes,
      ...overrides.deletes,
      ...callers.deletes,
      ...calls.deletes,
      ...credits.deletes,
    ],
    tombstones: tombstoneWrites,
  );
}

class _Merged<T> {
  const _Merged({
    required this.entities,
    required this.tombstones,
    required this.puts,
    required this.deletes,
  });

  final List<T> entities;
  final List<Tombstone> tombstones;
  final List<DocPut> puts;
  final List<DocPut> deletes;
}

_Merged<T> _mergeRecords<T>({
  required String collection,
  required List<T> local,
  required List<T> remote,
  required List<Tombstone> localTombstones,
  required List<Tombstone> remoteTombstones,
  required String Function(T item) id,
  required DateTime Function(T item) updatedAt,
  required Map<String, dynamic> Function(T item) toJson,
  required T Function(RemoteEntity entity) fromEntity,
}) {
  final merged = mergeCollection(
    collection: collection,
    local: [
      for (final item in local)
        RemoteEntity(id: id(item), updatedAt: updatedAt(item), json: toJson(item)),
    ],
    localTombstones: localTombstones,
    remote: [
      for (final item in remote)
        RemoteEntity(id: id(item), updatedAt: updatedAt(item), json: toJson(item)),
    ],
    remoteTombstones: remoteTombstones,
  );
  return _Merged(
    entities: [for (final entity in merged.entities) fromEntity(entity)],
    tombstones: merged.tombstones,
    puts: [
      for (final entity in merged.upserts)
        DocPut(collection: collection, id: entity.id, json: entity.json),
    ],
    deletes: [
      for (final itemId in merged.deletes) DocPut(collection: collection, id: itemId, json: const {}),
    ],
  );
}

RuntimeSnapshot _runtime(PersistedState local, RuntimeSnapshot? remote) {
  final current = RuntimeSnapshot.fromState(local);
  if (remote == null || !remote.runtimeUpdatedAt.isAfter(current.runtimeUpdatedAt)) {
    return current;
  }
  return remote;
}

bool _sameEntitlement(Entitlement a, Entitlement b) {
  return a.premium == b.premium && a.source == b.source && a.updatedAt == b.updatedAt;
}

DateTime? _dt(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}
