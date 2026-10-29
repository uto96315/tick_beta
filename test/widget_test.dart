import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tick/app.dart';
import 'package:tick/data/local_store.dart';
import 'package:tick/data/persisted_state.dart';
import 'package:tick/domain/app_update.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/domain/segments.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/services/gateways.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/copy.dart';
import 'package:tick/ui/interval_choices.dart';
import 'package:tick/ui/update_gate.dart';
import 'package:tick/ui/theme.dart';
import 'package:tick/ui/visuals.dart';

void main() {
  test('timer pose follows breaks, the end, and how far the day has gone', () {
    expect(timerPose(ratio: 0.2, remaining: 20, onBreak: true, pastShift: false), ChickPose.sleep);
    expect(timerPose(ratio: 1, remaining: 0, onBreak: false, pastShift: true), ChickPose.done);
    expect(timerPose(ratio: 0.5, remaining: 10, onBreak: false, pastShift: true), ChickPose.surprise);
    expect(timerPose(ratio: 0.8, remaining: 2, onBreak: false, pastShift: false), ChickPose.attention);
    expect(timerPose(ratio: 0.6, remaining: 10, onBreak: false, pastShift: false), ChickPose.cheer);
    expect(timerPose(ratio: 0.3, remaining: 10, onBreak: false, pastShift: false), ChickPose.happy);
    expect(timerPose(ratio: 0.1, remaining: 20, onBreak: false, pastShift: false), ChickPose.tired);
  });

  testWidgets('finished chunks show a check on the tile board', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SegmentBoard(
            views: [
              SegmentView(done: true, current: false, fraction: 1),
              SegmentView(done: false, current: true, fraction: 0.4),
            ],
            visual: TimerVisual.tiles,
            showCharacter: false,
            progress: 0.5,
            labels: ['9:00', '9:15'],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('9:15'), findsOneWidget);
    expect(find.text('9:00'), findsOneWidget);
  });

  testWidgets('chunks in one hour sit beside that hour', (tester) async {
    final hour = DateTime(2026, 10, 28, 12);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SegmentBoard(
            views: [
              for (final minute in [0, 15, 30, 45, 0])
                SegmentView(done: minute == 0 && minute == 0, current: minute == 15, fraction: minute == 15 ? 0.4 : minute < 15 ? 1 : 0),
            ],
            visual: TimerVisual.tiles,
            showCharacter: false,
            progress: 0.2,
            starts: [
              hour,
              hour.add(const Duration(minutes: 15)),
              hour.add(const Duration(minutes: 30)),
              hour.add(const Duration(minutes: 45)),
              hour.add(const Duration(hours: 1)),
            ],
            intervalMinutes: 15,
          ),
        ),
      ),
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.text('13'), findsOneWidget);
    expect(find.text(':15'), findsOneWidget);
    expect(find.text(':00'), findsNWidgets(2));
  });

  testWidgets('a list tile inside a card keeps its ink splash', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PopCard(
            child: ListTile(title: const Text('shift'), onTap: () {}),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('dark interval choices keep the other labels readable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          backgroundColor: TickColors.navy,
          body: IntervalChoices(minutes: 15, onDark: true, onPreset: (_) {}, onCustom: () {}),
        ),
      ),
    );

    expect(find.text('15分'), findsOneWidget);
    expect(find.text('30分'), findsOneWidget);
    expect(find.text('1時間'), findsOneWidget);
    expect(find.text('任意'), findsOneWidget);
    final unselected = tester.widget<Text>(find.text('30分'));
    expect(unselected.style?.color, Colors.white);
  });

  testWidgets('hour progress names the hour and the minute', (tester) async {
    final hour = DateTime(2026, 10, 28, 13);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HourProgress(
            views: const [
              SegmentView(done: true, current: false, fraction: 1),
              SegmentView(done: false, current: true, fraction: 0.4),
            ],
            starts: [hour, hour.add(const Duration(minutes: 15))],
          ),
        ),
      ),
    );

    expect(find.text('13'), findsOneWidget);
    expect(find.text(':00'), findsOneWidget);
    expect(find.text(':15'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('the current hour stays above finished hours', (tester) async {
    final noon = DateTime(2026, 10, 28, 12);
    final one = DateTime(2026, 10, 28, 13);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HourProgress(
            views: const [
              SegmentView(done: true, current: false, fraction: 1),
              SegmentView(done: false, current: true, fraction: 0.2),
            ],
            starts: [noon, one],
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.text('13')).dy, lessThan(tester.getTopLeft(find.text('12')).dy));
  });

  testWidgets('a break slot is not a work check', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HourProgress(
            views: const [SegmentView(done: true, current: false, fraction: 1)],
            starts: [DateTime(2026, 10, 28, 12)],
            breaks: const [true],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.coffee_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('settings opens from the corner and there is no tab bar', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.localeTestValue = const Locale('ja');
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearLocaleTestValue();
    });
    final persisted = PersistedState.seed(languageCode: 'ja');
    persisted.settings = persisted.settings.copyWith(tutorialSeen: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [depsProvider.overrideWithValue(_testDeps(persisted))],
        child: const TickApp(),
      ),
    );
    await tester.pump();

    final shown = AppLocalizations.of(tester.element(find.text('Ozio')));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text(shown.appTitle), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.text(shown.schedule), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('an old build is blocked until the required update', (tester) async {
    await _pumpApp(
      tester,
      updates: const _FixedUpdates(UpdatePolicy(minBuild: 9, latestBuild: 9, url: 'https://example.com/tick')),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(UpdateGate)));
    expect(find.text(l10n.updateRequiredTitle), findsOneWidget);
    expect(find.text(l10n.updateLater), findsNothing);

    await tester.tapAt(tester.getCenter(find.byIcon(Icons.settings_outlined)));
    await tester.pump();
    expect(find.text(l10n.updateRequiredTitle), findsOneWidget);
    expect(find.text(l10n.schedule), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('a newer build can be postponed', (tester) async {
    await _pumpApp(
      tester,
      updates: const _FixedUpdates(UpdatePolicy(minBuild: 0, latestBuild: 9, url: 'https://example.com/tick')),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(UpdateGate)));
    expect(find.text(l10n.updateAvailableTitle), findsOneWidget);

    await tester.tap(find.text(l10n.updateLater));
    await tester.pump();
    expect(find.text(l10n.updateAvailableTitle), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.updateAvailableTitle), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('the chick says another line after a moment', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ja'));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChickTalk(lines: chickLines(l10n, ChickPose.tired), onDark: true),
        ),
      ),
    );

    expect(find.text(l10n.chickTired1), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.chickTired2), findsOneWidget);

    for (final pose in ChickPose.values) {
      expect(chickLines(l10n, pose), hasLength(3));
    }
    expect(chickLines(l10n, ChickPose.tired, voice: ChickVoice.kansai).first, l10n.voiceKansai1);
    expect(chickLines(l10n, ChickPose.tired, voice: ChickVoice.custom, custom: '  ねむい  '), ['ねむい']);
    expect(moodLines(l10n, ChickMood.sleepy), hasLength(3));
    expect(moodPose(ChickMood.sleepy), ChickPose.sleep);
  });
}

Future<void> _pumpApp(WidgetTester tester, {required UpdatePolicySource updates}) async {
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final persisted = PersistedState.seed(languageCode: 'ja');
  persisted.settings = persisted.settings.copyWith(tutorialSeen: true);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [depsProvider.overrideWithValue(_testDeps(persisted, updates: updates))],
      child: const TickApp(),
    ),
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

class _FixedUpdates implements UpdatePolicySource {
  const _FixedUpdates(this.policy);

  final UpdatePolicy policy;

  @override
  Future<UpdatePolicy?> load() async => policy;
}

AppDeps _testDeps(PersistedState persisted, {UpdatePolicySource? updates}) {
  return AppDeps(
    store: LocalStore(persisted),
    auth: LocalAuthGateway(const AuthUser(uid: 'local', anonymous: true, email: null, provider: 'local')),
    sync: NoopSync(),
    notifications: NoopNotifications(),
    purchases: UnavailablePurchases(),
    ringtone: NoopRingtone(),
    clock: SystemClock(),
    firebaseConfigured: false,
    newId: () => 'id',
    languageCode: () => 'ja',
    savePhoto: (_, _) async => null,
    installedBuild: 2,
    updates: updates ?? const UnavailableUpdates(),
  );
}
