import 'package:tick/data/local_store.dart';
import 'package:tick/lab/lab_store.dart';
import 'package:tick/data/persisted_state.dart';
import 'package:tick/domain/app_update.dart';

class AuthUser {
  const AuthUser({
    required this.uid,
    required this.anonymous,
    required this.email,
    required this.provider,
  });

  final String uid;
  final bool anonymous;
  final String? email;
  final String provider;
}

class AuthFlowException implements Exception {
  AuthFlowException(this.code);
  final String code;
}

abstract class AuthGateway {
  AuthUser? get current;
  Future<AuthUser> ensureSignedIn();
  Future<AuthUser> registerEmail({
    required String email,
    required String password,
  });
  Future<AuthUser> signInEmail({
    required String email,
    required String password,
  });
  Future<AuthUser> registerGoogle();
  Future<AuthUser> signInGoogle();
  Future<void> signOut();
  Future<void> deleteAccount();
}

class LocalAuthGateway implements AuthGateway {
  LocalAuthGateway(this._user);

  final AuthUser _user;

  @override
  AuthUser? get current => _user;

  @override
  Future<AuthUser> ensureSignedIn() async => _user;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<AuthUser> registerEmail({
    required String email,
    required String password,
  }) {
    throw AuthFlowException('unavailable');
  }

  @override
  Future<AuthUser> registerGoogle() => throw AuthFlowException('unavailable');

  @override
  Future<AuthUser> signInEmail({
    required String email,
    required String password,
  }) {
    throw AuthFlowException('unavailable');
  }

  @override
  Future<AuthUser> signInGoogle() => throw AuthFlowException('unavailable');

  @override
  Future<void> signOut() async {}
}

abstract class RemoteSync {
  Future<PersistedState?> sync(PersistedState local);
  Future<void> deleteUser(String uid);
}

class NoopSync implements RemoteSync {
  @override
  Future<void> deleteUser(String uid) async {}

  @override
  Future<PersistedState?> sync(PersistedState local) async => local;
}

typedef NotificationCopy = ({
  String segmentTitle,
  String segmentBody,
  String endTitle,
  String endBody,
  String callTitle,
  String callBody,
});

abstract class NotificationGateway {
  Future<void> init({required void Function(String? payload) onTap});
  Future<void> syncSchedules({
    required PersistedState state,
    required NotificationCopy copy,
    required DateTime now,
  });
}

class NoopNotifications implements NotificationGateway {
  @override
  Future<void> init({required void Function(String? payload) onTap}) async {}

  @override
  Future<void> syncSchedules({
    required PersistedState state,
    required NotificationCopy copy,
    required DateTime now,
  }) async {}
}

abstract class PurchaseGateway {
  Future<void> init({required void Function() onPurchased});
  Future<String?> priceLabel();
  Future<void> buy();
  Future<void> restore();
}

class UnavailablePurchases implements PurchaseGateway {
  @override
  Future<void> buy() => throw AuthFlowException('purchase-unavailable');

  @override
  Future<void> init({required void Function() onPurchased}) async {}

  @override
  Future<String?> priceLabel() async => null;

  @override
  Future<void> restore() async {}
}

abstract class Ringtone {
  Future<void> start({String sound = 'classic'});
  Future<void> stop();
}

class NoopRingtone implements Ringtone {
  @override
  Future<void> start({String sound = 'classic'}) async {}

  @override
  Future<void> stop() async {}
}

abstract class UpdatePolicySource {
  Future<UpdatePolicy?> load();
}

class UnavailableUpdates implements UpdatePolicySource {
  const UnavailableUpdates();

  @override
  Future<UpdatePolicy?> load() async => null;
}

abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}

class AppDeps {
  AppDeps({
    required this.store,
    required this.auth,
    required this.sync,
    required this.notifications,
    required this.purchases,
    required this.ringtone,
    required this.clock,
    required this.firebaseConfigured,
    required this.newId,
    required this.languageCode,
    required this.savePhoto,
    required this.installedBuild,
    required this.updates,
    required this.lab,
  });

  final LocalStore store;
  final AuthGateway auth;
  final RemoteSync sync;
  final NotificationGateway notifications;
  final PurchaseGateway purchases;
  final Ringtone ringtone;
  final Clock clock;
  final bool firebaseConfigured;
  final String Function() newId;
  final String Function() languageCode;
  final Future<String?> Function(String callerId, String sourcePath) savePhoto;
  final int installedBuild;
  final UpdatePolicySource updates;
  final LabStore lab;
}
