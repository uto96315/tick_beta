import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/ui/camouflage_page.dart';
import 'package:tick/ui/camouflage_setup_sheet.dart';
import 'package:tick/ui/theme.dart';

class CamouflageSettingsPage extends ConsumerWidget {
  const CamouflageSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: TickColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, color: TickColors.ink),
                ),
                Expanded(
                  child: Text(
                    l10n.camouflage,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: TickColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            PopCard(
              child: CamouflageSetupPanel(
                onPreview: () => openCamouflage(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
