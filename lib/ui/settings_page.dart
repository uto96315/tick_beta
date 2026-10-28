import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/theme.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final app = ref.watch(appControllerProvider);
    final settings = app.settings;
    final controller = ref.read(appControllerProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l10n.settings, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(l10n.languageFollows),
            const SizedBox(height: 12),
            PopCard(
              child: Column(
                children: [
                  SwitchListTile(title: Text(l10n.notifyChunk), value: settings.notifySegment, onChanged: (value) => controller.updateSettings(settings.copyWith(notifySegment: value))),
                  SwitchListTile(title: Text(l10n.notifyEnd), value: settings.notifyEnd, onChanged: (value) => controller.updateSettings(settings.copyWith(notifyEnd: value))),
                  SwitchListTile(title: Text(l10n.sound), value: settings.notifySound, onChanged: (value) => controller.updateSettings(settings.copyWith(notifySound: value))),
                  SwitchListTile(title: Text(l10n.vibration), subtitle: Text(l10n.vibrationHelp), value: settings.notifyVibration, onChanged: (value) => controller.updateSettings(settings.copyWith(notifyVibration: value))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.endAction, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final action in EndAction.values)
                  ChoiceChip(
                    label: Text(_endLabel(l10n, action)),
                    selected: settings.endAction == action,
                    onSelected: (_) => controller.updateSettings(settings.copyWith(endAction: action)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.visual, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(l10n.visualHelp),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final visual in TimerVisual.values)
                  ChoiceChip(
                    label: Text(_visualLabel(l10n, visual)),
                    selected: settings.visual == visual,
                    onSelected: (_) => controller.updateSettings(settings.copyWith(visual: visual)),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.showCharacter),
              value: settings.showCharacter,
              onChanged: (value) => controller.updateSettings(settings.copyWith(showCharacter: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.autoStart),
              subtitle: Text(l10n.autoStartHelp),
              value: settings.autoStart,
              onChanged: (value) => controller.updateSettings(settings.copyWith(autoStart: value)),
            ),
            const SizedBox(height: 8),
            Text(l10n.trigger, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(l10n.camouflageHint),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final trigger in CamouflageTrigger.values)
                  ChoiceChip(
                    label: Text(_triggerLabel(l10n, trigger)),
                    selected: settings.camouflageTrigger == trigger,
                    onSelected: (_) {
                      if (!app.premium && trigger != CamouflageTrigger.corner) {
                        context.push('/settings/premium');
                        return;
                      }
                      controller.updateSettings(settings.copyWith(camouflageTrigger: trigger));
                    },
                  ),
              ],
            ),
            if (!app.premium) Text(l10n.premiumCamouflage, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            ListTile(title: Text(l10n.schedule), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings/schedule')),
            ListTile(title: Text(l10n.account), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings/account')),
            ListTile(
              title: Text(l10n.premium),
              subtitle: Text(app.premium ? l10n.premiumOwned : l10n.freeTier),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/premium'),
            ),
          ],
        ),
      ),
    );
  }
}

String _visualLabel(AppLocalizations l10n, TimerVisual visual) {
  return switch (visual) {
    TimerVisual.tiles => l10n.visualTiles,
    TimerVisual.map => l10n.visualMap,
    TimerVisual.character => l10n.visualCharacter,
    TimerVisual.gauge => l10n.visualGauge,
  };
}

String _endLabel(AppLocalizations l10n, EndAction action) {
  return switch (action) {
    EndAction.celebration => l10n.actionCelebration,
    EndAction.home => l10n.actionHome,
    EndAction.history => l10n.actionHistory,
  };
}

String _triggerLabel(AppLocalizations l10n, CamouflageTrigger trigger) {
  return switch (trigger) {
    CamouflageTrigger.corner => l10n.triggerCorner,
    CamouflageTrigger.longPress => l10n.triggerLong,
    CamouflageTrigger.swipe => l10n.triggerSwipe,
  };
}
