import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/lab/lab_store.dart';
import 'package:tick/lab/models.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/ui/lab_profile_section.dart';
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
              fontSize: 20,
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
  const LabScaffold({super.key, required this.header, required this.body});

  final Widget header;
  final Widget body;

  static const scrollPadding = EdgeInsets.fromLTRB(16, 0, 16, 28);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TickColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Expanded(child: body),
          ],
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

/// Genres users can propose (matches the lab list tabs + quiz).
const labProposeFormats = [
  LabFormat.ogiri,
  LabFormat.draw,
  LabFormat.pen,
  LabFormat.choice,
  LabFormat.quiz,
];

String labProposeTitleHint(AppLocalizations l10n, LabFormat format) =>
    switch (format) {
      LabFormat.ogiri => l10n.labProposeTitleHintOgiri,
      LabFormat.choice => l10n.labProposeTitleHintChoice,
      LabFormat.quiz => l10n.labProposeTitleHintQuiz,
      LabFormat.draw => l10n.labProposeTitleHintDraw,
      LabFormat.pen => l10n.labProposeTitleHintPen,
    };

String labFormatLabel(AppLocalizations l10n, LabFormat format) =>
    switch (format) {
      LabFormat.ogiri => l10n.labFormatOgiri,
      LabFormat.quiz => l10n.labFormatQuiz,
      LabFormat.choice => l10n.labFormatChoice,
      LabFormat.draw => l10n.labFormatDraw,
      LabFormat.pen => l10n.labFormatPen,
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
      LabFailure.photo => l10n.labFailPhotoEmpty,
      LabFailure.contact => l10n.labFailContact,
    };

class LabFeedLoading extends StatelessWidget {
  const LabFeedLoading({super.key, this.expanded = true});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    const indicator = SizedBox(
      width: 32,
      height: 32,
      child: CircularProgressIndicator(
        color: TickColors.ink,
        strokeWidth: 2.5,
      ),
    );
    if (expanded) {
      return const Center(child: indicator);
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(child: indicator),
    );
  }
}

LabFeed? labEffectiveFeed(AsyncSnapshot<LabFeed> snapshot, LabStore store) {
  return snapshot.data ?? store.cachedPromptFeed;
}

bool labFeedPending(LabFeed? feed) {
  return feed == null || feed.loading;
}

class LabFeedError extends StatelessWidget {
  const LabFeedError({
    super.key,
    required this.onRetry,
    this.emptyFailure = false,
  });

  final VoidCallback onRetry;
  final bool emptyFailure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            emptyFailure ? l10n.labLoadFailed : l10n.labLoadError,
            style: const TextStyle(height: 1.45, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(l10n.labReload)),
        ],
      ),
    );
  }
}

void labTell(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void labTellOutcome(BuildContext context, LabOutcome outcome) {
  final failure = outcome.failure;
  if (failure == null) return;
  labTell(context, labFailureMessage(AppLocalizations.of(context), failure));
}

Widget _labDialogActionRow(
  BuildContext context, {
  required String cancelLabel,
  required String confirmLabel,
}) {
  return Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ),
    ],
  );
}

Future<bool> labConfirm(
  BuildContext context, {
  required String title,
  required String detail,
  String? confirmLabel,
}) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(detail),
          const SizedBox(height: 20),
          _labDialogActionRow(
            context,
            cancelLabel: l10n.cancel,
            confirmLabel: confirmLabel ?? l10n.labSend,
          ),
        ],
      ),
    ),
  );
  return ok ?? false;
}

Future<bool> labConfirmPhotoPost(
  BuildContext context, {
  required String imagePath,
}) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.labConfirmPost),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(imagePath),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.labPhotoPolicyWarning,
              style: const TextStyle(height: 1.45),
            ),
            const SizedBox(height: 20),
            _labDialogActionRow(
              context,
              cancelLabel: l10n.cancel,
              confirmLabel: l10n.labSend,
            ),
          ],
        ),
      ),
    ),
  );
  return ok ?? false;
}

class LabEntryImage extends StatelessWidget {
  const LabEntryImage({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final remote = imageUrl.startsWith('http');
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: remote
          ? Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 80,
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            )
          : Image.file(
              File(imageUrl),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
    );
  }
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

class LabRankList extends StatelessWidget {
  const LabRankList({
    super.key,
    required this.entries,
    required this.onVote,
    required this.onReport,
    this.onDeleteEntry,
  });

  final List<LabEntry> entries;
  final ValueChanged<String> onVote;
  final ValueChanged<LabEntry> onReport;
  final Future<void> Function(LabEntry entry)? onDeleteEntry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visible = entries.where((entry) => !entry.hidden).toList();
    final voted = visible.any((entry) => entry.votes > 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.labRank,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          voted ? l10n.labEntries : l10n.labRankEmpty,
          style: const TextStyle(
            color: TickColors.muted,
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          Text(
            l10n.labEmptyEntries,
            style: const TextStyle(color: TickColors.muted),
          )
        else
          for (final entry in visible)
            LabEntryTile(
              entry: entry,
              onVote: onVote,
              onReport: onReport,
              onDeleteEntry: onDeleteEntry,
            ),
      ],
    );
  }
}

class LabEntryTile extends StatelessWidget {
  const LabEntryTile({
    super.key,
    required this.entry,
    required this.onVote,
    required this.onReport,
    this.onDeleteEntry,
  });

  final LabEntry entry;
  final ValueChanged<String> onVote;
  final ValueChanged<LabEntry> onReport;
  final Future<void> Function(LabEntry entry)? onDeleteEntry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PopCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LabUserAvatar(
                  name: entry.name,
                  imageUrl: entry.avatarUrl,
                  radius: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            if (entry.imageUrl != null) ...[
              const SizedBox(height: 10),
              LabEntryImage(imageUrl: entry.imageUrl!),
            ],
            if (entry.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.text,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
            if (entry.hidden)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.labHidden,
                  style: const TextStyle(
                    color: TickColors.muted,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (!entry.mine)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    tooltip: l10n.labReport,
                    onPressed: () => onReport(entry),
                    icon: const Icon(
                      Icons.flag_outlined,
                      size: 20,
                      color: TickColors.muted,
                    ),
                  ),
                if (onDeleteEntry != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    tooltip: l10n.labDeleteEntry,
                    onPressed: () => onDeleteEntry!(entry),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: TickColors.muted,
                    ),
                  ),
                const Spacer(),
                if (!entry.mine)
                  _LabVoteChip(
                    count: entry.votes,
                    voted: entry.voted,
                    onPressed: () => onVote(entry.uid),
                  )
                else if (entry.votes > 0)
                  Text(
                    '${entry.votes}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: TickColors.muted,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabVoteChip extends StatelessWidget {
  const _LabVoteChip({
    required this.count,
    required this.voted,
    required this.onPressed,
  });

  final int count;
  final bool voted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: voted
          ? TickColors.yellow.withValues(alpha: 0.55)
          : const Color(0xFFFFFBF4),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                voted
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 18,
                color: TickColors.ink,
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
