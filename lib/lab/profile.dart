import 'package:tick/lab/logic.dart';
import 'package:tick/lab/models.dart';

const labNickMax = 12;

LabFailure? validateLabNick(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return LabFailure.empty;
  if (trimmed.length > labNickMax) return LabFailure.tooLong;
  if (labHasContact(trimmed)) return LabFailure.contact;
  return null;
}

String resolveLabDisplayName(String? storedNick, String uid) {
  final trimmed = storedNick?.trim() ?? '';
  if (trimmed.isNotEmpty && validateLabNick(trimmed) == null) return trimmed;
  return labName(uid);
}

/// Shared between app UI and lab stores for the signed-in user.
class LabProfileCache {
  String nick = '';
  String? avatarPath;
  String? avatarUrl;

  void apply({required String nick, String? avatarPath, String? avatarUrl}) {
    this.nick = nick;
    this.avatarPath = avatarPath;
    this.avatarUrl = avatarUrl;
  }

  String displayNameFor(String uid) => resolveLabDisplayName(
    nick.isNotEmpty ? nick : null,
    uid,
  );

  String? avatarFor(String uid) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) return avatarUrl;
    if (avatarPath != null && avatarPath!.isNotEmpty) return avatarPath;
    return null;
  }
}
