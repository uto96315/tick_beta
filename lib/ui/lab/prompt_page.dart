import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _pickedPhotoPath;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(labStoreProvider);
    final email = ref.watch(
      appControllerProvider.select((state) => state.auth?.email),
    );
    final canModerate = labCanReview(email) || store.canReview;
    return StreamBuilder<PromptBoard>(
      stream: store.watchBoard(widget.id),
      builder: (context, snapshot) {
        final board = snapshot.data;
        final prompt = board?.prompt;
        final headerTitle = prompt != null
            ? labFormatLabel(l10n, prompt.format)
            : l10n.labTitle;
        return LabScaffold(
          header: LabHeader(title: headerTitle),
          body: board == null
              ? const LabFeedLoading()
              : SingleChildScrollView(
                  padding: LabScaffold.scrollPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
            if (prompt == null)
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
              PopCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                    if (prompt.body.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        prompt.body,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: TickColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
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
              if (labTakesPhoto(prompt.format))
                _PhotoBox(
                  prompt: prompt,
                  entries: board.entries,
                  pickedPath: _pickedPhotoPath,
                  busy: _busy,
                  onPick: _pickPhoto,
                  onSubmit: _submitPhoto,
                  onVote: _vote,
                  onReport: _report,
                  onDeleteEntry: canModerate ? _deleteEntry : null,
                )
              else if (labTakesText(prompt.format))
                _OgiriBox(
                  prompt: prompt,
                  entries: board.entries,
                  controller: _text,
                  busy: _busy,
                  onSubmit: _submitText,
                  onVote: _vote,
                  onReport: _report,
                  onDeleteEntry: canModerate ? _deleteEntry : null,
                )
              else
                _ChoiceBox(
                  prompt: prompt,
                  entries: board.entries,
                  busy: _busy,
                  onPick: _submitChoice,
                  onVote: _vote,
                  onReport: _report,
                  onDeleteEntry: canModerate ? _deleteEntry : null,
                  showAllEntries: canModerate,
                ),
            ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  Future<void> _pickPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;
    setState(() => _pickedPhotoPath = image.path);
  }

  Future<void> _submitPhoto() async {
    final path = _pickedPhotoPath;
    if (path == null) {
      labTell(context, AppLocalizations.of(context).labFailPhotoEmpty);
      return;
    }
    final ok = await labConfirmPhotoPost(context, imagePath: path);
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final outcome = await ref
        .read(labStoreProvider)
        .submitPhoto(widget.id, path);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (outcome.ok) _pickedPhotoPath = null;
    });
    if (outcome.ok) {
      labTell(context, AppLocalizations.of(context).labPosted);
    } else {
      labTellOutcome(context, outcome);
    }
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
    if (!mounted || outcome.ok) return;
    labTellOutcome(context, outcome);
  }

  Future<void> _deleteEntry(LabEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final ok = await labConfirm(
      context,
      title: l10n.labDeleteEntry,
      detail: l10n.labDeleteEntryConfirm,
      confirmLabel: l10n.labDeleteEntry,
    );
    if (!ok || !mounted) return;
    final outcome = await ref
        .read(labStoreProvider)
        .deleteEntry(widget.id, entry.uid);
    if (!mounted) return;
    if (outcome.ok) {
      labTell(context, l10n.labDeletedEntry);
    } else {
      labTellOutcome(context, outcome);
    }
  }

  Future<void> _report(LabEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final ok = await labConfirm(
      context,
      title: l10n.labReport,
      detail: entry.imageUrl != null ? l10n.labReportPhoto : entry.text,
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

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({
    required this.prompt,
    required this.entries,
    required this.pickedPath,
    required this.busy,
    required this.onPick,
    required this.onSubmit,
    required this.onVote,
    required this.onReport,
    this.onDeleteEntry,
  });

  final LabPrompt prompt;
  final List<LabEntry> entries;
  final String? pickedPath;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onSubmit;
  final ValueChanged<String> onVote;
  final ValueChanged<LabEntry> onReport;
  final Future<void> Function(LabEntry entry)? onDeleteEntry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mine = entries.where((entry) => entry.mine).firstOrNull;
    final open = isAccepting(prompt, DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mine != null) ...[
          Text(
            l10n.labYourAnswer,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (mine.imageUrl != null)
            LabEntryImage(imageUrl: mine.imageUrl!)
          else
            Text(mine.text),
          const SizedBox(height: 16),
        ] else if (open) ...[
          Text(
            l10n.labPhotoHint,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (pickedPath != null) ...[
            LabEntryImage(imageUrl: pickedPath!),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: busy ? null : onPick,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(
              pickedPath == null ? l10n.labPhotoPick : l10n.labPhotoReplace,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: busy || pickedPath == null ? null : onSubmit,
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
        LabRankList(
          entries: entries,
          onVote: onVote,
          onReport: onReport,
          onDeleteEntry: onDeleteEntry,
        ),
      ],
    );
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
    this.onDeleteEntry,
  });

  final LabPrompt prompt;
  final List<LabEntry> entries;
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSubmit;
  final ValueChanged<String> onVote;
  final ValueChanged<LabEntry> onReport;
  final Future<void> Function(LabEntry entry)? onDeleteEntry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mine = entries.where((entry) => entry.mine).firstOrNull;
    final open = isAccepting(prompt, DateTime.now());
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
        LabRankList(
          entries: entries,
          onVote: onVote,
          onReport: onReport,
          onDeleteEntry: onDeleteEntry,
        ),
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
    this.onDeleteEntry,
    this.showAllEntries = false,
  });

  final LabPrompt prompt;
  final List<LabEntry> entries;
  final bool busy;
  final void Function(int index, String label) onPick;
  final ValueChanged<String> onVote;
  final ValueChanged<LabEntry> onReport;
  final Future<void> Function(LabEntry entry)? onDeleteEntry;
  final bool showAllEntries;

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
        else if (mine == null && !showAllEntries)
          Text(
            l10n.labFailClosed,
            style: const TextStyle(fontWeight: FontWeight.w700),
          )
        else if (mine != null) ...[
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
          for (final entry in entries.where((entry) => !entry.hidden))
            LabEntryTile(
              entry: entry,
              onVote: onVote,
              onReport: onReport,
              onDeleteEntry: onDeleteEntry,
            ),
        ],
        if (showAllEntries && mine == null && entries.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.labEntries,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final entry in entries.where((entry) => !entry.hidden))
            LabEntryTile(
              entry: entry,
              onVote: onVote,
              onReport: onReport,
              onDeleteEntry: onDeleteEntry,
            ),
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

