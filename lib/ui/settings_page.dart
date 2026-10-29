import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/state/app_state.dart';
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
      backgroundColor: TickColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Row(
              children: [
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, color: TickColors.ink)),
                Text(l10n.settings, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: TickColors.ink)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 12),
              child: Text(l10n.languageFollows, style: const TextStyle(color: TickColors.muted, fontSize: 13)),
            ),
            PopCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    title: Text(l10n.schedule, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(_scheduleLine(app), style: const TextStyle(color: TickColors.muted)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/schedule'),
                  ),
                  ListTile(
                    title: Text(l10n.history, style: const TextStyle(fontWeight: FontWeight.w800)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/history'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PopCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
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
            PopCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.endAction, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final action in EndAction.values)
                        ChoiceChip(
                          label: Text(_endLabel(l10n, action)),
                          selected: settings.endAction == action,
                          onSelected: (_) => controller.updateSettings(settings.copyWith(endAction: action)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PopCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SwitchListTile(
                title: Text(l10n.autoStart),
                subtitle: Text(l10n.autoStartHelp),
                value: settings.autoStart,
                onChanged: (value) => controller.updateSettings(settings.copyWith(autoStart: value)),
              ),
            ),
            const SizedBox(height: 12),
            PopCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.trigger, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(l10n.camouflageHint, style: const TextStyle(color: TickColors.muted, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final trigger in CamouflageTrigger.values)
                        ChoiceChip(
                          label: premiumLabel(_triggerLabel(l10n, trigger), locked: !app.premium && trigger != CamouflageTrigger.corner),
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
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final look in CamouflageLook.values)
                        ChoiceChip(
                          label: premiumLabel(_lookLabel(l10n, look), locked: !app.premium && look != CamouflageLook.home),
                          selected: settings.camouflageLook == look,
                          onSelected: (_) {
                            if (!app.premium && look != CamouflageLook.home) {
                              context.push('/settings/premium');
                              return;
                            }
                            controller.updateSettings(settings.copyWith(camouflageLook: look));
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PopCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.chickVoiceTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final voice in ChickVoice.values)
                        ChoiceChip(
                          label: premiumLabel(_voiceLabel(l10n, voice), locked: !app.premium && voice != ChickVoice.plain),
                          selected: settings.chickVoice == voice,
                          onSelected: (_) {
                            if (!app.premium && voice != ChickVoice.plain) {
                              context.push('/settings/premium');
                              return;
                            }
                            controller.updateSettings(settings.copyWith(chickVoice: voice));
                          },
                        ),
                    ],
                  ),
                  if (app.premium && settings.chickVoice == ChickVoice.custom) ...[
                    const SizedBox(height: 8),
                    _CustomLineField(initial: settings.customChickLine, hint: l10n.customLine, onSave: (value) => controller.updateSettings(settings.copyWith(customChickLine: value))),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            PopCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  ListTile(title: Text(l10n.account, style: const TextStyle(fontWeight: FontWeight.w800)), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings/account')),
                  ListTile(
                    leading: const PremiumMark(size: 32),
                    title: Text(l10n.premium, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(app.premium ? l10n.premiumOwned : l10n.freeTier),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/premium'),
                  ),
                  ListTile(title: Text(l10n.fakeCall, style: const TextStyle(fontWeight: FontWeight.w800)), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/call')),
                  ListTile(
                    title: Text(l10n.camouflage, style: const TextStyle(fontWeight: FontWeight.w800)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => ref.read(appControllerProvider.notifier).setCamouflage(true),
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

String _scheduleLine(AppState app) {
  if (app.patterns.isEmpty) return '';
  final pattern = app.patterns.first;
  return '${pattern.start.label} – ${pattern.end.label}';
}

String _endLabel(AppLocalizations l10n, EndAction action) {
  return switch (action) {
    EndAction.celebration => l10n.actionCelebration,
    EndAction.home => l10n.actionHome,
    EndAction.history => l10n.actionHistory,
  };
}

class _CustomLineField extends StatefulWidget {
  const _CustomLineField({required this.initial, required this.hint, required this.onSave});

  final String initial;
  final String hint;
  final ValueChanged<String> onSave;

  @override
  State<_CustomLineField> createState() => _CustomLineFieldState();
}

class _CustomLineFieldState extends State<_CustomLineField> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void didUpdateWidget(_CustomLineField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial && _controller.text != widget.initial) {
      _controller.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLength: 40,
      decoration: InputDecoration(hintText: widget.hint),
      onSubmitted: widget.onSave,
      onEditingComplete: () => widget.onSave(_controller.text),
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

String _voiceLabel(AppLocalizations l10n, ChickVoice voice) {
  return switch (voice) {
    ChickVoice.plain => l10n.voicePlain,
    ChickVoice.lazy => l10n.voiceLazy,
    ChickVoice.kansai => l10n.voiceKansai,
    ChickVoice.custom => l10n.voiceCustom,
  };
}

String _triggerLabel(AppLocalizations l10n, CamouflageTrigger trigger) {
  return switch (trigger) {
    CamouflageTrigger.corner => l10n.triggerCorner,
    CamouflageTrigger.longPress => l10n.triggerLong,
    CamouflageTrigger.swipe => l10n.triggerSwipe,
  };
}
