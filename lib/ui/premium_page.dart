import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/copy.dart';

class PremiumPage extends ConsumerWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final premium = ref.watch(appControllerProvider.select((state) => state.premium));
    final controller = ref.read(appControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.premium)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(premium ? l10n.premiumOwned : l10n.priceFallback, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(l10n.premiumPitch),
          const SizedBox(height: 8),
          Text('· ${l10n.unlimited}'),
          Text('· ${l10n.premiumCallers}'),
          Text('· ${l10n.premiumCamouflage}'),
          const SizedBox(height: 20),
          if (!premium)
            FilledButton(
              onPressed: () async {
                final code = await controller.buyPremium();
                if (code != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authText(l10n, code))));
                }
              },
              child: Text(l10n.buy),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final code = await controller.restorePremium();
              if (code != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authText(l10n, code))));
              }
            },
            child: Text(l10n.restore),
          ),
        ],
      ),
    );
  }
}
