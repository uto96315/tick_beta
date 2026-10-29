import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/lab/logic.dart';
import 'package:tick/lab/models.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/lab/lab_widgets.dart';
import 'package:tick/ui/theme.dart';

class LabHubPage extends ConsumerWidget {
  const LabHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(labStoreProvider);
    final email = ref.watch(
      appControllerProvider.select((state) => state.auth?.email),
    );
    return LabScaffold(
      children: [
        LabHeader(title: l10n.labTitle),
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 12),
          child: Text(
            l10n.labSubtitle,
            style: const TextStyle(color: TickColors.muted, fontSize: 13),
          ),
        ),
        if (!store.sharesWithOthers) ...[
          const SizedBox(height: 4),
          Text(
            l10n.labLocalOnly,
            style: const TextStyle(
              color: TickColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
        ],
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
            final today = todaysPrompt(feed.prompts);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (feed.remoteFailed) ...[
                  Text(
                    l10n.labLoadError,
                    style: const TextStyle(
                      color: TickColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (today == null)
                  PopCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.labToday,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(l10n.labTodayEmpty),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.push('/lab/list'),
                          child: Text(l10n.labSeeAll),
                        ),
                      ],
                    ),
                  )
                else
                  _TodayCard(prompt: today),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _CategoryCard(
          title: l10n.labSit,
          help: l10n.labSitHelp,
          icon: Icons.draw_rounded,
          tint: const Color(0xFFFFF1E4),
          ink: const Color(0xFFD4894C),
          onTap: () => context.push('/lab/list?category=sit'),
        ),
        const SizedBox(height: 8),
        _CategoryCard(
          title: l10n.labStand,
          help: l10n.labStandHelp,
          icon: Icons.psychology_alt_rounded,
          tint: const Color(0xFFE7F6EA),
          ink: const Color(0xFF3C8F55),
          onTap: () => context.push('/lab/list?category=stand'),
        ),
        const SizedBox(height: 8),
        _CategoryCard(
          title: l10n.labQuiet,
          help: l10n.labQuietHelp,
          icon: Icons.visibility_off_rounded,
          tint: const Color(0xFFF3EEFF),
          ink: const Color(0xFF8A74C9),
          onTap: () => context.push('/lab/list?category=quiet'),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.labSafety,
          style: const TextStyle(
            color: TickColors.muted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => context.push('/lab/propose'),
          child: Text(l10n.labPropose),
        ),
        if (labCanReview(email) || store.canReview)
          TextButton(
            onPressed: () => context.push('/lab/review'),
            child: Text(l10n.labReview),
          ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.prompt});

  final LabPrompt prompt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopCard(
      color: TickColors.yellow,
      child: InkWell(
        onTap: () => context.push('/lab/prompt/${prompt.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.labToday,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              prompt.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(prompt.body),
            const SizedBox(height: 8),
            Text(
              l10n.labCount(prompt.entryCount),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
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
    required this.tint,
    required this.ink,
    required this.onTap,
  });

  final String title;
  final String help;
  final IconData icon;
  final Color tint;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PopCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icon, color: ink),
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
                      fontSize: 13,
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
