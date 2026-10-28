import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:tick/services/gateways.dart';

class AssetRingtone implements Ringtone {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> start() async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/ring.wav'));
    } catch (error) {
      debugPrint('ringtone failed: $error');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (error) {
      debugPrint('ringtone stop failed: $error');
    }
  }
}
