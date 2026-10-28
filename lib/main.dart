import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/app.dart';
import 'package:tick/services/app_deps.dart';
import 'package:tick/state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final deps = await loadAppDeps();
  runApp(ProviderScope(overrides: [depsProvider.overrideWithValue(deps)], child: const TickApp()));
}
