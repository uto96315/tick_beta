import 'package:flutter/foundation.dart';

/// Prompt feed diagnostics. Filter Xcode / `flutter run` console with `lab-feed`.
abstract final class LabFeedLog {
  static var _seq = 0;

  static void event(String phase, [Map<String, Object?> details = const {}]) {
    if (!kDebugMode) return;
    final id = ++_seq;
    final buffer = StringBuffer('[lab-feed#$id] $phase');
    if (details.isNotEmpty) {
      buffer.write(' | ');
      buffer.write(
        details.entries.map((e) => '${e.key}=${e.value}').join(' '),
      );
    }
    debugPrint(buffer.toString());
  }
}
