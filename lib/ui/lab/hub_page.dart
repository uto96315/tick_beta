import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/lab/feed_log.dart';
import 'package:tick/lab/logic.dart';
import 'package:tick/lab/models.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/lab/lab_widgets.dart';
import 'package:tick/ui/theme.dart';
import 'package:tick/ui/visuals.dart';

class LabHubPage extends ConsumerStatefulWidget {
  const LabHubPage({super.key});

  @override
  ConsumerState<LabHubPage> createState() => _LabHubPageState();
}

class _LabHubPageState extends ConsumerState<LabHubPage> {
  var _feedGeneration = 0;
  Object? _lastUiLogKey;
  String? _todayCountForId;
  int? _todayEntryCount;

  void _logHubUi(String branch, LabFeed? feed, {required bool waiting}) {
    final key = (
      waiting,
      feed?.loading,
      feed?.remoteFailed,
      feed?.prompts.length,
    );
    if (_lastUiLogKey == key) return;
    _lastUiLogKey = key;
    LabFeedLog.event(
      'ui.hub',
      {
        'branch': branch,
        'waiting': waiting,
        'loading': feed?.loading,
        'remoteFailed': feed?.remoteFailed,
        'count': feed?.prompts.length ?? -1,
      },
    );
  }

  void _retryFeed() {
    ref.read(labStoreProvider).refreshPromptFeed();
    setState(() {
      _feedGeneration++;
      _todayCountForId = null;
      _todayEntryCount = null;
    });
  }

  void _loadTodayEntryCount(LabPrompt today) {
    if (_todayCountForId == today.id) return;
    _todayCountForId = today.id;
    _todayEntryCount = null;
    unawaited(() async {
      final counts = await ref
          .read(labStoreProvider)
          .fetchEntryCounts([today.id]);
      if (!mounted || _todayCountForId != today.id) return;
      setState(() => _todayEntryCount = counts[today.id] ?? 0);
    }());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(labStoreProvider);
    final email = ref.watch(
      appControllerProvider.select((state) => state.auth?.email),
    );
    return LabScaffold(
      header: LabHeader(title: l10n.labTitle),
      body: StreamBuilder<LabFeed>(
        key: ValueKey(_feedGeneration),
        initialData: store.cachedPromptFeed,
        stream: store.watchPrompts(),
        builder: (context, snapshot) {
          final feed = labEffectiveFeed(snapshot, store);
          if (labFeedPending(feed)) {
            _logHubUi(
              'loading',
              feed,
              waiting: snapshot.connectionState == ConnectionState.waiting,
            );
            return const LabFeedLoading();
          }
          final ready = feed!;
          final today = todaysPrompt(ready.prompts);
          if (ready.remoteFailed && ready.prompts.isEmpty) {
            _logHubUi('error.empty', ready, waiting: false);
          } else if (ready.remoteFailed) {
            _logHubUi('error.partial', ready, waiting: false);
          } else if (today == null && ready.prompts.isEmpty) {
            _logHubUi('empty.today', ready, waiting: false);
          } else {
            _logHubUi('content', ready, waiting: false);
          }
          return SingleChildScrollView(
            padding: LabScaffold.scrollPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NowBuilder(
                      builder: (context, now) =>
                          LivingMascot(pose: idlePose(now), size: 72),
                    ),
                  ),
                ),
                if (!store.sharesWithOthers) ...[
                  Text(
                    l10n.labLocalOnly,
                    style: const TextStyle(
                      color: TickColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (ready.remoteFailed && ready.prompts.isEmpty)
                  LabFeedError(onRetry: _retryFeed, emptyFailure: true)
                else ...[
                  if (ready.remoteFailed) ...[
                    LabFeedError(onRetry: _retryFeed),
                    const SizedBox(height: 12),
                  ],
                  if (today == null && ready.prompts.isEmpty)
                    _LabEmptyToday(l10n: l10n)
                  else if (today != null) ...[
                    Builder(
                      builder: (context) {
                        _loadTodayEntryCount(today);
                        return _TodayCard(
                          prompt: today,
                          entryCount: _todayEntryCount,
                        );
                      },
                    ),
                  ],
                  if (ready.prompts.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _CategoryCard(
                      title: l10n.labOthers,
                      help: l10n.labOthersHelp,
                      icon: Icons.grid_view_rounded,
                      onTap: () => context.push('/lab/list'),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: TickColors.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: () => context.push('/lab/propose'),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l10n.labPropose),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.labSafety,
                  style: const TextStyle(
                    color: TickColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                if (labCanReview(email) || store.canReview)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => context.push('/lab/review'),
                      child: Text(l10n.labReview),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LabPill extends StatelessWidget {
  const _LabPill({required this.label, this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent ? TickColors.skySoft : const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: accent ? TickColors.ink : TickColors.muted,
          ),
        ),
      ),
    );
  }
}

class _LabEmptyToday extends StatelessWidget {
  const _LabEmptyToday({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return PopCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabPill(label: l10n.labToday),
          const SizedBox(height: 12),
          Text(
            l10n.labTodayEmpty,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.labTodayPreparingHelp,
            style: const TextStyle(color: TickColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.prompt, this.entryCount});

  final LabPrompt prompt;
  final int? entryCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('/lab/prompt/${prompt.id}'),
        child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: TickColors.yellow.withValues(alpha: 0.85),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _LabPill(label: l10n.labToday, accent: true),
                            const Spacer(),
                            _LabPill(
                              label: labFormatLabel(l10n, prompt.format),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          prompt.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            if (entryCount != null)
                              Text(
                                l10n.labCount(entryCount!),
                                style: const TextStyle(
                                  color: TickColors.muted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            const Spacer(),
                            Text(
                              l10n.labTapToPost,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: TickColors.muted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.help,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String help;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PopCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: TickColors.skySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(icon, color: TickColors.ink, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      help,
                      style: const TextStyle(
                        color: TickColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: TickColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
