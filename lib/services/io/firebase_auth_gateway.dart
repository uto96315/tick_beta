import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tick/firebase_options.dart';
import 'package:tick/services/gateways.dart';

class FirebaseAuthGateway implements AuthGateway {
  var _googleReady = false;

  @override
  AuthUser? get current {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return _map(user);
  }

  @override
  Future<AuthUser> ensureSignedIn() async {
    final existing = FirebaseAuth.instance.currentUser;
    if (existing != null) return _map(existing);
    final created = await FirebaseAuth.instance.signInAnonymously();
    return _map(created.user!);
  }

  @override
  Future<AuthUser> registerEmail({required String email, required String password}) async {
    final auth = FirebaseAuth.instance;
    final current = auth.currentUser;
    final credential = EmailAuthProvider.credential(email: email.trim(), password: password);
    try {
      if (current != null && current.isAnonymous) {
        final linked = await current.linkWithCredential(credential);
        return _map(linked.user!);
      }
      final created = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _map(created.user!);
    } on FirebaseAuthException catch (error) {
      throw AuthFlowException(error.code);
    }
  }

  @override
  Future<AuthUser> signInEmail({required String email, required String password}) async {
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _map(result.user!);
    } on FirebaseAuthException catch (error) {
      throw AuthFlowException(error.code);
    }
  }

  @override
  Future<AuthUser> registerGoogle() => _google(link: true);

  @override
  Future<AuthUser> signInGoogle() => _google(link: false);

  Future<AuthUser> _google({required bool link}) async {
    try {
      await _ensureGoogle();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw AuthFlowException('unavailable');
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) throw AuthFlowException('unknown');
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final auth = FirebaseAuth.instance;
      final current = auth.currentUser;
      if (link && current != null && current.isAnonymous) {
        final linked = await current.linkWithCredential(credential);
        return _map(linked.user!);
      }
      final signedIn = await auth.signInWithCredential(credential);
      return _map(signedIn.user!);
    } on FirebaseAuthException catch (error) {
      throw AuthFlowException(error.code);
    } on AuthFlowException {
      rethrow;
    } catch (error) {
      debugPrint('google sign-in failed: $error');
      final text = error.toString().toLowerCase();
      if (text.contains('cancel')) throw AuthFlowException('canceled');
      throw AuthFlowException('unknown');
    }
  }

  Future<void> _ensureGoogle() async {
    if (_googleReady) return;
    final clientId = DefaultFirebaseOptions.ios.iosClientId;
    final usable = clientId != null && clientId.isNotEmpty && clientId != 'REPLACE_ME';
    await GoogleSignIn.instance.initialize(clientId: usable ? clientId : null);
    _googleReady = true;
  }

  @override
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (error) {
      debugPrint('google sign-out skipped: $error');
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (error) {
      throw AuthFlowException(error.code);
    }
  }

  AuthUser _map(User user) {
    final providers = user.providerData.map((item) => item.providerId).toSet();
    var provider = 'anonymous';
    if (providers.contains('google.com')) {
      provider = 'google';
    } else if (providers.contains('password')) {
      provider = 'password';
    }
    return AuthUser(
      uid: user.uid,
      anonymous: user.isAnonymous,
      email: user.email,
      provider: provider,
    );
  }
}
