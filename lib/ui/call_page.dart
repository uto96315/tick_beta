import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tick/domain/fake_call_policy.dart';
import 'package:tick/domain/format.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/premium_offer.dart';
import 'package:tick/ui/theme.dart';

class CallPage extends ConsumerWidget {
  const CallPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final app = ref.watch(appControllerProvider);
    final used = FakeCallPolicy.usedInWeek(app.credits, DateTime.now());
    final openCalls =
        app.premium || FakeCallPolicy.isOwner(app.auth?.email);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.fakeCall)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            openCalls ? l10n.unlimited : l10n.weeklyLimit,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            '${l10n.usedThisWeek}: $used / ${openCalls ? '∞' : FakeCallPolicy.freeWeeklyLimit}',
          ),
          Text(l10n.weekReset, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 16),
          for (final caller in app.callers) ...[
            _CallerTile(caller: caller),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              if (!app.premium) {
                showPremiumOffer(context, ref);
                return;
              }
              final name = TextEditingController();
              final emoji = TextEditingController(text: '📞');
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.addCaller),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: name,
                        decoration: InputDecoration(labelText: l10n.callerName),
                      ),
                      TextField(
                        controller: emoji,
                        decoration: InputDecoration(labelText: l10n.photo),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              );
              if (ok == true)
                await ref
                    .read(appControllerProvider.notifier)
                    .addCaller(name.text, emoji.text);
              name.dispose();
              emoji.dispose();
            },
            child: premiumLabel(l10n.addCaller, locked: !app.premium),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.callLater,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          for (final call in app.scheduledCalls.where((item) => !item.fired))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(formatHm(call.fireAt)),
              subtitle: Text(_name(app.callers, call.callerId)),
              trailing: TextButton(
                onPressed: () => ref
                    .read(appControllerProvider.notifier)
                    .cancelFakeCall(call.id),
                child: Text(l10n.cancel),
              ),
            ),
        ],
      ),
    );
  }

  String _name(List<Caller> callers, String id) {
    for (final caller in callers) {
      if (caller.id == id) return caller.name;
    }
    return '';
  }
}

class _CallerTile extends ConsumerWidget {
  const _CallerTile({required this.caller});
  final Caller caller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final premium = ref.watch(
      appControllerProvider.select((state) => state.premium),
    );
    return PopCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          _Avatar(caller: caller),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              caller.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(
            onPressed: () => ref
                .read(appControllerProvider.notifier)
                .startFakeCall(caller.id),
            child: Text(l10n.callNow),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: TickColors.ink),
            onSelected: (value) => _act(context, ref, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'later',
                child: premiumLabel(l10n.callLater, locked: !premium),
              ),
              PopupMenuItem(
                value: 'before',
                child: premiumLabel(l10n.callBeforeEnd, locked: !premium),
              ),
              if (caller.custom)
                PopupMenuItem(value: 'photo', child: Text(l10n.photo)),
              if (caller.custom)
                PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _act(BuildContext context, WidgetRef ref, String value) async {
    final notifier = ref.read(appControllerProvider.notifier);
    final premium = ref.read(appControllerProvider).premium;
    if (value == 'later' || value == 'before') {
      if (!premium) {
        showPremiumOffer(context, ref);
        return;
      }
      if (value == 'later') {
        await _schedule(context, ref);
      } else {
        notifier.scheduleBeforeEnd(caller.id);
      }
      return;
    }
    if (value == 'photo') {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
      );
      if (image == null) return;
      await notifier.setCallerPhoto(caller.id, image.path);
      return;
    }
    if (value == 'delete') notifier.deleteCaller(caller.id);
  }

  Future<void> _schedule(BuildContext context, WidgetRef ref) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: DateTime.now(),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(minutes: 5)),
      ),
    );
    if (time == null) return;
    final when = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    ref.read(appControllerProvider.notifier).scheduleFakeCall(caller.id, when);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.caller, this.radius = 18});
  final Caller caller;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final path = caller.photoPath;
    if (path != null && File(path).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(path)),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE8D4DA),
      child: Text(caller.emoji, style: TextStyle(fontSize: radius * 0.9)),
    );
  }
}

