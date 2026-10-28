import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tick/data/local_store.dart';
import 'package:tick/firebase_gate.dart';
import 'package:tick/firebase_options.dart';
import 'package:tick/services/gateways.dart';
import 'package:tick/services/io/asset_ringtone.dart';
import 'package:tick/services/io/firebase_auth_gateway.dart';
import 'package:tick/services/io/firestore_sync.dart';
import 'package:tick/services/io/local_notifications.dart';
import 'package:tick/services/io/store_purchases.dart';
import 'package:uuid/uuid.dart';

Future<AppDeps> loadAppDeps() async {
  final store = await LocalStore.open();
  final notifications = LocalNotificationGateway();
  final purchases = StorePurchaseGateway();
  final ringtone = AssetRingtone();
  final ids = const Uuid();
  var firebaseReady = false;
  AuthGateway auth = LocalAuthGateway(
    AuthUser(
      uid: store.state.uid ?? 'local',
      anonymous: true,
      email: null,
      provider: 'local',
    ),
  );
  RemoteSync sync = NoopSync();
  if (kFirebaseConfigured) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
      auth = FirebaseAuthGateway();
      sync = FirestoreSync();
      firebaseReady = true;
    } catch (error) {
      debugPrint('Firebase stayed off: $error');
    }
  }
  return AppDeps(
    store: store,
    auth: auth,
    sync: sync,
    notifications: notifications,
    purchases: purchases,
    ringtone: ringtone,
    clock: SystemClock(),
    firebaseConfigured: firebaseReady,
    newId: ids.v4,
    languageCode: () {
      final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      return code == 'ja' ? 'ja' : 'en';
    },
    savePhoto: (callerId, sourcePath) async {
      final directory = await getApplicationDocumentsDirectory();
      final folder = Directory('${directory.path}/callers');
      await folder.create(recursive: true);
      final target = File('${folder.path}/$callerId.jpg');
      await File(sourcePath).copy(target.path);
      return target.path;
    },
  );
}
