import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tick/domain/fake_call_policy.dart';
import 'package:tick/domain/format.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/theme.dart';
import 'package:tick/ui/visuals.dart';

class CallPage extends ConsumerWidget {
  const CallPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final app = ref.watch(appControllerProvider);
    final used = FakeCallPolicy.usedInWeek(app.credits, DateTime.now());
    return Scaffold(
      appBar: AppBar(title: Text(l10n.fakeCall)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(app.premium ? l10n.unlimited : l10n.weeklyLimit, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('${l10n.usedThisWeek}: $used / ${app.premium ? '∞' : FakeCallPolicy.freeWeeklyLimit}'),
          Text(l10n.weekReset, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          for (final caller in app.callers) _CallerTile(caller: caller),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              if (!app.premium) {
                context.push('/settings/premium');
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
                      TextField(controller: name, decoration: InputDecoration(labelText: l10n.callerName)),
                      TextField(controller: emoji, decoration: InputDecoration(labelText: l10n.photo)),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
                  ],
                ),
              );
              if (ok == true) await ref.read(appControllerProvider.notifier).addCaller(name.text, emoji.text);
              name.dispose();
              emoji.dispose();
            },
            child: Text(l10n.addCaller),
          ),
          if (!app.premium) Text(l10n.premiumCallers, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 16),
          Text(l10n.callLater, style: const TextStyle(fontWeight: FontWeight.w800)),
          for (final call in app.scheduledCalls.where((item) => !item.fired))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(formatHm(call.fireAt)),
              subtitle: Text(_name(app.callers, call.callerId)),
              trailing: TextButton(
                onPressed: () => ref.read(appControllerProvider.notifier).cancelFakeCall(call.id),
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
    return PopCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _Avatar(caller: caller),
        title: Text(caller.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Wrap(
          spacing: 8,
          children: [
            TextButton(onPressed: () => ref.read(appControllerProvider.notifier).startFakeCall(caller.id), child: Text(l10n.callNow)),
            TextButton(onPressed: () => _schedule(context, ref), child: Text(l10n.callLater)),
            if (caller.custom)
              TextButton(onPressed: () => ref.read(appControllerProvider.notifier).deleteCaller(caller.id), child: Text(l10n.delete)),
          ],
        ),
        trailing: IconButton(
          onPressed: () async {
            final image = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
            if (image == null) return;
            await ref.read(appControllerProvider.notifier).setCallerPhoto(caller.id, image.path);
          },
          icon: const Icon(Icons.photo_outlined),
        ),
      ),
    );
  }

  Future<void> _schedule(BuildContext context, WidgetRef ref) async {
    final date = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)), initialDate: DateTime.now());
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 5))));
    if (time == null) return;
    final when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    ref.read(appControllerProvider.notifier).scheduleFakeCall(caller.id, when);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.caller});
  final Caller caller;

  @override
  Widget build(BuildContext context) {
    final path = caller.photoPath;
    if (path != null && File(path).existsSync()) {
      return CircleAvatar(backgroundImage: FileImage(File(path)));
    }
    return CircleAvatar(child: Text(caller.emoji, style: const TextStyle(fontSize: 20)));
  }
}

class IncomingPage extends ConsumerWidget {
  const IncomingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final call = ref.watch(appControllerProvider.select((state) => state.liveCall));
    final caller = call?.caller;
    return Scaffold(
      backgroundColor: const Color(0xFF111018),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 36),
              Text(l10n.incoming, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 28),
              if (caller != null) _Avatar(caller: caller),
              const SizedBox(height: 16),
              Text(caller?.name ?? '', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700)),
              Text(l10n.mobile, style: const TextStyle(color: Colors.white70)),
              Text(l10n.ringing, style: const TextStyle(color: Colors.white38)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RoundButton(color: TickColors.coral, icon: Icons.call_end, label: l10n.decline, onTap: () => ref.read(appControllerProvider.notifier).declineCall()),
                  _RoundButton(color: TickColors.mint, icon: Icons.call, label: l10n.answer, onTap: () => ref.read(appControllerProvider.notifier).answerCall()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InCallPage extends ConsumerWidget {
  const InCallPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final call = ref.watch(appControllerProvider.select((state) => state.liveCall));
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
                  Text(l10n.inCall, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  Text(call?.caller.name ?? '', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)),
                  Text(formatHms(elapsed), style: const TextStyle(color: Colors.white, fontSize: 28, fontFeatures: [FontFeature.tabularFigures()])),
                  if (call?.muted ?? false) Text(l10n.muted, style: const TextStyle(color: Colors.white70)),
                  const Spacer(),
                  const TickMascot(progress: 0.4, size: 120, showFace: false),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RoundButton(
                        color: Colors.white24,
                        icon: (call?.muted ?? false) ? Icons.mic_off : Icons.mic,
                        label: l10n.mute,
                        onTap: () => ref.read(appControllerProvider.notifier).toggleMute(),
                      ),
                      _RoundButton(color: TickColors.coral, icon: Icons.call_end, label: l10n.endCall, onTap: () => ref.read(appControllerProvider.notifier).hangUp()),
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
  const _RoundButton({required this.color, required this.icon, required this.label, required this.onTap});
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
          child: CircleAvatar(radius: 36, backgroundColor: color, child: Icon(icon, color: Colors.white, size: 30)),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
