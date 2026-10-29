import 'package:flutter/material.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/ui/copy.dart';
import 'package:tick/ui/theme.dart';

class IntervalChoices extends StatelessWidget {
  const IntervalChoices({super.key, required this.minutes, required this.onPreset, required this.onCustom, this.onDark = false});

  final int minutes;
  final ValueChanged<int> onPreset;
  final VoidCallback onCustom;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final presets = [(15, '15${l10n.mins}'), (30, '30${l10n.mins}'), (60, '1${l10n.hours}')];
    final custom = minutes != 15 && minutes != 30 && minutes != 60;
    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final preset in presets)
          ChoiceChip(
            label: Text(preset.$2),
            selected: minutes == preset.$1,
            onSelected: (_) {
              if (minutes != preset.$1) onPreset(preset.$1);
            },
          ),
        ChoiceChip(
          label: Text(custom ? chunkLengthLabel(l10n, minutes) : l10n.intervalCustom),
          selected: custom,
          onSelected: (_) => onCustom(),
        ),
      ],
    );
    if (!onDark) return chips;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final preset in presets)
          _DarkChoice(
            label: preset.$2,
            selected: minutes == preset.$1,
            onTap: () {
              if (minutes != preset.$1) onPreset(preset.$1);
            },
          ),
        _DarkChoice(
          label: custom ? chunkLengthLabel(l10n, minutes) : l10n.intervalCustom,
          selected: custom,
          onTap: onCustom,
        ),
      ],
    );
  }
}

class _DarkChoice extends StatelessWidget {
  const _DarkChoice({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = selected ? TickColors.ink : Colors.white;
    return Material(
      color: selected ? TickColors.yellow : const Color(0xFF2C3A52),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 16, color: ink),
                const SizedBox(width: 4),
              ],
              Text(label, style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

Future<int?> askChunkMinutes(BuildContext context, String title, int initial) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: '$initial');
  final result = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, keyboardType: TextInputType.number, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        TextButton(
          onPressed: () {
            final value = int.tryParse(controller.text.trim());
            if (value == null || value < 1) return;
            Navigator.pop(context, value);
          },
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
