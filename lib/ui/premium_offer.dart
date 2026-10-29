import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/copy.dart';
import 'package:tick/ui/theme.dart';

Future<void> showPremiumOffer(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final price = await ref.read(appControllerProvider.notifier).priceLabel();
  if (!context.mounted) return;
  final label = price ?? l10n.priceFallback;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: TickColors.cream,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PremiumMark(size: 48),
              const SizedBox(height: 12),
              Text(
                l10n.premiumOfferTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(l10n.premiumOfferLead, style: const TextStyle(height: 1.4)),
              const SizedBox(height: 14),
              for (final line in [
                l10n.premiumOfferCalls,
                l10n.premiumOfferCallers,
                l10n.premiumOfferSounds,
                l10n.premiumOfferLooks,
                l10n.premiumOfferVoice,
                l10n.premiumOfferBefore,
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    line,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    final code = await ref
                        .read(appControllerProvider.notifier)
                        .buyPremium();
                    if (code != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(authText(l10n, code))),
                      );
                    }
                  },
                  child: Text(l10n.premiumOfferBuy(label)),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.premiumOfferLater),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
