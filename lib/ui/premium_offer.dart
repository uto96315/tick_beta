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
  final benefits = [
    (
      Icons.phone_in_talk_rounded,
      l10n.premiumOfferCalls,
      l10n.premiumOfferCallsNote,
    ),
    (
      Icons.person_add_alt_1_rounded,
      l10n.premiumOfferCallers,
      l10n.premiumOfferCallersNote,
    ),
    (
      Icons.smartphone_rounded,
      l10n.premiumOfferIncoming,
      l10n.premiumOfferIncomingNote,
    ),
    (
      Icons.notifications_active_rounded,
      l10n.premiumOfferSounds,
      l10n.premiumOfferSoundsNote,
    ),
    (
      Icons.layers_rounded,
      l10n.premiumOfferLooks,
      l10n.premiumOfferLooksNote,
    ),
    (
      Icons.schedule_rounded,
      l10n.premiumOfferBefore,
      l10n.premiumOfferBeforeNote,
    ),
  ];
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TickColors.cream,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      final bottom = MediaQuery.paddingOf(sheetContext).bottom;
      final maxH = MediaQuery.sizeOf(sheetContext).height * 0.88;
      return SafeArea(
        child: SizedBox(
          height: maxH,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.premiumOfferTitle,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: TickColors.ink,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.premiumOfferLead,
                  style: const TextStyle(
                    color: TickColors.muted,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: benefits.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = benefits[index];
                      return _PremiumBenefit(
                        icon: item.$1,
                        title: item.$2,
                        body: item.$3,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: TickColors.yellow,
                      foregroundColor: TickColors.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      final code = await ref
                          .read(appControllerProvider.notifier)
                          .buyPremium();
                      if (code != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(authText(l10n, code))),
                        );
                      }
                    },
                    child: Text(
                      l10n.premiumOfferBuy(label),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: Text(l10n.premiumOfferLater),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _PremiumBenefit extends StatelessWidget {
  const _PremiumBenefit({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: TickColors.yellow.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: TickColors.ink, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: TickColors.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      color: TickColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
