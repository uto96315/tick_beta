import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Conservative text filter for user submitted public content.
/// Keep in sync with the basic server-side checks in firestore.rules.
class ContentFilter {
  static const blockedPhrases = <String>[
    '死ね',
    '消えろ',
    '殺す',
    '殺してやる',
    'レイプ',
    '児童ポルノ',
    '爆弾作り',
  ];

  static bool containsBlockedPhrase(String text) {
    final normalized = _normalize(text);
    return blockedPhrases.any((phrase) => normalized.contains(phrase));
  }

  static String _normalize(String text) {
    final lower = text.toLowerCase();
    final out = StringBuffer();
    for (final rune in lower.runes) {
      // Normalize full-width ASCII so simple obfuscation does not bypass the
      // filter. Keep Japanese spacing/punctuation intact to avoid overblocking.
      final normalized = rune >= 0xff01 && rune <= 0xff5e
          ? rune - 0xfee0
          : rune;
      out.writeCharCode(normalized);
    }
    return out
        .toString()
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .replaceAll(RegExp(r'[\s　、。・,，.．!！?？〜~…_＿\-－]+'), '');
  }
}

String contentAuthorKey(String uid) =>
    sha256.convert(utf8.encode(uid)).toString();
