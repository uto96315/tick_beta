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
  var _category = LabCategory.stand;
  var _format = LabFormat.ogiri;
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
    final choices = splitChoices(_choices.text);
    return LabScaffold(
      children: [
        LabHeader(title: l10n.labPropose),
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
        else ...[
          TextField(
            controller: _title,
            maxLength: labTitleMax,
            decoration: InputDecoration(labelText: l10n.labProposeTitle),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _body,
            maxLength: labBodyMax,
            maxLines: 4,
            decoration: InputDecoration(labelText: l10n.labProposeBody),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.labCategory,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final category in LabCategory.values)
                ChoiceChip(
                  label: Text(labCategoryLabel(l10n, category)),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.labProposeFormat,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final format in LabFormat.values)
                ChoiceChip(
                  label: Text(labFormatLabel(l10n, format)),
                  selected: _format == format,
                  onSelected: (_) => setState(() => _format = format),
                ),
            ],
          ),
          if (_format == LabFormat.quiz || _format == LabFormat.choice) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _choices,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l10n.labChoicesHint),
            ),
            if (_format == LabFormat.quiz && choices.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.labCorrectOptional,
                style: const TextStyle(color: TickColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (var index = 0; index < choices.length; index++)
                    ChoiceChip(
                      label: Text(choices[index]),
                      selected: _correct == index,
                      onSelected: (_) => setState(() => _correct = index),
                    ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _send,
            child: Text(l10n.labProposeSend),
          ),
        ],
      ],
    );
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final choices = splitChoices(_choices.text);
    final draft = LabDraft(
      title: _title.text,
      body: _body.text,
      category: _category,
      format: _format,
      choices: choices,
      correctIndex: _format == LabFormat.quiz && choices.isNotEmpty
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
