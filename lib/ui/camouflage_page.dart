import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';

class CamouflagePage extends ConsumerWidget {
  const CamouflagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appControllerProvider.select((state) => state.settings));
    final premium = ref.watch(appControllerProvider.select((state) => state.premium));
    final trigger = premium || settings.camouflageTrigger == CamouflageTrigger.corner ? settings.camouflageTrigger : CamouflageTrigger.corner;
    final hint = switch (trigger) {
      CamouflageTrigger.corner => l10n.backHintCorner,
      CamouflageTrigger.longPress => l10n.backHintLong,
      CamouflageTrigger.swipe => l10n.backHintSwipe,
    };
    void exit() => ref.read(appControllerProvider.notifier).setCamouflage(false);
    return GestureDetector(
      onLongPress: trigger == CamouflageTrigger.longPress ? exit : null,
      onVerticalDragEnd: trigger == CamouflageTrigger.swipe ? (details) {
        if ((details.primaryVelocity ?? 0) > 250) exit();
      } : null,
      child: Scaffold(
        backgroundColor: const Color(0xFF8EC5FF),
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_clock(), style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w600)),
                    const Text('Tick', style: TextStyle(color: Colors.white70)),
                    const Spacer(),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 4,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      children: const [
                        _FakeIcon(icon: Icons.notes_rounded, label: 'Notes'),
                        _FakeIcon(icon: Icons.wb_sunny_rounded, label: 'Weather'),
                        _FakeIcon(icon: Icons.photo_rounded, label: 'Photos'),
                        _FakeIcon(icon: Icons.music_note_rounded, label: 'Music'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(hint, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              if (trigger == CamouflageTrigger.corner)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: exit,
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(width: 88, height: 88),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _clock() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class _FakeIcon extends StatelessWidget {
  const _FakeIcon({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: const Color(0xFF31425A)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}
