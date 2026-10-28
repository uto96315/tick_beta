import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/domain/schedule.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';

class PatternPage extends ConsumerStatefulWidget {
  const PatternPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<PatternPage> createState() => _PatternPageState();
}

class _PatternPageState extends ConsumerState<PatternPage> {
  late final TextEditingController _name = TextEditingController();
  ClockTime _start = const ClockTime(9, 0);
  ClockTime _end = const ClockTime(18, 0);
  List<BreakTemplate> _breaks = const [BreakTemplate(id: 'lunch', start: ClockTime(12, 0), end: ClockTime(13, 0))];
  var _ready = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final patterns = ref.watch(appControllerProvider.select((state) => state.patterns));
    WorkPattern? existing;
    for (final pattern in patterns) {
      if (pattern.id == widget.id) existing = pattern;
    }
    if (!_ready) {
      if (existing != null) {
        _name.text = existing.name;
        _start = existing.start;
        _end = existing.end;
        _breaks = existing.breaks;
      } else {
        _name.text = l10n.newPattern;
      }
      _ready = true;
    }
    final crosses = _end.minutesOfDay <= _start.minutesOfDay;
    return Scaffold(
      appBar: AppBar(title: Text(existing == null ? l10n.newPattern : l10n.editPattern)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _name, decoration: InputDecoration(labelText: l10n.name)),
          const SizedBox(height: 12),
          ListTile(
            title: Text(l10n.startTime),
            trailing: Text(_start.label),
            onTap: () => _pick(true),
          ),
          ListTile(
            title: Text(l10n.endTime),
            trailing: Text(_end.label),
            onTap: () => _pick(false),
          ),
          if (crosses) Text(l10n.crossesMidnight),
          const SizedBox(height: 8),
          Text(l10n.breakLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
          for (var i = 0; i < _breaks.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${_breaks[i].start.label} – ${_breaks[i].end.label}'),
              trailing: IconButton(
                onPressed: () => setState(() => _breaks = [for (var n = 0; n < _breaks.length; n++) if (n != i) _breaks[n]]),
                icon: const Icon(Icons.close),
              ),
              onTap: () => _editBreak(i),
            ),
          TextButton(
            onPressed: () => setState(() {
              _breaks = [..._breaks, BreakTemplate(id: 'b${_breaks.length}', start: const ClockTime(12, 0), end: const ClockTime(13, 0))];
            }),
            child: Text(l10n.addBreak),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final id = existing?.id ?? 'pattern-${DateTime.now().microsecondsSinceEpoch}';
              ref.read(appControllerProvider.notifier).upsertPattern(
                WorkPattern(id: id, name: _name.text.trim().isEmpty ? l10n.newPattern : _name.text.trim(), start: _start, end: _end, breaks: _breaks, updatedAt: DateTime.now()),
              );
              context.pop();
            },
            child: Text(l10n.save),
          ),
          if (existing != null)
            TextButton(
              onPressed: () {
                ref.read(appControllerProvider.notifier).deletePattern(existing!.id);
                context.pop();
              },
              child: Text(l10n.deletePattern),
            ),
        ],
      ),
    );
  }

  Future<void> _pick(bool start) async {
    final initial = start ? _start : _end;
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute));
    if (picked == null) return;
    setState(() {
      final clock = ClockTime(picked.hour, picked.minute);
      if (start) {
        _start = clock;
      } else {
        _end = clock;
      }
    });
  }

  Future<void> _editBreak(int index) async {
    final item = _breaks[index];
    final start = await showTimePicker(context: context, initialTime: TimeOfDay(hour: item.start.hour, minute: item.start.minute));
    if (start == null || !mounted) return;
    final end = await showTimePicker(context: context, initialTime: TimeOfDay(hour: item.end.hour, minute: item.end.minute));
    if (end == null) return;
    setState(() {
      _breaks = [
        for (var i = 0; i < _breaks.length; i++)
          if (i == index)
            BreakTemplate(id: item.id, start: ClockTime(start.hour, start.minute), end: ClockTime(end.hour, end.minute))
          else
            _breaks[i],
      ];
    });
  }
}
