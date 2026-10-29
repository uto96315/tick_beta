import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/domain/format.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/theme.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  var _calendar = false;
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(appControllerProvider.select((state) => state.history));
    return Scaffold(
      backgroundColor: TickColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                  icon: const Icon(Icons.arrow_back, color: TickColors.ink),
                ),
                Text(l10n.historyWork, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.viewList)),
                ButtonSegment(value: true, label: Text(l10n.viewCalendar)),
              ],
              selected: {_calendar},
              onSelectionChanged: (value) => setState(() => _calendar = value.first),
            ),
            const SizedBox(height: 16),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Text(l10n.emptyHistory, textAlign: TextAlign.center, style: const TextStyle(color: TickColors.muted, fontSize: 16)),
              )
            else if (_calendar)
              _Month(month: _month, history: history, onPrevious: () => setState(() => _month = DateTime(_month.year, _month.month - 1)), onNext: () => setState(() => _month = DateTime(_month.year, _month.month + 1)))
            else
              for (final record in history) ...[
                _HistoryCard(record: record),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record});
  final WorkRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = (record.achievementRate * 100).round();
    return PopCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => context.push('/history/${record.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateKey(record.workDate), style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('${formatHm(record.actualStart)} – ${formatHm(record.actualEnd)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${record.segmentsCompleted} / ${record.segmentsTotal}  ·  $percent%', style: const TextStyle(color: TickColors.muted)),
            const SizedBox(height: 4),
            Text(record.status == EndStatus.completed ? l10n.statusDone : l10n.statusEarly, style: const TextStyle(color: TickColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _Month extends StatelessWidget {
  const _Month({required this.month, required this.history, required this.onPrevious, required this.onNext});
  final DateTime month;
  final List<WorkRecord> history;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1;
    final marked = {for (final record in history) dateKey(record.workDate)};
    return Column(
      children: [
        Row(
          children: [
            IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
            Expanded(child: Text('${month.year}/${month.month}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))),
            IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
          ],
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lead + days,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemBuilder: (context, index) {
            if (index < lead) return const SizedBox.shrink();
            final day = index - lead + 1;
            final date = DateTime(month.year, month.month, day);
            final hit = marked.contains(dateKey(date));
            final record = hit ? history.where((item) => dateKey(item.workDate) == dateKey(date)).firstOrNull : null;
            return InkWell(
              onTap: record == null ? null : () => context.push('/history/${record.id}'),
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: hit ? const BoxDecoration(color: TickColors.yellow, shape: BoxShape.circle) : null,
                  child: Text('$day', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class HistoryDetailPage extends ConsumerStatefulWidget {
  const HistoryDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends ConsumerState<HistoryDetailPage> {
  late final TextEditingController _memo = TextEditingController();
  var _loaded = false;

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(appControllerProvider.select((state) => state.history));
    WorkRecord? record;
    for (final item in history) {
      if (item.id == widget.id) record = item;
    }
    if (record == null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(l10n.emptyHistory)));
    }
    if (!_loaded) {
      _memo.text = record.memo;
      _loaded = true;
    }
    final current = record;
    final overtime = overtimeOf(current);
    final early = earlyLeaveOf(current);
    return Scaffold(
      appBar: AppBar(title: Text(dateKey(current.workDate))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('${l10n.status}: ${current.status == EndStatus.completed ? l10n.statusDone : l10n.statusEarly}'),
          Text('${l10n.actualStart}: ${formatHm(current.actualStart)}'),
          Text('${l10n.actualEnd}: ${formatHm(current.actualEnd)}'),
          Text('${l10n.originalEnd}: ${formatHm(current.originalPlannedEnd)}'),
          Text('${l10n.achievement}: ${current.segmentsCompleted}/${current.segmentsTotal}'),
          Text('${l10n.rate}: ${(current.achievementRate * 100).round()}%'),
          Text('${l10n.overtime}: ${overtime == Duration.zero ? l10n.overtimeNone : formatLooseDuration(overtime)}'),
          if (early > Duration.zero) Text('${l10n.earlyBy}: ${formatLooseDuration(early)}'),
          Text('${l10n.extendTotal}: ${extensionMinutes(current.extensions)} ${l10n.mins}'),
          const SizedBox(height: 8),
          Text(l10n.extensions, style: const TextStyle(fontWeight: FontWeight.w800)),
          for (final item in current.extensions)
            Text('${formatHm(item.previousEnd)} → ${formatHm(item.newEnd)}  (${item.minutes} ${l10n.mins})'),
          const SizedBox(height: 12),
          TextField(
            controller: _memo,
            decoration: InputDecoration(labelText: l10n.memo, hintText: l10n.memoHint),
            onSubmitted: (value) => ref.read(appControllerProvider.notifier).setMemo(current.id, value),
            onTapOutside: (_) => ref.read(appControllerProvider.notifier).setMemo(current.id, _memo.text),
          ),
          const SizedBox(height: 12),
          Text(l10n.breakLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('${l10n.breakTotal}: ${formatLooseDuration(breakTotal(current.breaks))}'),
          Text(l10n.computedNote, style: const TextStyle(fontSize: 13)),
          for (final span in current.breaks) _BreakEditor(recordId: current.id, span: span),
          if (current.breaks.isEmpty) Text(l10n.noBreaks),
          TextButton(onPressed: () => ref.read(appControllerProvider.notifier).addHistoryBreak(current.id), child: Text(l10n.addBreak)),
        ],
      ),
    );
  }
}

class _BreakEditor extends ConsumerWidget {
  const _BreakEditor({required this.recordId, required this.span});
  final String recordId;
  final BreakSpan span;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(appControllerProvider.notifier);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${formatHm(span.start)} – ${formatHm(span.end)}'),
      subtitle: Text('${l10n.breakTotal} ${formatLooseDuration(span.duration)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _editDuration(context, ref),
            icon: const Icon(Icons.timelapse),
          ),
          IconButton(onPressed: () => controller.removeHistoryBreak(recordId, span.id), icon: const Icon(Icons.close)),
        ],
      ),
      onTap: () async {
        final start = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(span.start));
        if (start == null || !context.mounted) return;
        final end = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(span.end));
        if (end == null) return;
        final nextStart = DateTime(span.start.year, span.start.month, span.start.day, start.hour, start.minute);
        var nextEnd = DateTime(span.end.year, span.end.month, span.end.day, end.hour, end.minute);
        if (!nextEnd.isAfter(nextStart)) nextEnd = nextEnd.add(const Duration(days: 1));
        controller.updateHistoryBreak(recordId, span.id, start: nextStart, end: nextEnd);
      },
    );
  }

  Future<void> _editDuration(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final field = TextEditingController(text: '${span.duration.inMinutes}');
    final minutes = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.breakTotal),
        content: TextField(controller: field, keyboardType: TextInputType.number, autofocus: true, decoration: InputDecoration(suffixText: l10n.mins)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, int.tryParse(field.text.trim())), child: Text(l10n.save)),
        ],
      ),
    );
    field.dispose();
    if (minutes == null || minutes < 1) return;
    ref.read(appControllerProvider.notifier).updateHistoryBreak(recordId, span.id, duration: Duration(minutes: minutes));
  }
}
