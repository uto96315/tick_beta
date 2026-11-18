import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/lab/logic.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/state/app_state.dart';
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
                                      key: ValueKey(
                                        'mascot-option-${kind.name}',
                                      ),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings/account'),
                    ),
                  ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.premium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (app.premium)
                          const PremiumMark(size: 28)
                        else
                          const Text(
                            'Free',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: TickColors.muted,
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/premium'),
                  ),
                  ListTile(
                    title: Text(
                      l10n.fakeCall,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/call'),
                  ),
                  ListTile(
                    title: Text(
                      l10n.camouflage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/camouflage'),
                  ),
                  if (labCanReview(app.auth?.email))
                    ListTile(
                      title: Text(
                        l10n.labReview,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
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
