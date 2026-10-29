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
    final look = shownLook(premium, settings.camouflageLook);
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
        backgroundColor: look == CamouflageLook.home ? const Color(0xFF9FD4F5) : const Color(0xFFF2F2F7),
        body: SafeArea(
          child: Stack(
            children: [
              switch (look) {
                CamouflageLook.notes => _NotesCover(l10n: l10n, hint: hint),
                CamouflageLook.calendar => _CalendarCover(l10n: l10n, hint: hint),
                CamouflageLook.home => _HomeCover(hint: hint),
              },
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

}

String _clock() {
  final now = DateTime.now();
  return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
}

class _HomeCover extends StatelessWidget {
  const _HomeCover({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_clock(), style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w500)),
          const Spacer(),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            children: const [
              _FakeIcon(icon: Icons.chat_bubble_rounded, label: 'Message'),
              _FakeIcon(icon: Icons.calendar_today_rounded, label: 'Calendar'),
              _FakeIcon(icon: Icons.photo_rounded, label: 'Photos'),
              _FakeIcon(icon: Icons.camera_alt_rounded, label: 'Camera'),
              _FakeIcon(icon: Icons.notes_rounded, label: 'Notes'),
              _FakeIcon(icon: Icons.map_rounded, label: 'Map'),
              _FakeIcon(icon: Icons.wb_sunny_rounded, label: 'Weather'),
              _FakeIcon(icon: Icons.music_note_rounded, label: 'Music'),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.28), borderRadius: BorderRadius.circular(28)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _FakeIcon(icon: Icons.phone_rounded, label: ''),
                _FakeIcon(icon: Icons.language_rounded, label: ''),
                _FakeIcon(icon: Icons.music_note_rounded, label: ''),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(hint, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _NotesCover extends StatelessWidget {
  const _NotesCover({required this.l10n, required this.hint});

  final AppLocalizations l10n;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final notes = [
      (l10n.noteMilk, l10n.noteMilkBody),
      (l10n.noteDentist, l10n.noteDentistBody),
      (l10n.noteReturn, l10n.noteReturnBody),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(l10n.lookNotes, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        for (final note in notes)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 4),
                Text(note.$2, style: const TextStyle(color: Color(0xFF8E8E93))),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Text(hint, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
      ],
    );
  }
}

class _CalendarCover extends StatelessWidget {
  const _CalendarCover({required this.l10n, required this.hint});

  final AppLocalizations l10n;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month);
    final startWeekday = first.weekday % 7;
    final days = DateTime(now.year, now.month + 1, 0).day;
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    final heads = ja ? ['日', '月', '火', '水', '木', '金', '土'] : ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(l10n.lookCalendar, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFFFF3B30))),
        Text('${now.year} / ${now.month}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final head in heads)
              Expanded(child: Center(child: Text(head, style: const TextStyle(color: Color(0xFF8E8E93), fontWeight: FontWeight.w700)))),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          children: [
            for (var i = 0; i < startWeekday; i++) const SizedBox.shrink(),
            for (var day = 1; day <= days; day++)
              Center(
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: day == now.day ? const BoxDecoration(color: Color(0xFFFF3B30), shape: BoxShape.circle) : null,
                  child: Text('$day', style: TextStyle(color: day == now.day ? Colors.white : const Color(0xFF1C1C1E), fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(width: 4, height: 36, decoration: BoxDecoration(color: const Color(0xFFFF3B30), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Text(l10n.calLunch, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(hint, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
      ],
    );
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
