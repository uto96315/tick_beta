import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/theme.dart';

const _pages = [
  'assets/images/tutorial/turorial01.png',
  'assets/images/tutorial/tutorial02.png',
  'assets/images/tutorial/tutorial03.png',
];

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
    final last = _index == _pages.length - 1;
    return Material(
      color: TickColors.cream,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) {
                    return Image.asset(_pages[index], fit: BoxFit.contain);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(color: i == _index ? TickColors.ink : TickColors.line, shape: BoxShape.circle),
                    ),
                ],
              ),
              const SizedBox(height: 12),
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
