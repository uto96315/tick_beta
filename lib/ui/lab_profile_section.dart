import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/lab/logic.dart';
import 'package:tick/lab/profile.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/lab/lab_widgets.dart';
import 'package:tick/ui/theme.dart';

class LabProfileSection extends ConsumerStatefulWidget {
  const LabProfileSection({super.key});

  @override
  ConsumerState<LabProfileSection> createState() => _LabProfileSectionState();
}

class _LabProfileSectionState extends ConsumerState<LabProfileSection> {
  late final TextEditingController _nick;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _nick = TextEditingController();
  }

  @override
  void dispose() {
    _nick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = ref.watch(appControllerProvider);
    if (_nick.text != app.labNick) {
      _nick.text = app.labNick;
    }
    final uid = app.auth?.uid ?? 'local';
    final hint = labName(uid);
    return PopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.labProfileTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.labProfileHint,
            style: const TextStyle(color: TickColors.muted, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              LabUserAvatar(
                name: app.labDisplayName,
                imageUrl: app.labAvatarUrl.isNotEmpty
                    ? app.labAvatarUrl
                    : (app.labAvatarPath.isNotEmpty
                          ? app.labAvatarPath
                          : null),
                radius: 36,
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickAvatar,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.labProfilePickIcon),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nick,
            maxLength: labNickMax,
            decoration: InputDecoration(
              labelText: l10n.labProfileName,
              hintText: hint,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : _saveNick,
            child: Text(l10n.labProfileSave),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 88,
    );
    if (image == null || !mounted) return;
    setState(() => _busy = true);
    final failure = await ref
        .read(appControllerProvider.notifier)
        .updateLabAvatar(image.path);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      labTell(context, labFailureMessage(AppLocalizations.of(context), failure));
    } else {
      labTell(context, AppLocalizations.of(context).labProfileSaved);
    }
  }

  Future<void> _saveNick() async {
    setState(() => _busy = true);
    final failure = await ref
        .read(appControllerProvider.notifier)
        .updateLabNick(_nick.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      labTell(context, labFailureMessage(AppLocalizations.of(context), failure));
    } else {
      labTell(context, AppLocalizations.of(context).labProfileSaved);
    }
  }
}

class LabUserAvatar extends StatelessWidget {
  const LabUserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 18,
  });

  final String name;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    ImageProvider? photo;
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      photo = url.startsWith('http')
          ? NetworkImage(url)
          : FileImage(File(url));
    }
    final initial = name.isEmpty
        ? '?'
        : String.fromCharCode(name.runes.first);
    return CircleAvatar(
      radius: radius,
      backgroundColor: TickColors.skySoft,
      backgroundImage: photo,
      child: photo == null
          ? Text(
              initial,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.72,
              ),
            )
          : null,
    );
  }
}
