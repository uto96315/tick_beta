import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tick/data/persisted_state.dart';
import 'package:tick/domain/fake_call_policy.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/domain/schedule.dart';
import 'package:tick/domain/state_sync.dart';
import 'package:tick/services/gateways.dart';

/// Offline-first sync. The on-device store is what the UI reads.
/// Firestore merges with last-write-wins per record. Premium is sticky
/// (either side being premium keeps it), and fake-call credits merge by id
/// so a cancellation is not overwritten by an older count.
class FirestoreSync implements RemoteSync {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<PersistedState?> sync(PersistedState local) async {
    final uid = local.uid;
    if (uid == null || uid.isEmpty) return local;
    try {
      final remote = await _pull(uid).timeout(const Duration(seconds: 8));
      final plan = planStateSync(local, remote);
      await _push(uid, plan).timeout(const Duration(seconds: 8));
      return plan.state;
    } catch (error) {
      debugPrint('sync failed: $error');
      return null;
    }
  }

  @override
  Future<void> deleteUser(String uid) async {
    final root = _db.collection('users').doc(uid);
    for (final name in [
      'history',
      'patterns',
      'overrides',
      'callers',
      'calls',
      'credits',
      'tombstones',
    ]) {
      final snapshot = await root.collection(name).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
    for (final name in ['settings', 'runtime', 'week', 'entitlement']) {
      await root.collection('singletons').doc(name).delete();
    }
  }

  Future<RemoteSnapshot> _pull(String uid) async {
    final root = _db.collection('users').doc(uid);
    final singletons = root.collection('singletons');
    final settingsDoc = await singletons.doc('settings').get();
    final runtimeDoc = await singletons.doc('runtime').get();
    final weekDoc = await singletons.doc('week').get();
    final entitlementDoc = await singletons.doc('entitlement').get();
    final history = await _collection(root, 'history');
    final patterns = await _collection(root, 'patterns');
    final overrides = await _collection(root, 'overrides');
    final callers = await _collection(root, 'callers');
    final calls = await _collection(root, 'calls');
    final credits = await _collection(root, 'credits');
    final tombstones = await _collection(root, 'tombstones');
    final found =
        settingsDoc.exists ||
        runtimeDoc.exists ||
        weekDoc.exists ||
        entitlementDoc.exists ||
        history.isNotEmpty ||
        patterns.isNotEmpty ||
        overrides.isNotEmpty ||
        callers.isNotEmpty ||
        calls.isNotEmpty ||
        credits.isNotEmpty ||
        tombstones.isNotEmpty;
    return RemoteSnapshot(
      found: found,
      settings: _map(settingsDoc) == null
          ? null
          : AppSettings.fromJson(_map(settingsDoc)!),
      runtime: _map(runtimeDoc) == null ? null : RuntimeSnapshot.fromJson(_map(runtimeDoc)!),
      week: _map(weekDoc) == null ? null : WeekPlan.fromJson(_map(weekDoc)!),
      entitlement: _map(entitlementDoc) == null
          ? null
          : Entitlement.fromJson(_map(entitlementDoc)!),
      history: [for (final item in history) WorkRecord.fromJson(item)],
      patterns: [for (final item in patterns) WorkPattern.fromJson(item)],
      overrides: [for (final item in overrides) DateOverride.fromJson(item)],
      callers: [for (final item in callers) Caller.fromJson(item)],
      calls: [for (final item in calls) ScheduledFakeCall.fromJson(item)],
      credits: [for (final item in credits) CallCredit.fromJson(item)],
      tombstones: [for (final item in tombstones) Tombstone.fromJson(item)],
    );
  }

  Future<void> _push(String uid, StateSyncPlan plan) async {
    final root = _db.collection('users').doc(uid);
    final singletons = root.collection('singletons');
    if (plan.writeSettings) {
      await singletons.doc('settings').set(plan.state.settings.toJson());
    }
    if (plan.writeRuntime) {
      await singletons.doc('runtime').set(RuntimeSnapshot.fromState(plan.state).toJson());
    }
    if (plan.writeWeek) {
      await singletons.doc('week').set(plan.state.week.toJson());
    }
    if (plan.writeEntitlement) {
      await singletons.doc('entitlement').set(plan.state.entitlement.toJson());
    }
    for (final put in plan.puts) {
      await root.collection(put.collection).doc(put.id).set(put.json);
    }
    for (final delete in plan.deletes) {
      await root.collection(delete.collection).doc(delete.id).delete();
    }
    for (final tombstone in plan.tombstones) {
      await root.collection('tombstones').doc(tombstone.key.replaceAll('::', '_')).set(
        tombstone.toJson(),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _collection(DocumentReference<Map<String, dynamic>> root, String name) async {
    final snapshot = await root.collection(name).get();
    return [
      for (final doc in snapshot.docs) doc.data(),
    ];
  }

  Map<String, dynamic>? _map(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) return null;
    return doc.data();
  }
}
