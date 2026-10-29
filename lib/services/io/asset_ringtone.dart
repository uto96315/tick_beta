import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:tick/services/gateways.dart';

class AssetRingtone implements Ringtone {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> start({String sound = 'classic'}) async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      final tone = _tone(sound);
      if (tone == null) {
        await _player.play(AssetSource('sounds/ring.wav'));
      } else {
        await _player.play(BytesSource(tone, mimeType: 'audio/wav'));
      }
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

Uint8List? _tone(String sound) {
  final hz = switch (sound) {
    'soft' => 494.0,
    'bright' => 988.0,
    _ => null,
  };
  if (hz == null) return null;
  const rate = 22050;
  final total = (rate * 1.4).round();
  final pcm = Int16List(total);
  for (var i = 0; i < total; i++) {
    final t = i / rate;
    final gate = t < 0.45 || (t > 0.7 && t < 1.15);
    final sample = gate ? math.sin(2 * math.pi * hz * t) * 0.35 : 0.0;
    pcm[i] = (sample * 32767).round();
  }
  final data = ByteData(pcm.length * 2);
  for (var i = 0; i < pcm.length; i++) {
    data.setInt16(i * 2, pcm[i], Endian.little);
  }
  final bytes = data.buffer.asUint8List();
  final header = ByteData(44);
  final chunk = bytes.length;
  header.setUint8(0, 0x52);
  header.setUint8(1, 0x49);
  header.setUint8(2, 0x46);
  header.setUint8(3, 0x46);
  header.setUint32(4, 36 + chunk, Endian.little);
  header.setUint8(8, 0x57);
  header.setUint8(9, 0x41);
  header.setUint8(10, 0x56);
  header.setUint8(11, 0x45);
  header.setUint8(12, 0x66);
  header.setUint8(13, 0x6d);
  header.setUint8(14, 0x74);
  header.setUint8(15, 0x20);
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, 1, Endian.little);
  header.setUint32(24, rate, Endian.little);
  header.setUint32(28, rate * 2, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  header.setUint8(36, 0x64);
  header.setUint8(37, 0x61);
  header.setUint8(38, 0x74);
  header.setUint8(39, 0x61);
  header.setUint32(40, chunk, Endian.little);
  return Uint8List.fromList([...header.buffer.asUint8List(0, 44), ...bytes]);
}
