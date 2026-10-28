import 'package:tick/l10n/app_localizations.dart';

String flashText(AppLocalizations l10n, String code, String? detail) {
  return switch (code) {
    'too-short' => l10n.tooShort,
    'early' => l10n.earlyDone,
    'premium' => l10n.premiumRequired,
    'limit' => l10n.limitReached,
    'scheduled' => '${l10n.scheduledCall} ${detail ?? ''}',
    'name' => l10n.requiredName,
    'offline' => l10n.offline,
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

String encouragement(AppLocalizations l10n, int index) {
  return switch (index % 5) {
    0 => l10n.encourage1,
    1 => l10n.encourage2,
    2 => l10n.encourage3,
    3 => l10n.encourage4,
    _ => l10n.encourage5,
  };
}
