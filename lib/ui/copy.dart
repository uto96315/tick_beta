import 'package:flutter/material.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/ui/theme.dart';
import 'package:tick/ui/visuals.dart';

/// Bottom sheet sentinel: clear manual mood and follow timer progress again.
const chickMoodAuto = Object();

const chickMoodPickOrder = [
  ChickMood.heavy,
  ChickMood.sleepy,
  ChickMood.hungry,
  ChickMood.cheer,
  ChickMood.fine,
  ChickMood.away,
];

String moodLabel(AppLocalizations l10n, ChickMood mood) {
  return switch (mood) {
    ChickMood.heavy => l10n.moodHeavy,
    ChickMood.sleepy => l10n.moodSleepy,
    ChickMood.hungry => l10n.moodHungry,
    ChickMood.cheer => l10n.moodCheer,
    ChickMood.fine => l10n.moodFine,
    ChickMood.away => l10n.moodAway,
  };
}

Future<void> showChickMoodPicker(
  BuildContext context, {
  ChickMood? current,
  required void Function(ChickMood? mood) onPick,
}) async {
  final l10n = AppLocalizations.of(context);
  final picked = await showModalBottomSheet<Object?>(
    context: context,
    backgroundColor: TickColors.cream,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Text(
                l10n.moodTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: TickColors.ink,
                ),
              ),
            ),
            for (final mood in chickMoodPickOrder)
              ListTile(
                title: Text(
                  moodLabel(l10n, mood),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: current == mood
                    ? const Icon(Icons.check_rounded, color: TickColors.ink)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => Navigator.pop(sheetContext, mood),
              ),
            const Divider(height: 1),
            ListTile(
              title: Text(
                l10n.moodAuto,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: TickColors.muted,
                ),
              ),
              trailing: current == null
                  ? const Icon(Icons.check_rounded, color: TickColors.muted)
                  : null,
              onTap: () => Navigator.pop(sheetContext, chickMoodAuto),
            ),
          ],
        ),
      );
    },
  );
  if (!context.mounted || picked == null) return;
  if (picked == chickMoodAuto) {
    onPick(null);
    return;
  }
  if (picked is ChickMood) onPick(picked);
}

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
    'email-already-in-use' ||
    'credential-already-in-use' ||
    'provider-already-linked' => l10n.authExists,
    'wrong-password' ||
    'user-not-found' ||
    'invalid-credential' => l10n.authWrong,
    'requires-recent-login' => l10n.authRecent,
    'canceled' => l10n.authCanceled,
    'unavailable' => l10n.googleMissing,
    'purchase-unavailable' => l10n.purchaseUnavailable,
    _ => l10n.authUnknown,
  };
}

String chunkLengthLabel(AppLocalizations l10n, int minutes) {
  if (minutes >= 60 && minutes % 60 == 0)
    return '${minutes ~/ 60}${l10n.hourChunk}';
  return '$minutes${l10n.minuteChunk}';
}

List<String> chickLines(
  AppLocalizations l10n,
  ChickPose pose, {
  ChickVoice voice = ChickVoice.plain,
  String custom = '',
}) {
  final line = custom.trim();
  if (voice == ChickVoice.custom && line.isNotEmpty) return [line];
  if (voice == ChickVoice.lazy) {
    return [
      l10n.voiceLazy1,
      l10n.voiceLazy2,
      l10n.voiceLazy3,
      l10n.voiceLazy4,
      l10n.voiceLazy5,
      l10n.voiceLazy6,
    ];
  }
  if (voice == ChickVoice.kansai) {
    return [
      l10n.voiceKansai1,
      l10n.voiceKansai2,
      l10n.voiceKansai3,
      l10n.voiceKansai4,
      l10n.voiceKansai5,
      l10n.voiceKansai6,
    ];
  }
  return switch (pose) {
    ChickPose.normal => [
      l10n.chickNormal1,
      l10n.chickNormal2,
      l10n.chickNormal3,
      l10n.chickNormal4,
      l10n.chickNormal5,
    ],
    ChickPose.tired => [
      l10n.chickTired1,
      l10n.chickTired2,
      l10n.chickTired3,
      l10n.chickTired4,
      l10n.chickTired5,
    ],
    ChickPose.happy => [
      l10n.chickHappy1,
      l10n.chickHappy2,
      l10n.chickHappy3,
      l10n.chickHappy4,
      l10n.chickHappy5,
    ],
    ChickPose.cheer => [
      l10n.chickCheer1,
      l10n.chickCheer2,
      l10n.chickCheer3,
      l10n.chickCheer4,
      l10n.chickCheer5,
    ],
    ChickPose.attention => [
      l10n.chickAttention1,
      l10n.chickAttention2,
      l10n.chickAttention3,
      l10n.chickAttention4,
      l10n.chickAttention5,
    ],
    ChickPose.surprise => [
      l10n.chickSurprise1,
      l10n.chickSurprise2,
      l10n.chickSurprise3,
    ],
    ChickPose.sleep => [l10n.chickSleep1, l10n.chickSleep2, l10n.chickSleep3],
    ChickPose.done => [l10n.chickDone1, l10n.chickDone2, l10n.chickDone3],
    ChickPose.back => [l10n.chickBack1, l10n.chickBack2, l10n.chickBack3],
    ChickPose.notice => [
      l10n.chickNotice1,
      l10n.chickNotice2,
      l10n.chickNotice3,
    ],
    ChickPose.goodjob => [
      l10n.chickGoodjob1,
      l10n.chickGoodjob2,
      l10n.chickGoodjob3,
    ],
    ChickPose.love => [l10n.chickLove1, l10n.chickLove2, l10n.chickLove3],
    ChickPose.hungry => [l10n.moodHungry1, l10n.moodHungry2, l10n.moodHungry3],
  };
}

List<String> moodLines(AppLocalizations l10n, ChickMood mood) {
  return switch (mood) {
    ChickMood.heavy => [
      l10n.moodHeavy1,
      l10n.moodHeavy2,
      l10n.moodHeavy3,
      l10n.moodHeavy4,
      l10n.moodHeavy5,
    ],
    ChickMood.hungry => [
      l10n.moodHungry1,
      l10n.moodHungry2,
      l10n.moodHungry3,
      l10n.moodHungry4,
      l10n.moodHungry5,
    ],
    ChickMood.sleepy => [
      l10n.moodSleepy1,
      l10n.moodSleepy2,
      l10n.moodSleepy3,
      l10n.moodSleepy4,
      l10n.moodSleepy5,
    ],
    ChickMood.cheer => [l10n.chickGoodjob1, l10n.chickGoodjob2, l10n.chickGoodjob3],
    ChickMood.fine => [
      l10n.moodFine1,
      l10n.moodFine2,
      l10n.moodFine3,
      l10n.moodFine4,
      l10n.moodFine5,
    ],
    ChickMood.away => [l10n.chickBack1, l10n.chickBack2, l10n.chickBack3],
  };
}

ChickPose moodPose(ChickMood mood) {
  return switch (mood) {
    ChickMood.heavy => ChickPose.tired,
    ChickMood.hungry => ChickPose.hungry,
    ChickMood.sleepy => ChickPose.sleep,
    ChickMood.cheer => ChickPose.goodjob,
    ChickMood.fine => ChickPose.happy,
    ChickMood.away => ChickPose.back,
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
