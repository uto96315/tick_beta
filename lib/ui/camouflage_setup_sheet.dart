import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/premium_offer.dart';
import 'package:tick/ui/theme.dart';

Future<void> showCamouflageSetupSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TickColors.cream,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      final bottom = MediaQuery.paddingOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 16),
        child: CamouflageSetupPanel(
          showPreview: false,
          onDone: () => Navigator.pop(sheetContext),
        ),
      );
    },
  );
}

class CamouflageSetupPanel extends ConsumerWidget {
  const CamouflageSetupPanel({
    super.key,
    this.showPreview = true,
    this.onPreview,
    this.onDone,
  });

  final bool showPreview;
  final VoidCallback? onPreview;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final app = ref.watch(appControllerProvider);
    final settings = app.settings;
    final controller = ref.read(appControllerProvider.notifier);
    final hasShot = app.premium && settings.homeShot.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.camouflageSetup,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: TickColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.camouflageSettingsLead,
          style: const TextStyle(
            color: TickColors.muted,
            fontWeight: FontWeight.w600,
            height: 1.35,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.homeShotTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          app.premium ? l10n.homeShotHelp : l10n.homeShotFree,
          style: const TextStyle(
            fontSize: 13,
            color: TickColors.muted,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.camouflageImageUseNote,
          style: const TextStyle(
            fontSize: 12,
            color: TickColors.muted,
            height: 1.35,
          ),
        ),
        if (hasShot) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(settings.homeShot),
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: TickColors.ink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: () async {
              if (!app.premium) {
                showPremiumOffer(context, ref);
                return;
              }
              final image = await ImagePicker().pickImage(
                source: ImageSource.gallery,
              );
              if (image == null) return;
              await controller.setHomeShot(image.path);
            },
            icon: Icon(
              app.premium ? Icons.photo_library_rounded : Icons.lock_rounded,
            ),
            label: Text(l10n.homeShotPick),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.camouflageHint,
          style: const TextStyle(
            color: TickColors.muted,
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final look in CamouflageLook.values)
              ChoiceChip(
                label: premiumLabel(
                  _lookLabel(l10n, look),
                  locked: !app.premium && look != CamouflageLook.home,
                ),
                selected: settings.camouflageLook == look,
                onSelected: (_) {
                  if (!app.premium && look != CamouflageLook.home) {
                    showPremiumOffer(context, ref);
                    return;
                  }
                  controller.updateSettings(
                    settings.copyWith(camouflageLook: look),
                  );
                },
              ),
          ],
        ),
        if (showPreview && onPreview != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPreview,
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l10n.camouflagePreview),
            ),
          ),
        ],
        if (onDone != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: TickColors.yellow,
                foregroundColor: TickColors.ink,
              ),
              onPressed: onDone,
              child: Text(l10n.close),
            ),
          ),
        ],
      ],
    );
  }
}

String _lookLabel(AppLocalizations l10n, CamouflageLook look) {
  return switch (look) {
    CamouflageLook.home => l10n.lookHome,
    CamouflageLook.notes => l10n.lookNotes,
    CamouflageLook.calendar => l10n.lookCalendar,
  };
}
