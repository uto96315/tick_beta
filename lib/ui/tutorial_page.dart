import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/theme.dart';
import 'package:tick/ui/visuals.dart';

class TutorialOverlay extends ConsumerStatefulWidget {
  const TutorialOverlay({super.key});

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay> {
  final _page = PageController();
  var _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [
      (ChickPose.normal, l10n.tutorial1Title, l10n.tutorial1Body),
      (ChickPose.attention, l10n.tutorial2Title, l10n.tutorial2Body),
      (ChickPose.notice, l10n.tutorial3Title, l10n.tutorial3Body),
    ];
    final last = _index == steps.length - 1;
    return Material(
      color: TickColors.skySoft,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => ref.read(appControllerProvider.notifier).completeTutorial(),
                  child: Text(l10n.tutorialSkip),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  itemCount: steps.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) {
                    final step = steps[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TickMascot(size: 180, pose: step.$1),
                        const SizedBox(height: 24),
                        Text(step.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: TickColors.ink)),
                        const SizedBox(height: 12),
                        Text(step.$3, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.5, color: TickColors.muted)),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < steps.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(color: i == _index ? TickColors.ink : TickColors.line, shape: BoxShape.circle),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (last) {
                    ref.read(appControllerProvider.notifier).completeTutorial();
                    return;
                  }
                  _page.nextPage(duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
                },
                child: Text(last ? l10n.tutorialStart : l10n.tutorialNext),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
