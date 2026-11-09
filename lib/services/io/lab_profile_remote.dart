import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:tick/lab/profile.dart';

class LabProfileRemote {
  LabProfileRemote({FirebaseFirestore? db, FirebaseStorage? storage})
    : _db = db ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _db.collection('labProfiles');

  Future<({String nick, String? avatarUrl})?> fetch(String uid) async {
    try {
      final doc = await _profiles.doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      final name = data['displayName'];
      final avatar = data['avatarUrl'];
      return (
        nick: name is String ? name.trim() : '',
        avatarUrl: avatar is String && avatar.isNotEmpty ? avatar : null,
      );
    } catch (error) {
      debugPrint('lab profile fetch failed: $error');
      return null;
    }
  }

  Future<void> pushNick(String uid, String nick) async {
    await _profiles.doc(uid).set({
      'displayName': nick.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> uploadAvatar(String uid, String localPath) async {
    final ref = _storage.ref('labProfiles/$uid.jpg');
    await ref.putFile(
      File(localPath),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await ref.getDownloadURL();
    await _profiles.doc(uid).set({
      'avatarUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return url;
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _storage.ref('labProfiles/$uid.jpg').delete();
    } catch (_) {}
    await _profiles.doc(uid).delete();
  }
}

String? sanitizedStoredNick(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  return validateLabNick(trimmed) == null ? trimmed : null;
}
