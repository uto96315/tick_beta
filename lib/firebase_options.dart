import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Values taken from `GoogleService-Info.plist` for the `tick-beta` project.
/// That file does not include a Google OAuth client id, so Google sign-in
/// stays unavailable until the plist is re-downloaded with `CLIENT_ID`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.iOS) return ios;
    throw UnsupportedError('Tick MVP targets iOS.');
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDS7sQ16A7AmOcF4tAUghABr6bTJxXsnsQ',
    appId: '1:1013298014690:ios:8fe00017c6f73fbcebb1bb',
    messagingSenderId: '1013298014690',
    projectId: 'tick-beta',
    storageBucket: 'tick-beta.firebasestorage.app',
    iosBundleId: 'com.beta.tick',
  );
}
