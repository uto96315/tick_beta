import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/domain/format.dart';
import 'package:tick/lab/logic.dart';
import 'package:tick/lab/models.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/lab/lab_widgets.dart';
import 'package:tick/ui/theme.dart';

class LabPromptPage extends ConsumerStatefulWidget {
  const LabPromptPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<LabPromptPage> createState() => _LabPromptPageState();
}

class _LabPromptPageState extends ConsumerState<LabPromptPage> {
  final _text = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(labStoreProvider);
    return StreamBuilder<PromptBoard>(
      stream: store.watchBoard(widget.id),
      builder: (context, snapshot) {
        final board = snapshot.data;
        final prompt = board?.prompt;
        return LabScaffold(
          children: [
            LabHeader(title: prompt?.title ?? l10n.labTitle),
            if (board == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(color: TickColors.ink),
                ),
              )
            else if (prompt == null)
              Text(l10n.labNotFound)
            else ...[
              if (board.remoteFailed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.labLoadError,
                    style: const TextStyle(
                      color: TickColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(
                prompt.body,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 10),
              LabMeta(prompt: prompt),
              if (prompt.closesAt != null && prompt.phase == LabPhase.open) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.labUntil(formatHm(prompt.closesAt!)),
                  style: const TextStyle(
                    color: TickColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (prompt.format == LabFormat.draw)
                Text(
                  l10n.labDrawLater,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                )
              else if (prompt.format == LabFormat.ogiri)
                _OgiriBox(
                  prompt: prompt,
                  entries: board.entries,
                  controller: _text,
                  busy: _busy,
                  onSubmit: _submitText,
                  onVote: _vote,
                  onReport: _report,
                )
              else
                _ChoiceBox(
                  prompt: prompt,
                  entries: board.entries,
                  busy: _busy,
                  onPick: _submitChoice,
                  onVote: _vote,
                  onReport: _report,
                ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _submitText() async {
    final l10n = AppLocalizations.of(context);
    final text = _text.text.trim();
    final failure = validateAnswer(text);
    if (failure != null) {
      labTell(context, labFailureMessage(l10n, failure));
      return;
    }
    final ok = await labConfirm(
      context,
      title: l10n.labConfirmPost,
      detail: text,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final outcome = await ref
        .read(labStoreProvider)
        .submitText(widget.id, text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome.ok) {
      _text.clear();
      labTell(context, l10n.labPosted);
    } else {
      labTellOutcome(context, outcome);
    }
  }

  Future<void> _submitChoice(int index, String label) async {
    final l10n = AppLocalizations.of(context);
    final ok = await labConfirm(
      context,
      title: l10n.labConfirmPost,
      detail: label,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final outcome = await ref
        .read(labStoreProvider)
        .submitChoice(widget.id, index);
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome.ok) {
      labTell(context, l10n.labPosted);
    } else {
      labTellOutcome(context, outcome);
    }
  }

  Future<void> _vote(String entryUid) async {
    final outcome = await ref
        .read(labStoreProvider)
        .toggleVote(widget.id, entryUid);
    if (!mounted) return;
    labTellOutcome(context, outcome);
  }

  Future<void> _report(LabEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final ok = await labConfirm(
      context,
      title: l10n.labReport,
      detail: entry.text,
    );
    if (!ok || !mounted) return;
    final outcome = await ref
        .read(labStoreProvider)
        .report(widget.id, entry.uid);
    if (!mounted) return;
    if (outcome.ok) {
      labTell(context, l10n.labReported);
    } else {
      labTellOutcome(context, outcome);
    }
  }
}

class _OgiriBox extends StatelessWidget {
  const _OgiriBox({
    required this.prompt,
    required this.entries,
    required this.controller,
    required this.busy,
    required this.onSubmit,
    required this.onVote,
    required this.onReport,
  });

  final LabPrompt prompt;
  final List<LabEntry> entries;
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSubmit;
  final ValueChanged<String> onVote;
  final ValueChanged<LabEntry> onReport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mine = entries.where((entry) => entry.mine).firstOrNull;
    final open = isAccepting(prompt, DateTime.now());
    final voted = entries.any((entry) => entry.votes > 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mine != null) ...[
          Text(
            l10n.labYourAnswer,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(mine.text),
          const SizedBox(height: 16),
        ] else if (open) ...[
          TextField(
            controller: controller,
            maxLength: labAnswerMax,
            maxLines: 3,
            decoration: InputDecoration(hintText: l10n.labAnswerHint),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: busy ? null : onSubmit,
            child: Text(l10n.labAnswer),
          ),
          const SizedBox(height: 16),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              l10n.labFailClosed,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        Text(
          l10n.labRank,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          voted ? l10n.labEntries : l10n.labRankEmpty,
          style: const TextStyle(color: TickColors.muted),
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          Text(l10n.labEmptyEntries)
        else
          for (final entry in entries)
            _EntryTile(entry: entry, onVote: onVote, onReport: onReport),
      ],
    );
  }
}

class _ChoiceBox extends StatelessWidget {
  const _ChoiceBox({
    required this.prompt,
    required this.entries,
    required this.busy,
    required this.onPick,
    required this.onVote,
    required this.onReport,
  });

  final LabPrompt prompt;
  final List<LabEntry> entries;
  final bool busy;
  final void Function(int index, String label) onPick;
  final ValueChanged<String> onVote;
  final ValueChanged<LabEntry> onReport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mine = entries.where((entry) => entry.mine).firstOrNull;
    final open = isAccepting(prompt, DateTime.now());
    final counts = tallyChoices(entries, prompt.choices.length);
    final total = counts.values.fold<int>(0, (sum, count) => sum + count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mine == null && open)
          for (var index = 0; index < prompt.choices.length; index++) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: busy
                    ? null
                    : () => onPick(index, prompt.choices[index]),
                child: Text(prompt.choices[index]),
              ),
            ),
            const SizedBox(height: 8),
          ]
        else if (mine == null)
          Text(
            l10n.labFailClosed,
            style: const TextStyle(fontWeight: FontWeight.w700),
          )
        else ...[
          Text(
            l10n.labYourAnswer,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(mine.text),
          if (prompt.format == LabFormat.quiz &&
              prompt.correctIndex != null) ...[
            const SizedBox(height: 6),
            Text(
              mine.choiceIndex == prompt.correctIndex
                  ? l10n.labCorrect
                  : l10n.labWrong,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.labChoiceResult,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < prompt.choices.length; index++) ...[
            _ShareBar(
              label: prompt.choices[index],
              count: counts[index] ?? 0,
              total: total,
              mine: mine.choiceIndex == index,
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          Text(
            l10n.labEntries,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final entry in entries)
            _EntryTile(entry: entry, onVote: onVote, onReport: onReport),
        ],
      ],
    );
  }
}

class _ShareBar extends StatelessWidget {
  const _ShareBar({
    required this.label,
    required this.count,
    required this.total,
    required this.mine,
  });

  final String label;
  final int count;
  final int total;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;
    final percent = (fraction * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label  $percent%',
          style: TextStyle(
            fontWeight: mine ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 10,
            backgroundColor: TickColors.line,
            color: TickColors.yellow,
          ),
        ),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.onVote,
    required this.onReport,
  });

  final LabEntry entry;
  final ValueChanged<String> onVote;
  final ValueChanged<LabEntry> onReport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PopCard(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      color: TickColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.text,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (entry.hidden)
                    Text(
                      l10n.labHidden,
                      style: const TextStyle(
                        color: TickColors.muted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (!entry.mine)
              IconButton(
                tooltip: l10n.labLike,
                onPressed: () => onVote(entry.uid),
                icon: Icon(
                  entry.voted
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: TickColors.ink,
                ),
              ),
            if (!entry.mine)
              IconButton(
                tooltip: l10n.labReport,
                onPressed: () => onReport(entry),
                icon: const Icon(Icons.flag_outlined, color: TickColors.muted),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 8),
              child: Text(
                '${entry.votes}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
