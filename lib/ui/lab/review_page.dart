import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/lab/logic.dart';
import 'package:tick/lab/models.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/lab/lab_widgets.dart';
import 'package:tick/ui/theme.dart';

class LabReviewPage extends ConsumerWidget {
  const LabReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(labStoreProvider);
    final email = ref.watch(
      appControllerProvider.select((state) => state.auth?.email),
    );
    final allowed = store.canReview || labCanReview(email);
    return LabScaffold(
      children: [
        LabHeader(title: l10n.labReview),
        if (!allowed)
          Text(
            l10n.labReviewLocked,
            style: const TextStyle(fontSize: 16, height: 1.4),
          )
        else ...[
          Text(
            l10n.labOfficial,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const _OfficialForm(),
          const SizedBox(height: 20),
          Text(
            l10n.labPropose,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<LabProposal>>(
            stream: store.watchProposals(),
            builder: (context, snapshot) {
              final items = snapshot.data;
              if (items == null) {
                return const Center(
                  child: CircularProgressIndicator(color: TickColors.ink),
                );
              }
              if (items.isEmpty) return Text(l10n.labNoProposals);
              return Column(
                children: [
                  for (final proposal in items) ...[
                    _ProposalCard(proposal: proposal),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            l10n.labReports,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<LabReport>>(
            stream: store.watchReports(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <LabReport>[];
              if (items.isEmpty) return Text(l10n.labNoReports);
              return Column(
                children: [
                  for (final report in items)
                    PopCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${report.promptId}\n${report.entryUid}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final outcome = await ref
                                  .read(labStoreProvider)
                                  .setEntryHidden(
                                    report.promptId,
                                    report.entryUid,
                                    true,
                                  );
                              if (!context.mounted) return;
                              if (outcome.ok) {
                                labTell(context, l10n.labHidden);
                              } else {
                                labTellOutcome(context, outcome);
                              }
                            },
                            child: Text(l10n.labHide),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _OfficialForm extends ConsumerStatefulWidget {
  const _OfficialForm();

  @override
  ConsumerState<_OfficialForm> createState() => _OfficialFormState();
}

class _OfficialFormState extends ConsumerState<_OfficialForm> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _choices = TextEditingController();
  var _category = LabCategory.stand;
  var _format = LabFormat.ogiri;
  var _correct = 0;
  var _featured = false;
  var _busy = false;

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
    return PopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _title,
            decoration: InputDecoration(labelText: l10n.labProposeTitle),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _body,
            maxLines: 3,
            decoration: InputDecoration(labelText: l10n.labProposeBody),
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
            const SizedBox(height: 8),
            TextField(
              controller: _choices,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l10n.labChoicesHint),
            ),
            if (_format == LabFormat.quiz)
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.labFeatured),
            value: _featured,
            onChanged: (value) => setState(() => _featured = value),
          ),
          FilledButton(
            onPressed: _busy ? null : () => _publish(choices),
            child: Text(l10n.labPublish),
          ),
        ],
      ),
    );
  }

  Future<void> _publish(List<String> choices) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final outcome = await ref
        .read(labStoreProvider)
        .publishPrompt(
          LabDraft(
            title: _title.text,
            body: _body.text,
            category: _category,
            format: _format,
            choices: choices,
            correctIndex: _format == LabFormat.quiz && choices.isNotEmpty
                ? _correct.clamp(0, choices.length - 1)
                : null,
            featured: _featured,
          ),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome.ok) {
      _title.clear();
      _body.clear();
      _choices.clear();
      labTell(context, l10n.labPublished);
    } else {
      labTellOutcome(context, outcome);
    }
  }
}

class _ProposalCard extends ConsumerStatefulWidget {
  const _ProposalCard({required this.proposal});

  final LabProposal proposal;

  @override
  ConsumerState<_ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends ConsumerState<_ProposalCard> {
  late final TextEditingController _title = TextEditingController(
    text: widget.proposal.title,
  );
  late final TextEditingController _body = TextEditingController(
    text: widget.proposal.body,
  );
  var _featured = false;
  var _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final proposal = widget.proposal;
    return PopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labStatusLabel(l10n, proposal.status),
            style: const TextStyle(
              color: TickColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '${labCategoryLabel(l10n, proposal.category)} / ${labFormatLabel(l10n, proposal.format)}',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _title,
            decoration: InputDecoration(labelText: l10n.labProposeTitle),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _body,
            maxLines: 3,
            decoration: InputDecoration(labelText: l10n.labProposeBody),
          ),
          if (proposal.choices.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(proposal.choices.join(' / ')),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.labFeatured),
            value: _featured,
            onChanged: proposal.status == ProposalStatus.rejected
                ? null
                : (value) => setState(() => _featured = value),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _status(ProposalStatus.rejected),
                child: Text(l10n.labReject),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _status(ProposalStatus.accepted),
                child: Text(l10n.labAccept),
              ),
              TextButton(
                onPressed: _busy || proposal.status == ProposalStatus.rejected
                    ? null
                    : _publish,
                child: Text(l10n.labPublish),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _status(ProposalStatus status) async {
    setState(() => _busy = true);
    final outcome = await ref
        .read(labStoreProvider)
        .setProposalStatus(widget.proposal.id, status);
    if (!mounted) return;
    setState(() => _busy = false);
    labTellOutcome(context, outcome);
  }

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final proposal = widget.proposal;
    final outcome = await ref
        .read(labStoreProvider)
        .publishProposal(
          proposal.id,
          LabDraft(
            title: _title.text,
            body: _body.text,
            category: proposal.category,
            format: proposal.format,
            choices: proposal.choices,
            correctIndex: proposal.correctIndex,
            featured: _featured,
          ),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome.ok) {
      labTell(context, l10n.labPublished);
    } else {
      labTellOutcome(context, outcome);
    }
  }
}