class IncomingPage extends ConsumerWidget {
  const IncomingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final call = ref.watch(
      appControllerProvider.select((state) => state.liveCall),
    );
    final caller = call?.caller;
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final gradient = dark
        ? const [
            Color(0xFF1A1218),
            Color(0xFF2C1F28),
            Color(0xFF151015),
          ]
        : const [
            Color(0xFFD9BFC3),
            Color(0xFFC9A6AD),
            Color(0xFFB88E98),
          ];
    final titleColor = dark ? Colors.white : const Color(0xFF1C1C1E);
    final subtle = dark ? Colors.white70 : const Color(0xFF3C3C43);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        l10n.incoming,
                        style: TextStyle(
                          color: subtle.withValues(alpha: 0.85),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    if (caller != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Avatar(caller: caller, radius: 42),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'iPhone',
                                    style: TextStyle(
                                      color: subtle,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    caller.name,
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w700,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _IosSecondaryAction(
                          icon: CupertinoIcons.chat_bubble_fill,
                          label: l10n.incomingSendMessage,
                          onDark: dark,
                          onTap: () {},
                        ),
                        _IosSecondaryAction(
                          icon: CupertinoIcons.recordingtape,
                          label: l10n.incomingVoicemail,
                          onDark: dark,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 44),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _IosCallButton(
                            color: const Color(0xFFFF3B30),
                            icon: CupertinoIcons.phone_down_fill,
                            label: l10n.decline,
                            onDark: dark,
                            onTap: () => ref
                                .read(appControllerProvider.notifier)
                                .declineCall(),
                          ),
                          _IosCallButton(
                            color: const Color(0xFF34C759),
                            icon: CupertinoIcons.phone_fill,
                            label: l10n.answer,
                            onDark: dark,
                            onTap: () => ref
                                .read(appControllerProvider.notifier)
                                .answerCall(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 4,
                right: 8,
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(
                    CupertinoIcons.info_circle,
                    color: subtle.withValues(alpha: 0.9),
                    size: 22,
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

class _IosSecondaryAction extends StatelessWidget {
  const _IosSecondaryAction({
    required this.icon,
    required this.label,
    required this.onDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool onDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = onDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.12);
    final ink = onDark ? Colors.white : const Color(0xFF1C1C1E);
    return SizedBox(
      width: 128,
      child: Column(
        children: [
          Material(
            color: bg,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 58,
                height: 58,
                child: Icon(icon, color: ink.withValues(alpha: 0.92), size: 26),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink.withValues(alpha: 0.82),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _IosCallButton extends StatelessWidget {
  const _IosCallButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onDark,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final bool onDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final caption = onDark ? Colors.white : const Color(0xFF1C1C1E);
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 74,
              height: 74,
              child: Icon(icon, color: Colors.white, size: 34),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: caption,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class InCallPage extends ConsumerWidget {
  const InCallPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final call = ref.watch(
      appControllerProvider.select((state) => state.liveCall),
    );
    return NowBuilder(
      builder: (context, now) {
        final started = call?.answeredAt ?? now;
        final elapsed = now.difference(started);
        return Scaffold(
          backgroundColor: const Color(0xFF111018),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Text(
                    l10n.inCall,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    call?.caller.name ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    formatHms(elapsed),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (call?.muted ?? false)
                    Text(
                      l10n.muted,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RoundButton(
                        color: Colors.white24,
                        icon: (call?.muted ?? false)
                            ? Icons.mic_off
                            : Icons.mic,
                        label: l10n.mute,
                        onTap: () => ref
                            .read(appControllerProvider.notifier)
                            .toggleMute(),
                      ),
                      _RoundButton(
                        color: const Color(0xFFE14B4B),
                        icon: Icons.call_end,
                        label: l10n.endCall,
                        onTap: () =>
                            ref.read(appControllerProvider.notifier).hangUp(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: CircleAvatar(
            radius: 36,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
