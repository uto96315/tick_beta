import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/lab/models.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/theme.dart';

class VentPage extends ConsumerStatefulWidget {
  const VentPage({super.key});

  @override
  ConsumerState<VentPage> createState() => _VentPageState();
}

class _VentPageState extends ConsumerState<VentPage> {
  final _text = TextEditingController();
  late final Stream<VentFeed> _feed;
  var _posting = false;

  @override
  void initState() {
    super.initState();
    _feed = ref.read(labStoreProvider).watchVents();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_posting) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _posting = true);
    final result = await ref.read(labStoreProvider).submitVent(_text.text);
    if (!mounted) return;
    setState(() => _posting = false);
    if (result.ok) {
      _text.clear();
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.ventPostError)));
    }
  }

  Future<void> _react(VentPost post, VentReaction reaction) async {
    final result = await ref
        .read(labStoreProvider)
        .toggleVentReaction(post.id, reaction);
    if (!mounted || result.ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).ventPostError)),
    );
  }

  Future<void> _report(VentPost post) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(l10n.ventReportConfirm, l10n.ventConfirm);
    if (!confirmed || !mounted) return;
    final result = await ref.read(labStoreProvider).reportVent(post.id);
    if (!mounted) return;
    final message = result.ok
        ? l10n.ventReported
        : result.failure == LabFailure.already
        ? l10n.ventReportDuplicate
        : l10n.ventPostError;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _delete(VentPost post) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(l10n.ventDeleteConfirm, l10n.ventConfirm);
    if (!confirmed || !mounted) return;
    final result = await ref.read(labStoreProvider).deleteVent(post.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.ok ? l10n.ventDeleted : l10n.ventPostError),
      ),
    );
  }

  Future<bool> _confirm(String message, String confirmLabel) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.ventCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(labStoreProvider);
    return Scaffold(
      backgroundColor: TickColors.cream,
      appBar: AppBar(
        backgroundColor: TickColors.cream,
        title: Text(l10n.ventTitle),
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Column(
                children: [
                  PopCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFFC75B4D),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            store.sharesWithOthers
                                ? l10n.ventPrivacy
                                : l10n.ventLocalOnly,
                            style: const TextStyle(
                              color: TickColors.ink,
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  PopCard(
                    padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.ventComposeTitle,
                          style: const TextStyle(
                            color: TickColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextField(
                          controller: _text,
                          minLines: 2,
                          maxLines: 4,
                          maxLength: 140,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: l10n.ventHint,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            counterStyle: const TextStyle(
                              color: TickColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _posting ? null : _post,
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: Text(l10n.ventSend),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<VentFeed>(
                stream: _feed,
                builder: (context, snapshot) {
                  final feed = snapshot.data;
                  if (feed == null || feed.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (feed.remoteFailed) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.ventPostError,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: TickColors.muted),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.ventVisibleCount(feed.posts.length),
                            style: const TextStyle(
                              color: TickColors.muted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      if (feed.posts.isEmpty)
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Text(
                                l10n.ventEmpty,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: TickColors.muted,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            itemCount: feed.posts.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) => _VentCard(
                              post: feed.posts[index],
                              onReact: (reaction) =>
                                  _react(feed.posts[index], reaction),
                              onReport: () => _report(feed.posts[index]),
                              onDelete: () => _delete(feed.posts[index]),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VentCard extends StatelessWidget {
  const _VentCard({
    required this.post,
    required this.onReact,
    required this.onReport,
    required this.onDelete,
  });

  final VentPost post;
  final ValueChanged<VentReaction> onReact;
  final VoidCallback onReport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: TickColors.muted,
                size: 18,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _age(l10n, DateTime.now().difference(post.createdAt)),
                  style: const TextStyle(
                    color: TickColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                  if (value == 'report') onReport();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: post.mine ? 'delete' : 'report',
                    child: Text(post.mine ? l10n.ventDelete : l10n.ventReport),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 8, 12),
            child: Text(
              post.text,
              style: const TextStyle(
                color: TickColors.ink,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _ReactionButton(
                label: l10n.ventRelate,
                count: post.relateCount,
                selected: post.myReaction == VentReaction.relate,
                icon: Icons.favorite_border_rounded,
                onPressed: post.mine
                    ? null
                    : () => onReact(VentReaction.relate),
              ),
              _ReactionButton(
                label: l10n.ventCheer,
                count: post.cheerCount,
                selected: post.myReaction == VentReaction.cheer,
                icon: Icons.waving_hand_outlined,
                onPressed: post.mine ? null : () => onReact(VentReaction.cheer),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final int count;
  final bool selected;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text('$label  $count'),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? TickColors.ink : TickColors.muted,
        backgroundColor: selected ? TickColors.yellow : Colors.white,
        side: BorderSide(color: selected ? TickColors.yellow : TickColors.line),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      ),
    );
  }
}

String _age(AppLocalizations l10n, Duration age) {
  if (age.inMinutes < 1) return l10n.ventAgeNow;
  if (age.inHours < 1) return l10n.ventAgeMinutes(age.inMinutes);
  return l10n.ventAgeHours(age.inHours);
}
