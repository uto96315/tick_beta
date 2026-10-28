import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:tick/data/persisted_state.dart';

class LocalStore {
  LocalStore(this.state, {this.file});

  PersistedState state;
  final File? file;
  Future<void> _queue = Future<void>.value();

  Future<void> save() {
    _queue = _queue.then((_) => _write());
    return _queue;
  }

  Future<void> _write() async {
    final target = file;
    if (target == null) return;
    final temp = File('${target.path}.tmp');
    await temp.writeAsString(jsonEncode(state.toJson()));
    if (await target.exists()) await target.delete();
    await temp.rename(target.path);
  }

  static Future<LocalStore> open() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/tick_store.json');
    if (!await file.exists()) {
      final language = Platform.localeName.toLowerCase().startsWith('ja') ? 'ja' : 'en';
      final store = LocalStore(PersistedState.seed(languageCode: language), file: file);
      await store.save();
      return store;
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      final store = LocalStore(PersistedState.seed(languageCode: 'en'), file: file);
      await store.save();
      return store;
    }
    return LocalStore(PersistedState.fromJson(decoded.cast<String, dynamic>()), file: file);
  }
}
