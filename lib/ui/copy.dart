import 'package:tick/domain/records.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/ui/visuals.dart';

String flashText(AppLocalizations l10n, String code, String? detail) {
  return switch (code) {
    'too-short' => l10n.tooShort,
    'early' => l10n.earlyDone,
    'premium' => l10n.premiumRequired,
    'limit' => l10n.limitReached,
    'scheduled' => '${l10n.scheduledCall} ${detail ?? ''}',
    'name' => l10n.requiredName,
    'offline' => l10n.offline,
    'passed' => l10n.beforeEndPassed,
    _ => l10n.authUnknown,
  };
}

String authText(AppLocalizations l10n, String code) {
  return switch (code) {
    'invalid-email' => l10n.authInvalid,
    'weak-password' => l10n.authWeak,
    'email-already-in-use' || 'credential-already-in-use' || 'provider-already-linked' => l10n.authExists,
    'wrong-password' || 'user-not-found' || 'invalid-credential' => l10n.authWrong,
    'requires-recent-login' => l10n.authRecent,
    'canceled' => l10n.authCanceled,
    'unavailable' => l10n.googleMissing,
    'purchase-unavailable' => l10n.purchaseUnavailable,
    _ => l10n.authUnknown,
  };
}

String chunkLengthLabel(AppLocalizations l10n, int minutes) {
  if (minutes >= 60 && minutes % 60 == 0) return '${minutes ~/ 60}${l10n.hourChunk}';
  return '$minutes${l10n.minuteChunk}';
}

List<String> chickLines(AppLocalizations l10n, ChickPose pose, {ChickVoice voice = ChickVoice.plain, String custom = ''}) {
  final line = custom.trim();
  if (voice == ChickVoice.custom && line.isNotEmpty) return [line];
  if (voice == ChickVoice.lazy) {
    return [l10n.voiceLazy1, l10n.voiceLazy2, l10n.voiceLazy3, l10n.voiceLazy4, l10n.voiceLazy5, l10n.voiceLazy6];
  }
  if (voice == ChickVoice.kansai) {
    return [l10n.voiceKansai1, l10n.voiceKansai2, l10n.voiceKansai3, l10n.voiceKansai4, l10n.voiceKansai5, l10n.voiceKansai6];
  }
  return switch (pose) {
    ChickPose.normal => [l10n.chickNormal1, l10n.chickNormal2, l10n.chickNormal3],
    ChickPose.tired => [l10n.chickTired1, l10n.chickTired2, l10n.chickTired3],
    ChickPose.happy => [l10n.chickHappy1, l10n.chickHappy2, l10n.chickHappy3],
    ChickPose.cheer => [l10n.chickCheer1, l10n.chickCheer2, l10n.chickCheer3],
    ChickPose.attention => [l10n.chickAttention1, l10n.chickAttention2, l10n.chickAttention3],
    ChickPose.surprise => [l10n.chickSurprise1, l10n.chickSurprise2, l10n.chickSurprise3],
    ChickPose.sleep => [l10n.chickSleep1, l10n.chickSleep2, l10n.chickSleep3],
    ChickPose.done => [l10n.chickDone1, l10n.chickDone2, l10n.chickDone3],
    ChickPose.back => [l10n.chickBack1, l10n.chickBack2, l10n.chickBack3],
    ChickPose.notice => [l10n.chickNotice1, l10n.chickNotice2, l10n.chickNotice3],
    ChickPose.goodjob => [l10n.chickGoodjob1, l10n.chickGoodjob2, l10n.chickGoodjob3],
    ChickPose.love => [l10n.chickLove1, l10n.chickLove2, l10n.chickLove3],
  };
}

List<String> moodLines(AppLocalizations l10n, ChickMood mood) {
  return switch (mood) {
    ChickMood.heavy => [l10n.moodHeavy1, l10n.moodHeavy2, l10n.moodHeavy3],
    ChickMood.tired => [l10n.moodTired1, l10n.moodTired2, l10n.moodTired3],
    ChickMood.sleepy => [l10n.moodSleepy1, l10n.moodSleepy2, l10n.moodSleepy3],
  };
}

ChickPose moodPose(ChickMood mood) {
  return switch (mood) {
    ChickMood.sleepy => ChickPose.sleep,
    ChickMood.heavy || ChickMood.tired => ChickPose.tired,
  };
}

String encouragement(AppLocalizations l10n, int index) {
  return switch (index % 5) {
    0 => l10n.encourage1,
    1 => l10n.encourage2,
    2 => l10n.encourage3,
    3 => l10n.encourage4,
    _ => l10n.encourage5,
  };
}
