import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/domain/format.dart';
import 'package:tick/lab/logic.dart';
import 'package:tick/lab/models.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/lab/lab_widgets.dart';
import 'package:tick/ui/theme.dart';

class LabListPage extends ConsumerStatefulWidget {
  const LabListPage({super.key});

  @override
  ConsumerState<LabListPage> createState() => _LabListPageState();
}

class _LabListPageState extends ConsumerState<LabListPage> {
  var _format = LabFormat.ogiri;
  var _feedGeneration = 0;
  Set<String> _joinedIds = {};
  Map<String, int> _entryCounts = {};
  Object? _listMetaKey;

  Future<void> _loadListMeta(List<LabPrompt> prompts) async {
    final key = (prompts.length, _format);
    if (_listMetaKey == key) return;
    _listMetaKey = key;
    final ids = [for (final p in prompts) if (p.format == _format) p.id];
    final store = ref.read(labStoreProvider);
    final joinedFuture = store.fetchJoinedPromptIds(ids);
    final countsFuture = store.fetchEntryCounts(ids);
    final joined = await joinedFuture;
    final counts = await countsFuture;
    if (!mounted) return;
    setState(() {
      _joinedIds = joined;
      _entryCounts = counts;
    });
  }

  void _retryFeed() {
    ref.read(labStoreProvider).refreshPromptFeed();
    setState(() => _feedGeneration++);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(labStoreProvider);
    return LabScaffold(
      header: LabHeader(title: l10n.labOthers),
      body: StreamBuilder<LabFeed>(
        key: ValueKey(_feedGeneration),
        initialData: store.cachedPromptFeed,
        stream: store.watchPrompts(),
        builder: (context, snapshot) {
          final feed = labEffectiveFeed(snapshot, store);
          if (labFeedPending(feed)) {
            return const LabFeedLoading();
          }
          final ready = feed!;
          if (ready.remoteFailed && ready.prompts.isEmpty) {
            return LabFeedError(onRetry: _retryFeed, emptyFailure: true);
          }
          if (ready.prompts.isEmpty) {
            return SingleChildScrollView(
              padding: LabScaffold.scrollPadding,
              child: PopCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.labTodayEmpty,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.labTodayPreparingHelp,
                      style: const TextStyle(
                        color: TickColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final today = todaysPrompt(ready.prompts);
          final metaKey = (ready.prompts.length, _format);
          if (_listMetaKey != metaKey) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _loadListMeta(ready.prompts);
            });
          }
          return SingleChildScrollView(
            padding: LabScaffold.scrollPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (today == null) ...[
                  Text(
                    l10n.labTodayPreparingHelp,
                    style: const TextStyle(
                      color: TickColors.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final format in const [
                      LabFormat.ogiri,
                      LabFormat.draw,
                      LabFormat.pen,
                      LabFormat.choice,
                    ])
                      ChoiceChip(
                        label: Text(_tabLabel(l10n, format)),
                        selected: _format == format,
                        onSelected: (_) {
                          setState(() {
                            _format = format;
                            _listMetaKey = null;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _PromptList(
                  l10n: l10n,
                  feed: ready,
                  format: _format,
                  joinedIds: _joinedIds,
                  entryCounts: _entryCounts,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PromptList extends StatelessWidget {
  const _PromptList({
    required this.l10n,
    required this.feed,
    required this.format,
    required this.joinedIds,
    required this.entryCounts,
  });

  final AppLocalizations l10n;
  final LabFeed feed;
  final LabFormat format;
  final Set<String> joinedIds;
  final Map<String, int> entryCounts;

  @override
  Widget build(BuildContext context) {
            final prompts = [
              for (final prompt in feed.prompts)
                if (prompt.format == format) prompt,
            ];
            if (prompts.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.labEmptyList),
                  TextButton(
                    onPressed: () => context.push('/lab/propose'),
                    child: Text(l10n.labPropose),
                  ),
                ],
              );
            }
            return Column(
              children: [
                for (final prompt in prompts) ...[
                  _PromptCard(
                    prompt: prompt,
                    joined: joinedIds.contains(prompt.id),
                    entryCount: entryCounts[prompt.id],
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
  }
}

String _tabLabel(AppLocalizations l10n, LabFormat format) {
  return switch (format) {
    LabFormat.ogiri => l10n.labFormatOgiri,
    LabFormat.draw => l10n.labFormatDraw,
    LabFormat.pen => l10n.labFormatPen,
    LabFormat.choice => l10n.labTabChoice,
    LabFormat.quiz => l10n.labFormatQuiz,
  };
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.prompt,
    required this.joined,
    this.entryCount,
  });

  final LabPrompt prompt;
  final bool joined;
  final int? entryCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final closes = prompt.closesAt;
    return PopCard(
      child: InkWell(
        onTap: () => context.push('/lab/prompt/${prompt.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prompt.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(prompt.body, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                if (entryCount != null)
                  Text(
                    l10n.labCount(entryCount!),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: TickColors.muted,
                    ),
                  ),
                const Spacer(),
                Text(
                  joined ? l10n.labJoined : l10n.labNotJoined,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: joined ? TickColors.ink : TickColors.muted,
                  ),
                ),
              ],
            ),
            if (closes != null && prompt.phase == LabPhase.open) ...[
              const SizedBox(height: 8),
              Text(
                l10n.labUntil(formatHm(closes)),
                style: const TextStyle(
                  color: TickColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
