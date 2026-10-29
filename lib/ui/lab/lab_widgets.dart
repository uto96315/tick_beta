import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/lab/models.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/ui/theme.dart';

class LabHeader extends StatelessWidget {
  const LabHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          icon: const Icon(Icons.arrow_back, color: TickColors.ink),
        ),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: TickColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class LabScaffold extends StatelessWidget {
  const LabScaffold({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TickColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: children,
        ),
      ),
    );
  }
}

String labCategoryLabel(AppLocalizations l10n, LabCategory category) =>
    switch (category) {
      LabCategory.sit => l10n.labSit,
      LabCategory.stand => l10n.labStand,
      LabCategory.quiet => l10n.labQuiet,
    };

String labFormatLabel(AppLocalizations l10n, LabFormat format) =>
    switch (format) {
      LabFormat.ogiri => l10n.labFormatOgiri,
      LabFormat.quiz => l10n.labFormatQuiz,
      LabFormat.choice => l10n.labFormatChoice,
      LabFormat.draw => l10n.labFormatDraw,
    };

String labPhaseLabel(AppLocalizations l10n, LabPhase phase) => switch (phase) {
  LabPhase.open => l10n.labOpen,
  LabPhase.closed => l10n.labClosed,
};

String labStatusLabel(AppLocalizations l10n, ProposalStatus status) =>
    switch (status) {
      ProposalStatus.pending => l10n.labPending,
      ProposalStatus.accepted => l10n.labAccepted,
      ProposalStatus.rejected => l10n.labRejected,
    };

String labFailureMessage(AppLocalizations l10n, LabFailure failure) =>
    switch (failure) {
      LabFailure.empty => l10n.labFailEmpty,
      LabFailure.tooLong => l10n.labFailLong,
      LabFailure.already => l10n.labFailAlready,
      LabFailure.closed => l10n.labFailClosed,
      LabFailure.selfVote => l10n.labFailSelf,
      LabFailure.forbidden => l10n.labFailForbidden,
      LabFailure.offline => l10n.labFailOffline,
      LabFailure.invalid => l10n.labFailInvalid,
      LabFailure.draw => l10n.labDrawLater,
      LabFailure.contact => l10n.labFailContact,
    };

void labTell(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void labTellOutcome(BuildContext context, LabOutcome outcome) {
  final failure = outcome.failure;
  if (failure == null) return;
  labTell(context, labFailureMessage(AppLocalizations.of(context), failure));
}

Future<bool> labConfirm(
  BuildContext context, {
  required String title,
  required String detail,
}) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(detail),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.labSend),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class LabMeta extends StatelessWidget {
  const LabMeta({super.key, required this.prompt});

  final LabPrompt prompt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(labCategoryLabel(l10n, prompt.category)),
        _Chip(labFormatLabel(l10n, prompt.format)),
        _Chip(labPhaseLabel(l10n, prompt.phase)),
        _Chip(l10n.labCount(prompt.entryCount)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TickColors.skySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
