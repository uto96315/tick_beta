import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/copy.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = ref.watch(appControllerProvider);
    final auth = app.auth;
    final anonymous = auth == null || auth.anonymous || auth.provider == 'local';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.account)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(anonymous ? l10n.anonymous : l10n.registered, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          if (auth?.email != null) Text(auth!.email!),
          const SizedBox(height: 8),
          Text(l10n.linkKeeps),
          Text(l10n.anonymousLoss),
          Text(l10n.switchHelp),
          if (!app.firebaseConfigured) ...[
            const SizedBox(height: 8),
            Text(l10n.firebaseLocal),
          ],
          const SizedBox(height: 16),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: l10n.email)),
          const SizedBox(height: 8),
          TextField(controller: _password, obscureText: true, decoration: InputDecoration(labelText: l10n.password, hintText: l10n.passwordHint)),
          const SizedBox(height: 12),
          FilledButton(onPressed: _busy ? null : () => _run(() => ref.read(appControllerProvider.notifier).registerEmail(_email.text, _password.text)), child: Text(l10n.registerEmail)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _busy ? null : () => _run(() => ref.read(appControllerProvider.notifier).signInEmail(_email.text, _password.text)), child: Text(l10n.signInEmail)),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: _busy ? null : () => _run(() => ref.read(appControllerProvider.notifier).registerGoogle()), child: Text(l10n.registerGoogle)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _busy ? null : () => _run(() => ref.read(appControllerProvider.notifier).signInGoogle()), child: Text(l10n.signInGoogle)),
          const SizedBox(height: 8),
          Text(l10n.googleMissing, style: const TextStyle(fontSize: 13)),
          if (!anonymous) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: _busy ? null : () => _run(() => ref.read(appControllerProvider.notifier).signOut()), child: Text(l10n.signOut)),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.deleteAccount),
                        content: Text(l10n.deleteAccountBody),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
                        ],
                      ),
                    );
                    if (ok == true) await _run(() => ref.read(appControllerProvider.notifier).deleteAccount());
                  },
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
  }

  Future<void> _run(Future<String?> Function() action) async {
    setState(() => _busy = true);
    final code = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (code != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authText(AppLocalizations.of(context), code))));
    }
  }
}
