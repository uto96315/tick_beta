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
  const LabListPage({super.key, this.category});

  final String? category;

  @override
  ConsumerState<LabListPage> createState() => _LabListPageState();
}

class _LabListPageState extends ConsumerState<LabListPage> {
  late LabCategory? _category = labCategoryFrom(widget.category);
  var _openOnly = false;
  var _byCount = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(labStoreProvider);
    return LabScaffold(
      children: [
        LabHeader(title: l10n.labSeeAll),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: Text(l10n.labAll),
              selected: _category == null,
              onSelected: (_) => setState(() => _category = null),
            ),
            for (final category in LabCategory.values)
              FilterChip(
                label: Text(labCategoryLabel(l10n, category)),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              ),
            FilterChip(
              label: Text(l10n.labOpen),
              selected: _openOnly,
              onSelected: (value) => setState(() => _openOnly = value),
            ),
            FilterChip(
              label: Text(l10n.labSortCount),
              selected: _byCount,
              onSelected: (value) => setState(() => _byCount = value),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<LabFeed>(
          stream: store.watchPrompts(),
          builder: (context, snapshot) {
            final feed = snapshot.data;
            if (feed == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(color: TickColors.ink),
                ),
              );
            }
            final prompts = [
              for (final prompt in feed.prompts)
                if (_category == null || prompt.category == _category)
                  if (!_openOnly || prompt.phase == LabPhase.open) prompt,
            ];
            if (_byCount) {
              prompts.sort((a, b) => b.entryCount.compareTo(a.entryCount));
            }
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
                if (_category == LabCategory.sit) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.labDrawLater,
                      style: const TextStyle(color: TickColors.muted),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                for (final prompt in prompts) ...[
                  _PromptCard(prompt: prompt),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt});

  final LabPrompt prompt;

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
            LabMeta(prompt: prompt),
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
