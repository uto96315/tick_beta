import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/domain/app_update.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/state/update_controller.dart';
import 'package:tick/ui/theme.dart';
import 'package:tick/ui/visuals.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({super.key});

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(updateOfferProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = ref.watch(updateOfferProvider);
    final holdOptional = ref.watch(
      appControllerProvider.select(
        (state) => !state.ready || state.liveCall != null || state.camouflage || !state.settings.tutorialSeen,
      ),
    );
    final visible = offer.kind == UpdateKind.required || (offer.kind == UpdateKind.optional && !holdOptional);
    return IgnorePointer(
      ignoring: !visible,
      child: visible ? _surface(context, offer) : const SizedBox.expand(),
    );
  }

  Widget _surface(BuildContext context, UpdateOffer offer) {
    final l10n = AppLocalizations.of(context);
    final requiredUpdate = offer.kind == UpdateKind.required;
    final panel = _UpdatePanel(
      title: requiredUpdate ? l10n.updateRequiredTitle : l10n.updateAvailableTitle,
      message: requiredUpdate ? l10n.updateRequiredBody : l10n.updateAvailableBody,
      pose: requiredUpdate ? ChickPose.attention : ChickPose.notice,
      action: l10n.updateAction,
      later: requiredUpdate ? null : l10n.updateLater,
      url: offer.url,
      onLater: requiredUpdate ? null : () => ref.read(updateOfferProvider.notifier).dismiss(),
    );
    if (requiredUpdate) return _absorb(panel);
    return _absorb(ColoredBox(
      color: const Color(0x99101A2E),
      child: SafeArea(
        child: Center(
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 28), child: panel),
        ),
      ),
    ));
  }
}

Widget _absorb(Widget child) {
  return GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}, child: child);
}

class _UpdatePanel extends StatelessWidget {
  const _UpdatePanel({
    required this.title,
    required this.message,
    required this.pose,
    required this.action,
    required this.later,
    required this.url,
    required this.onLater,
  });

  final String title;
  final String message;
  final ChickPose pose;
  final String action;
  final String? later;
  final String url;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    final full = onLater == null;
    final content = Column(
      mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (full) const Spacer(),
        TickMascot(size: full ? 180 : 120, pose: pose),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: TickColors.muted, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        if (canOpenUpdateLink(url))
          FilledButton(onPressed: () => openUpdateLink(url), child: Text(action)),
        if (later != null) ...[
          const SizedBox(height: 4),
          TextButton(onPressed: onLater, child: Text(later!)),
        ],
        if (full) const Spacer() else const SizedBox(height: 4),
      ],
    );
    if (full) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [TickColors.sky, TickColors.skySoft, TickColors.paper],
          ),
        ),
        child: SafeArea(
          child: Padding(padding: const EdgeInsets.fromLTRB(28, 24, 28, 24), child: content),
        ),
      );
    }
    return PopCard(padding: const EdgeInsets.fromLTRB(22, 22, 22, 12), child: content);
  }
}

Future<void> openUpdateLink(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !canOpenUpdateLink(url)) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}
