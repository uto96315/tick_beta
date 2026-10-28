import 'records.dart';

class RemoteEntity {
  const RemoteEntity({required this.id, required this.updatedAt, required this.json});

  final String id;
  final DateTime updatedAt;
  final Map<String, dynamic> json;
}

class MergeCollection {
  const MergeCollection({
    required this.entities,
    required this.tombstones,
    required this.upserts,
    required this.deletes,
  });

  final List<RemoteEntity> entities;
  final List<Tombstone> tombstones;
  final List<RemoteEntity> upserts;
  final List<String> deletes;
}

/// Last-write-wins per id. A tombstone wins when it is newer than the entity.
MergeCollection mergeCollection({
  required String collection,
  required List<RemoteEntity> local,
  required List<Tombstone> localTombstones,
  required List<RemoteEntity> remote,
  required List<Tombstone> remoteTombstones,
}) {
  final tombstones = <String, Tombstone>{};
  for (final tombstone in [...localTombstones, ...remoteTombstones]) {
    if (tombstone.collection != collection) continue;
    final previous = tombstones[tombstone.id];
    if (previous == null || tombstone.deletedAt.isAfter(previous.deletedAt)) {
      tombstones[tombstone.id] = tombstone;
    }
  }

  final byId = <String, RemoteEntity>{};
  for (final entity in [...remote, ...local]) {
    final previous = byId[entity.id];
    if (previous == null || entity.updatedAt.isAfter(previous.updatedAt)) {
      byId[entity.id] = entity;
    }
  }

  final removed = <String>[];
  for (final tombstone in tombstones.values.toList()) {
    final entity = byId[tombstone.id];
    if (entity == null || !entity.updatedAt.isAfter(tombstone.deletedAt)) {
      if (entity != null) removed.add(entity.id);
      byId.remove(tombstone.id);
    } else {
      tombstones.remove(tombstone.id);
    }
  }

  final remoteById = {for (final entity in remote) entity.id: entity};
  final upserts = <RemoteEntity>[];
  for (final entity in byId.values) {
    final existing = remoteById[entity.id];
    if (existing == null || entity.updatedAt.isAfter(existing.updatedAt)) {
      upserts.add(entity);
    }
  }

  final deletes = <String>[
    for (final entity in remote)
      if (!byId.containsKey(entity.id)) entity.id,
  ];

  return MergeCollection(
    entities: byId.values.toList(),
    tombstones: tombstones.values.toList(),
    upserts: upserts,
    deletes: deletes,
  );
}

Entitlement mergeEntitlement(Entitlement local, Entitlement remote) {
  if (local.premium || remote.premium) {
    final source = remote.premium ? remote.source : local.source;
    final updatedAt = local.updatedAt.isAfter(remote.updatedAt)
        ? local.updatedAt
        : remote.updatedAt;
    return Entitlement(premium: true, updatedAt: updatedAt, source: source);
  }
  return local.updatedAt.isAfter(remote.updatedAt) ? local : remote;
}

T pickNewer<T>(T local, DateTime localAt, T remote, DateTime remoteAt) {
  return remoteAt.isAfter(localAt) ? remote : local;
}
