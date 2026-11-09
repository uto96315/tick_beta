import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/lab/logic.dart';
import 'package:tick/lab/models.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/lab/lab_widgets.dart';
import 'package:tick/ui/theme.dart';

class LabProposePage extends ConsumerStatefulWidget {
  const LabProposePage({super.key});

  @override
  ConsumerState<LabProposePage> createState() => _LabProposePageState();
}

class _LabProposePageState extends ConsumerState<LabProposePage> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _choices = TextEditingController();
  LabFormat? _format;
  var _correct = 0;
  var _busy = false;
  var _done = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _choices.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LabScaffold(
      header: LabHeader(title: l10n.labPropose),
      body: SingleChildScrollView(
        padding: LabScaffold.scrollPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
        if (_done)
          PopCard(
            child: Text(
              l10n.labProposeDone,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          )
        else if (_format == null)
          _GenreStep(
            onPick: (format) => setState(() => _format = format),
          )
        else
          _ContentStep(
            l10n: l10n,
            format: _format!,
            title: _title,
            body: _body,
            choices: _choices,
            correct: _correct,
            busy: _busy,
            onCorrect: (index) => setState(() => _correct = index),
            onChoicesChanged: () => setState(() {}),
            onChangeGenre: () => setState(() {
              _format = null;
              _title.clear();
              _body.clear();
              _choices.clear();
              _correct = 0;
            }),
            onSend: _send,
          ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final format = _format!;
    final choices = splitChoices(_choices.text);
    final bodyText = _body.text.trim().isEmpty
        ? l10n.labProposeBodyDefault
        : _body.text.trim();
    final draft = LabDraft(
      title: _title.text,
      body: bodyText,
      category: LabCategory.stand,
      format: format,
      choices: choices,
      correctIndex: format == LabFormat.quiz && choices.isNotEmpty
          ? _correct.clamp(0, choices.length - 1)
          : null,
    );
    final failure = validateDraft(draft, publishing: false);
    if (failure != null) {
      labTell(context, labFailureMessage(l10n, failure));
      return;
    }
    final ok = await labConfirm(
      context,
      title: l10n.labConfirmPost,
      detail: draft.title.trim(),
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final outcome = await ref.read(labStoreProvider).propose(draft);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = outcome.ok;
    });
    if (!outcome.ok) labTellOutcome(context, outcome);
  }
}

class _GenreStep extends StatelessWidget {
  const _GenreStep({required this.onPick});

  final ValueChanged<LabFormat> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.labProposePickGenre,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        for (final format in labProposeFormats) ...[
          _GenreTile(
            label: labFormatLabel(l10n, format),
            hint: labProposeTitleHint(l10n, format),
            onTap: () => onPick(format),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _GenreTile extends StatelessWidget {
  const _GenreTile({
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PopCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hint,
                    style: const TextStyle(
                      color: TickColors.muted,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: TickColors.muted),
          ],
        ),
      ),
    );
  }
}

class _ContentStep extends StatelessWidget {
  const _ContentStep({
    required this.l10n,
    required this.format,
    required this.title,
    required this.body,
    required this.choices,
    required this.correct,
    required this.busy,
    required this.onCorrect,
    required this.onChoicesChanged,
    required this.onChangeGenre,
    required this.onSend,
  });

  final AppLocalizations l10n;
  final LabFormat format;
  final TextEditingController title;
  final TextEditingController body;
  final TextEditingController choices;
  final int correct;
  final bool busy;
  final ValueChanged<int> onCorrect;
  final VoidCallback onChoicesChanged;
  final VoidCallback onChangeGenre;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final split = splitChoices(choices.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onChangeGenre,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(l10n.labProposeChangeGenre),
          ),
        ),
        Text(
          labFormatLabel(l10n, format),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: TickColors.muted,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: title,
          maxLength: labTitleMax,
          decoration: InputDecoration(
            labelText: l10n.labProposeTitle,
            hintText: labProposeTitleHint(l10n, format),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: body,
          maxLength: labBodyMax,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.labProposeBody,
            hintText: l10n.labProposeBodyHint,
          ),
        ),
        if (format == LabFormat.quiz || format == LabFormat.choice) ...[
          const SizedBox(height: 12),
          TextField(
            controller: choices,
            maxLines: 4,
            onChanged: (_) => onChoicesChanged(),
            decoration: InputDecoration(labelText: l10n.labChoicesHint),
          ),
          if (format == LabFormat.quiz && split.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.labCorrectOptional,
              style: const TextStyle(color: TickColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (var index = 0; index < split.length; index++)
                  ChoiceChip(
                    label: Text(split[index]),
                    selected: correct == index,
                    onSelected: (_) => onCorrect(index),
                  ),
              ],
            ),
          ],
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TickColors.ink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: busy ? null : onSend,
            child: Text(l10n.labProposeSend),
          ),
        ),
      ],
    );
  }
}
