import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/lab/logic.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/state/app_state.dart';
import 'package:tick/ui/premium_offer.dart';
import 'package:tick/ui/lab_profile_section.dart';
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
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, color: TickColors.ink),
                ),
                Text(
                  l10n.settings,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: TickColors.ink,
                  ),
                ),
              ],
            ),
            if (_anonymous(app)) ...[
              PopCard(
                color: TickColors.yellow,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(
                    l10n.signInEmail,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/account'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _SectionTitle(l10n.settingsWork),
            PopCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      l10n.schedule,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      _scheduleLine(app),
                      style: const TextStyle(color: TickColors.muted),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/schedule'),
                  ),
                  ListTile(
                    title: Text(
                      l10n.history,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/history'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle(l10n.settingsNotify),
            PopCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(l10n.notifyChunk),
                    value: settings.notifySegment,
                    onChanged: (value) => controller.updateSettings(
                      settings.copyWith(notifySegment: value),
                    ),
                  ),
                  SwitchListTile(
                    title: Text(l10n.notifyEnd),
                    value: settings.notifyEnd,
                    onChanged: (value) => controller.updateSettings(
                      settings.copyWith(notifyEnd: value),
                    ),
                  ),
                  SwitchListTile(
                    title: Text(l10n.sound),
                    value: settings.notifySound,
                    onChanged: (value) => controller.updateSettings(
                      settings.copyWith(notifySound: value),
                    ),
                  ),
                  SwitchListTile(
                    title: Text(l10n.vibration),
                    subtitle: Text(l10n.vibrationHelp),
                    value: settings.notifyVibration,
                    onChanged: (value) => controller.updateSettings(
                      settings.copyWith(notifyVibration: value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle(l10n.settingsTimer),
            PopCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SwitchListTile(
                title: Text(l10n.autoStart),
                subtitle: Text(l10n.autoStartHelp),
                value: settings.autoStart,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(autoStart: value),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle(l10n.camouflage),
            PopCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(
                  l10n.camouflage,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  l10n.camouflageSettingsLead,
                  style: const TextStyle(color: TickColors.muted),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/camouflage'),
              ),
            ),
            const SizedBox(height: 12),
            PopCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.mascotTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final kind in MascotKind.values) ...[
                        if (kind != MascotKind.values.first)
                          const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => controller.updateSettings(
                              settings.copyWith(mascot: kind),
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: settings.mascot == kind
                                    ? TickColors.yellow
                                    : const Color(0xFFFFFBF4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: settings.mascot == kind
                                      ? TickColors.yellow
                                      : TickColors.line,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Column(
                                  children: [
                                    Image.asset(
                                      'assets/images/character/${kind.folder}/normal.png',
                                      height: 64,
                                      width: 64,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      kind == MascotKind.chick
                                          ? l10n.mascotChick
                                          : l10n.mascotSloth,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                  Text(
                    l10n.chickVoiceTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final voice in ChickVoice.values)
                        ChoiceChip(
                          label: premiumLabel(
                            _voiceLabel(l10n, voice),
                            locked: !app.premium && voice != ChickVoice.plain,
                          ),
                          selected: settings.chickVoice == voice,
                          onSelected: (_) {
                            if (!app.premium && voice != ChickVoice.plain) {
                              showPremiumOffer(context, ref);
                              return;
                            }
                            controller.updateSettings(
                              settings.copyWith(chickVoice: voice),
                            );
                          },
                        ),
                    ],
                  ),
                  if (app.premium &&
                      settings.chickVoice == ChickVoice.custom) ...[
                    const SizedBox(height: 8),
                    _CustomLineField(
                      initial: settings.customChickLine,
                      hint: l10n.customLine,
                      onSave: (value) => controller.updateSettings(
                        settings.copyWith(customChickLine: value),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle(l10n.settingsMore),
            PopCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  if (!_anonymous(app))
                    ListTile(
                      title: Text(
                        l10n.account,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings/account'),
                    ),
                  ListTile(
                    leading: const PremiumMark(size: 32),
                    title: Text(
                      l10n.premium,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      app.premium ? l10n.premiumOwned : l10n.freeTier,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/premium'),
                  ),
                  ListTile(
                    title: Text(
                      l10n.fakeCall,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/call'),
                  ),
                  ListTile(
                    title: Text(
                      l10n.camouflage,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      l10n.camouflageSettingsLead,
                      style: const TextStyle(color: TickColors.muted),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/camouflage'),
                  ),
                  if (labCanReview(app.auth?.email))
                    ListTile(
                      title: Text(
                        l10n.labReview,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/lab/review'),
                    ),
                ],
              ),
            ),
            if (app.firebaseConfigured && app.auth?.provider != 'local') ...[
              const SizedBox(height: 16),
              const LabProfileSection(),
            ],
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

bool _anonymous(AppState app) {
  final auth = app.auth;
  return auth == null || auth.anonymous || auth.provider == 'local';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: TickColors.muted,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _CustomLineField extends StatefulWidget {
  const _CustomLineField({
    required this.initial,
    required this.hint,
    required this.onSave,
  });

  final String initial;
  final String hint;
  final ValueChanged<String> onSave;

  @override
  State<_CustomLineField> createState() => _CustomLineFieldState();
}

class _CustomLineFieldState extends State<_CustomLineField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void didUpdateWidget(_CustomLineField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial &&
        _controller.text != widget.initial) {
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

String _voiceLabel(AppLocalizations l10n, ChickVoice voice) {
  return switch (voice) {
    ChickVoice.plain => l10n.voicePlain,
    ChickVoice.lazy => l10n.voiceLazy,
    ChickVoice.kansai => l10n.voiceKansai,
    ChickVoice.custom => l10n.voiceCustom,
  };
}

