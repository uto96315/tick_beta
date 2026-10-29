import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:tick/domain/app_update.dart';
import 'package:tick/services/gateways.dart';

class FirebaseUpdatePolicy implements UpdatePolicySource {
  static const minKey = 'ios_min_build';
  static const latestKey = 'ios_latest_build';
  static const urlKey = 'ios_update_url';

  @override
  Future<UpdatePolicy?> load() async {
    try {
      final remote = FirebaseRemoteConfig.instance;
      await remote.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(minutes: 15),
        ),
      );
      await remote.setDefaults(const {minKey: 0, latestKey: 0, urlKey: ''});
      try {
        await remote.fetchAndActivate();
      } catch (error) {
        debugPrint('update check used cache: $error');
        await remote.activate();
      }
      return UpdatePolicy(
        minBuild: remote.getInt(minKey),
        latestBuild: remote.getInt(latestKey),
        url: remote.getString(urlKey),
      );
    } catch (error) {
      debugPrint('update check skipped: $error');
      return null;
    }
  }
}
