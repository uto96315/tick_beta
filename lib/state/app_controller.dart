import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/data/persisted_state.dart';
import 'package:tick/domain/engine.dart';
import 'package:tick/domain/fake_call_policy.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/domain/schedule.dart';
import 'package:tick/domain/session_ops.dart';
import 'package:tick/services/gateways.dart';
import 'package:tick/services/notification_copy.dart';
import 'package:tick/state/app_state.dart';

final depsProvider = Provider<AppDeps>(
  (ref) => throw StateError('AppDeps is not installed'),
);

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

class AppController extends Notifier<AppState> {
  late AppDeps _deps;
  late PersistedState _db;
  Timer? _timer;
  Timer? _syncTimer;
  var _booted = false;
  var _foreground = true;
  DateTime? _lastForegroundTick;
  AuthUser? _auth;
  ResolvedShift? _prompt;
  LiveCall? _live;
  var _camouflage = false;
  ChickMood? _mood;
  var _offline = false;
  var _burstCount = 0;
  var _burstNonce = 0;
  var _encourageIndex = 0;
  var _encourageNonce = 0;
  Flash? _flash;
  var _flashNonce = 0;

  @override
  AppState build() {
    _deps = ref.read(depsProvider);
    _db = _deps.store.state;
    _auth = _deps.auth.current;
    ref.onDispose(_dispose);
    Future<void>.microtask(_start);
    return _view();
  }

  Future<void> _start() async {
    if (_booted) return;
    _booted = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _applyTick());
    await _deps.notifications.init(onTap: _onNotification);
    await _deps.purchases.init(onPurchased: _markPremium);
    if (!ref.mounted) return;
    try {
      final user = await _deps.auth.ensureSignedIn();
      if (!ref.mounted) return;
      await _bindUser(user);
    } catch (error) {
      debugPrint('auth skipped: $error');
      _offline = true;
      _db.uid ??= 'local';
    }
    if (!ref.mounted) return;
    _restoreRing();
    _applyTick();
    await _reschedule();
    _emit();
  }

  void _dispose() {
    _timer?.cancel();
    _syncTimer?.cancel();
    unawaited(_deps.ringtone.stop());
  }

  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    if (!value) {
      _lastForegroundTick = null;
      return;
    }
    _lastForegroundTick = null;
    _applyTick();
    unawaited(_syncNow());
  }

  void startManual({
    required DateTime plannedEnd,
    required int intervalMinutes,
    DateTime? anchorStart,
    DateTime? originalPlannedEnd,
    String? shiftKey,
    String? patternId,
    List<TimeRange> breaks = const [],
  }) {
    if (_db.session != null) return;
    final now = _deps.clock.now();
    final start = anchorStart ?? now;
    if (!plannedEnd.isAfter(start.add(const Duration(seconds: 59)))) {
      _flashCode('too-short');
      return;
    }
    final interval = intervalMinutes.clamp(1, 240);
    _db.session = buildSession(
      SessionDraft(
        id: _deps.newId(),
        now: now,
        actualStart: start,
        plannedEnd: plannedEnd,
        originalPlannedEnd: originalPlannedEnd ?? plannedEnd,
        intervalMinutes: interval,
        breaks: breaks,
        patternId: patternId,
        shiftKey: shiftKey,
        celebrateElapsed: false,
      ),
    );
    _db.settings = _db.settings.copyWith(
      lastIntervalMinutes: interval,
      updatedAt: now,
    );
    _db.pendingFreedom = false;
    _db.bumpRuntime(now);
    _prompt = null;
    _commit();
  }

  void acceptPrompt() {
    final shift = _prompt;
    if (shift == null || _db.session != null) return;
    _prompt = null;
    _startShift(shift);
  }

  void dismissPrompt() {
    final shift = _prompt;
    if (shift == null) return;
    _prompt = null;
    _db.dismissedShiftKey = shift.key;
    _db.bumpRuntime(_deps.clock.now());
    _commit();
  }

  void setInterval(int minutes) {
    final interval = minutes.clamp(1, 240);
    final session = _db.session;
    if (session?.intervalMinutes == interval &&
        _db.settings.lastIntervalMinutes == interval)
      return;
    final now = _deps.clock.now();
    if (session != null && session.intervalMinutes != interval) {
      _db.session = changeInterval(session, interval, now);
      _db.bumpRuntime(now);
    }
    _db.settings = _db.settings.copyWith(
      lastIntervalMinutes: interval,
      updatedAt: now,
    );
    _commit();
  }

  void extendBy(int minutes) {
    final session = _db.session;
    if (session == null) return;
    final amount = minutes.clamp(1, 360);
    final now = _deps.clock.now();
    _db.session = extendSession(session, amount, now);
    _db.bumpRuntime(now);
    _encourageIndex = _db.session!.extensions.length - 1;
    _encourageNonce++;
    _commit();
  }

  void endEarly() {
    final session = _db.session;
    if (session == null) return;
    final now = _deps.clock.now();
    final record = finishSession(session, now, EndStatus.early);
    _db.history = [record, ..._db.history];
    _closeSession(now, freedom: false);
    _flashCode('early');
    _commit();
  }

  void acknowledgeFreedom() {
    if (!_db.pendingFreedom) return;
    _db.pendingFreedom = false;
    _db.bumpRuntime(_deps.clock.now());
    _commit();
  }

  void setMemo(String recordId, String memo) {
    final now = _deps.clock.now();
    final session = _db.session;
    if (session != null && session.id == recordId) {
      _db.session = session.copyWith(memo: memo, updatedAt: now);
      _db.bumpRuntime(now);
    }
    final index = _db.history.indexWhere((item) => item.id == recordId);
    if (index >= 0) {
      _db.history[index] = _db.history[index].copyWith(
        memo: memo,
        updatedAt: now,
      );
    }
    _commit();
  }

  void addSessionBreak() => _addBreak(onSession: true, recordId: null);

  void updateSessionBreak(
    String breakId, {
    DateTime? start,
    DateTime? end,
    Duration? duration,
  }) {
    final session = _db.session;
    if (session == null) return;
    final now = _deps.clock.now();
    _db.session = session.copyWith(
      breaks: [
        for (final span in session.breaks)
          if (span.id == breakId)
            _editSpan(span, start: start, end: end, duration: duration)
          else
            span,
      ],
      updatedAt: now,
    );
    _db.bumpRuntime(now);
    _commit();
  }

  void removeSessionBreak(String breakId) {
    final session = _db.session;
    if (session == null) return;
    final now = _deps.clock.now();
    _db.session = session.copyWith(
      breaks: [
        for (final span in session.breaks)
          if (span.id != breakId) span,
      ],
      updatedAt: now,
    );
    _db.bumpRuntime(now);
    _commit();
  }

  void addHistoryBreak(String recordId) =>
      _addBreak(onSession: false, recordId: recordId);

  void updateHistoryBreak(
    String recordId,
    String breakId, {
    DateTime? start,
    DateTime? end,
    Duration? duration,
  }) {
    final index = _db.history.indexWhere((item) => item.id == recordId);
    if (index < 0) return;
    final record = _db.history[index];
    _db.history[index] = record.copyWith(
      breaks: [
        for (final span in record.breaks)
          if (span.id == breakId)
            _editSpan(span, start: start, end: end, duration: duration)
          else
            span,
      ],
      updatedAt: _deps.clock.now(),
    );
    _commit();
  }

  void removeHistoryBreak(String recordId, String breakId) {
    final index = _db.history.indexWhere((item) => item.id == recordId);
    if (index < 0) return;
    final record = _db.history[index];
    _db.history[index] = record.copyWith(
      breaks: [
        for (final span in record.breaks)
          if (span.id != breakId) span,
      ],
      updatedAt: _deps.clock.now(),
    );
    _commit();
  }

  void completeTutorial() {
    if (_db.settings.tutorialSeen) return;
    updateSettings(_db.settings.copyWith(tutorialSeen: true));
  }

  void updateSettings(AppSettings settings) {
    _db.settings = settings.copyWith(updatedAt: _deps.clock.now());
    _commit();
  }

  void setCamouflage(bool value) {
    _camouflage = value;
    _emit();
  }

  void setMood(ChickMood mood) {
    _mood = mood;
    if (_db.settings.notifyVibration) HapticFeedback.lightImpact();
    _emit();
  }

  void callFromMood() {
    slackCall();
  }

  void slackCall() {
    Caller? caller;
    for (final item in _db.callers) {
      if (_premium || !item.custom) {
        caller = item;
        break;
      }
    }
    if (caller == null) {
      if (_db.callers.isNotEmpty) _flashCode('premium');
      return;
    }
    startFakeCall(caller.id);
  }

  void scheduleBeforeEnd(String callerId) {
    if (!_premium) {
      _flashCode('premium');
      return;
    }
    final end = _callAnchor();
    if (end == null) return;
    final when = end.subtract(const Duration(minutes: 10));
    if (!when.isAfter(_deps.clock.now())) {
      _flashCode('passed');
      return;
    }
    scheduleFakeCall(callerId, when);
  }

  DateTime? _callAnchor() {
    final session = _db.session;
    if (session != null) return session.originalPlannedEnd;
    final now = _deps.clock.now();
    final calendar = ScheduleCalendar(
      patterns: _db.patterns,
      week: _db.week,
      overrides: _db.overrides,
    );
    return (calendar.shiftCovering(now) ?? calendar.upcomingOn(now))?.end;
  }

  void upsertPattern(WorkPattern pattern) {
    final now = _deps.clock.now();
    final next = pattern.copyWith(updatedAt: now);
    final index = _db.patterns.indexWhere((item) => item.id == pattern.id);
    if (index >= 0) {
      _db.patterns[index] = next;
    } else {
      _db.patterns = [..._db.patterns, next];
    }
    _resyncLiveShift(now);
    _commit();
  }

  void deletePattern(String id) {
    final now = _deps.clock.now();
    _db.removeWhere('patterns', id, now);
    final days = Map<int, String?>.from(_db.week.days)
      ..removeWhere((_, value) => value == id);
    _db.week = _db.week.copyWith(days: days, updatedAt: now);
    _commit();
  }

  void assignWeekday(int weekday, String? patternId) {
    final days = Map<int, String?>.from(_db.week.days);
    if (patternId == null) {
      days.remove(weekday);
    } else {
      days[weekday] = patternId;
    }
    _db.week = _db.week.copyWith(days: days, updatedAt: _deps.clock.now());
    _commit();
  }

  void upsertOverride(DateOverride override) {
    final now = _deps.clock.now();
    final next = DateOverride(
      id: override.id,
      date: override.date,
      holiday: override.holiday,
      name: override.name,
      start: override.start,
      end: override.end,
      breaks: override.breaks,
      updatedAt: now,
    );
    final index = _db.overrides.indexWhere((item) => item.id == override.id);
    if (index >= 0) {
      _db.overrides[index] = next;
    } else {
      _db.overrides = [..._db.overrides, next];
    }
    _commit();
  }

  void deleteOverride(String id) {
    _db.removeWhere('overrides', id, _deps.clock.now());
    _commit();
  }

  void startFakeCall(String callerId) {
    final caller = _findCaller(callerId);
    if (caller == null) return;
    if (caller.custom && !_premium) {
      _flashCode('premium');
      return;
    }
    final now = _deps.clock.now();
    if (!FakeCallPolicy.canConsume(
      premium: _premium,
      credits: _db.credits,
      when: now,
    )) {
      _flashCode('limit');
      return;
    }
    _consumeCredit(now);
    _beginRing(caller, now);
    _commit();
  }

  void scheduleFakeCall(String callerId, DateTime when) {
    final caller = _findCaller(callerId);
    if (caller == null) return;
    if (caller.custom && !_premium) {
      _flashCode('premium');
      return;
    }
    final now = _deps.clock.now();
    if (!when.isAfter(now)) {
      startFakeCall(callerId);
      return;
    }
    if (!FakeCallPolicy.canConsume(
      premium: _premium,
      credits: _db.credits,
      when: when,
    )) {
      _flashCode('limit');
      return;
    }
    final id = _deps.newId();
    _db.scheduledCalls = [
      ..._db.scheduledCalls,
      ScheduledFakeCall(
        id: id,
        callerId: callerId,
        fireAt: when,
        fired: false,
        updatedAt: now,
      ),
    ];
    _db.credits = [
      ..._db.credits,
      CallCredit(id: id, when: when, canceled: false, updatedAt: now),
    ];
    _flashCode('scheduled', _hm(when));
    _commit();
  }

  void cancelFakeCall(String id) {
    final now = _deps.clock.now();
    ScheduledFakeCall? call;
    for (final item in _db.scheduledCalls) {
      if (item.id == id) call = item;
    }
    if (call == null || call.fired) return;
    _db.removeWhere('calls', id, now);
    _db.credits = [
      for (final credit in _db.credits)
        if (credit.id == id)
          credit.copyWith(canceled: true, updatedAt: now)
        else
          credit,
    ];
    _commit();
  }

  void answerCall() {
    final live = _live;
    if (live == null) return;
    _live = live.copyWith(answered: true, answeredAt: _deps.clock.now());
    _db.ringingCallerId = null;
    unawaited(_deps.ringtone.stop());
    unawaited(_save());
    _emit();
  }

  void declineCall() => _endCall();

  void hangUp() => _endCall();

  void toggleMute() {
    final live = _live;
    if (live == null) return;
    _live = live.copyWith(muted: !live.muted);
    _emit();
  }

  Future<void> addCaller(String name, String emoji) async {
    if (!_premium) {
      _flashCode('premium');
      return;
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _flashCode('name');
      return;
    }
    final now = _deps.clock.now();
    _db.callers = [
      ..._db.callers,
      Caller(
        id: _deps.newId(),
        name: trimmed,
        emoji: emoji.isEmpty ? '📞' : emoji,
        presetKey: null,
        photoPath: null,
        updatedAt: now,
      ),
    ];
    _commit();
  }

  Future<void> setCallerPhoto(String id, String sourcePath) async {
    if (!_premium) {
      _flashCode('premium');
      return;
    }
    final saved = await _deps.savePhoto(id, sourcePath);
    if (!ref.mounted || saved == null) return;
    final now = _deps.clock.now();
    _db.callers = [
      for (final caller in _db.callers)
        if (caller.id == id)
          caller.copyWith(photoPath: saved, updatedAt: now)
        else
          caller,
    ];
    _commit();
  }

  void deleteCaller(String id) {
    final caller = _findCaller(id);
    if (caller == null || !caller.custom) return;
    _db.removeWhere('callers', id, _deps.clock.now());
    _commit();
  }

  Future<String?> registerEmail(String email, String password) {
    return _authCall(
      () => _deps.auth.registerEmail(email: email, password: password),
    );
  }

  Future<String?> signInEmail(String email, String password) {
    return _authCall(
      () => _deps.auth.signInEmail(email: email, password: password),
    );
  }

  Future<String?> registerGoogle() => _authCall(_deps.auth.registerGoogle);

  Future<String?> signInGoogle() => _authCall(_deps.auth.signInGoogle);

  Future<String?> signOut() async {
    try {
      await _deps.auth.signOut();
      final user = await _deps.auth.ensureSignedIn();
      if (!ref.mounted) return null;
      await _bindUser(user);
      return null;
    } on AuthFlowException catch (error) {
      return error.code;
    }
  }

  Future<String?> deleteAccount() async {
    final uid = _db.uid;
    try {
      await _deps.auth.deleteAccount();
      if (uid != null && _deps.firebaseConfigured) {
        try {
          await _deps.sync.deleteUser(uid);
        } catch (error) {
          debugPrint('remote delete failed: $error');
        }
      }
      final user = await _deps.auth.ensureSignedIn();
      if (!ref.mounted) return null;
      _db = PersistedState.seed(
        languageCode: _deps.languageCode(),
        uid: user.uid,
        now: _deps.clock.now(),
      );
      _auth = user;
      _deps.store.state = _db;
      _prompt = null;
      _live = null;
      _camouflage = false;
      await _deps.ringtone.stop();
      await _save();
      _scheduleSync();
      await _reschedule();
      _emit();
      return null;
    } on AuthFlowException catch (error) {
      return error.code;
    }
  }

  Future<String?> buyPremium() async {
    try {
      await _deps.purchases.buy();
      return null;
    } on AuthFlowException catch (error) {
      return error.code;
    }
  }

  Future<String?> restorePremium() async {
    try {
      await _deps.purchases.restore();
      return null;
    } on AuthFlowException catch (error) {
      return error.code;
    }
  }

  Future<String?> priceLabel() => _deps.purchases.priceLabel();

  bool get premium => _db.entitlement.premium;

  void _resyncLiveShift(DateTime now) {
    final session = _db.session;
    final patternId = session?.patternId;
    if (session == null || patternId == null) return;
    final shift = ScheduleCalendar(
      patterns: _db.patterns,
      week: _db.week,
      overrides: _db.overrides,
    ).shiftStartingOn(session.workDate);
    if (shift == null || shift.patternId != patternId) return;
    final aligned = realignSession(session, shift, now);
    final sameBreaks =
        aligned.breaks.length == session.breaks.length &&
        [
          for (var i = 0; i < aligned.breaks.length; i++)
            aligned.breaks[i].start == session.breaks[i].start &&
                aligned.breaks[i].end == session.breaks[i].end,
        ].every((same) => same);
    if (aligned.actualStart == session.actualStart &&
        aligned.plannedEnd == session.plannedEnd &&
        aligned.originalPlannedEnd == session.originalPlannedEnd &&
        sameBreaks)
      return;
    _db.session = aligned;
    _db.bumpRuntime(now);
  }

  void _startShift(ResolvedShift shift) {
    final now = _deps.clock.now();
    _db.session = buildSession(
      SessionDraft(
        id: _deps.newId(),
        now: now,
        actualStart: shift.start,
        plannedEnd: shift.end,
        originalPlannedEnd: shift.end,
        intervalMinutes: _db.settings.lastIntervalMinutes,
        breaks: shift.breaks,
        patternId: shift.patternId,
        shiftKey: shift.key,
        celebrateElapsed: false,
      ),
    );
    _db.pendingFreedom = false;
    _db.bumpRuntime(now);
    _commit();
  }

  void _applyTick() {
    if (!_booted) return;
    final now = _deps.clock.now();
    final commands = planTick(
      now: now,
      foreground: _foreground,
      lastForegroundTick: _lastForegroundTick,
      session: _db.session,
      calendar: ScheduleCalendar(
        patterns: _db.patterns,
        week: _db.week,
        overrides: _db.overrides,
      ),
      autoStart: _db.settings.autoStart,
      dismissedShiftKey: _db.dismissedShiftKey,
      history: _db.history,
      currentPrompt: _prompt,
      calls: _db.scheduledCalls,
      callInProgress: _live != null,
    );
    if (_foreground) _lastForegroundTick = now;
    if (commands.isEmpty) return;
    for (final command in commands) {
      _apply(command, now);
    }
    _commit();
  }

  void _apply(TickCommand command, DateTime now) {
    switch (command) {
      case FireFakeCall(:final callId):
        _ringScheduled(callId, now);
      case CompleteSession(:final at):
        final session = _db.session;
        if (session == null) return;
        final record = finishSession(session, at, EndStatus.completed);
        _db.history = [record, ..._db.history];
        _closeSession(now, freedom: true, historyId: record.id);
      case CelebrateSegments(:final completed):
        final session = _db.session;
        if (session == null) return;
        final gained = completed - session.celebratedCount;
        _db.session = session.copyWith(
          celebratedCount: completed,
          updatedAt: now,
        );
        _db.bumpRuntime(now);
        if (gained > 0) {
          _burstCount = gained;
          _burstNonce++;
          if (_db.settings.notifyVibration) HapticFeedback.mediumImpact();
        }
      case AutoStartShift(:final shift):
        _prompt = null;
        _startShift(shift);
      case AskStartShift(:final shift):
        _prompt = shift;
    }
  }

  void _closeSession(DateTime now, {required bool freedom, String? historyId}) {
    _mood = null;
    _db.session = null;
    _db.sessionClearedAt = now;
    _db.pendingFreedom = freedom;
    if (freedom) _db.freedomHistoryId = historyId;
    _db.bumpRuntime(now);
  }

  void _ringScheduled(String id, DateTime now) {
    if (_live != null) return;
    final index = _db.scheduledCalls.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final call = _db.scheduledCalls[index];
    final caller = _findCaller(call.callerId);
    if (caller == null) return;
    _db.scheduledCalls[index] = call.copyWith(fired: true, updatedAt: now);
    _beginRing(caller, now);
  }

  void _beginRing(Caller caller, DateTime now) {
    _live = LiveCall(
      caller: caller,
      startedAt: now,
      answered: false,
      answeredAt: null,
      muted: false,
    );
    _db.ringingCallerId = caller.id;
    _camouflage = false;
    if (_db.settings.notifySound) {
      unawaited(
        _deps.ringtone.start(
          sound: shownSound(_premium, _db.settings.callSound).name,
        ),
      );
    }
    if (_db.settings.notifyVibration) HapticFeedback.mediumImpact();
  }

  void _restoreRing() {
    final id = _db.ringingCallerId;
    if (id == null || _live != null) return;
    final caller = _findCaller(id);
    if (caller == null) return;
    _beginRing(caller, _deps.clock.now());
  }

  void _endCall() {
    _live = null;
    _db.ringingCallerId = null;
    unawaited(_deps.ringtone.stop());
    unawaited(_save());
    _emit();
  }

  void _consumeCredit(DateTime when) {
    _db.credits = [
      ..._db.credits,
      CallCredit(
        id: _deps.newId(),
        when: when,
        canceled: false,
        updatedAt: when,
      ),
    ];
  }

  void _addBreak({required bool onSession, required String? recordId}) {
    final now = _deps.clock.now();
    final span = BreakSpan(
      id: _deps.newId(),
      start: now,
      end: now.add(const Duration(minutes: 15)),
      updatedAt: now,
    );
    if (onSession) {
      final session = _db.session;
      if (session == null) return;
      _db.session = session.copyWith(
        breaks: [...session.breaks, span],
        updatedAt: now,
      );
      _db.bumpRuntime(now);
    } else if (recordId != null) {
      final index = _db.history.indexWhere((item) => item.id == recordId);
      if (index < 0) return;
      final record = _db.history[index];
      _db.history[index] = record.copyWith(
        breaks: [...record.breaks, span],
        updatedAt: now,
      );
    }
    _commit();
  }

  BreakSpan _editSpan(
    BreakSpan span, {
    DateTime? start,
    DateTime? end,
    Duration? duration,
  }) {
    final now = _deps.clock.now();
    if (duration != null) {
      return withDuration(
        span.copyWith(start: start ?? span.start),
        duration,
        now,
      );
    }
    final nextStart = start ?? span.start;
    final nextEnd = end ?? span.end;
    final safeEnd = nextEnd.isAfter(nextStart)
        ? nextEnd
        : nextStart.add(const Duration(minutes: 1));
    return span.copyWith(start: nextStart, end: safeEnd, updatedAt: now);
  }

  Future<void> _bindUser(AuthUser user) async {
    _auth = user;
    if (_db.uid == null || _db.uid == user.uid) {
      _db.uid ??= user.uid;
      _deps.store.state = _db;
      await _save();
      await _syncNow();
      return;
    }
    _db = PersistedState.blank(uid: user.uid);
    _deps.store.state = _db;
    _prompt = null;
    _live = null;
    await _deps.ringtone.stop();
    await _save();
    await _syncNow();
    _emit();
  }

  Future<String?> _authCall(Future<AuthUser> Function() action) async {
    try {
      final user = await action();
      if (!ref.mounted) return null;
      await _bindUser(user);
      return null;
    } on AuthFlowException catch (error) {
      return error.code;
    }
  }

  Future<void> _syncNow() async {
    if (!_deps.firebaseConfigured || _db.uid == null) return;
    final result = await _deps.sync.sync(_db);
    if (!ref.mounted) return;
    if (result == null) {
      _offline = true;
      _emit();
      return;
    }
    _offline = false;
    final ringing = _db.ringingCallerId;
    _db = result;
    _db.ringingCallerId = ringing;
    _deps.store.state = _db;
    if (result.needsPull && result.isBlank) {
      _db = PersistedState.seed(
        languageCode: _deps.languageCode(),
        uid: result.uid,
        now: _deps.clock.now(),
      );
      _db.ringingCallerId = ringing;
      _deps.store.state = _db;
      await _save();
      final pushed = await _deps.sync.sync(_db);
      if (!ref.mounted) return;
      if (pushed != null) {
        _db = pushed;
        _db.ringingCallerId = ringing;
        _deps.store.state = _db;
        await _save();
      }
    } else {
      await _save();
    }
    await _reschedule();
    _emit();
  }

  void _scheduleSync() {
    if (!_deps.firebaseConfigured) return;
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 2), () => unawaited(_syncNow()));
  }

  void _markPremium() {
    if (!ref.mounted || _db.entitlement.premium) return;
    _db.entitlement = Entitlement(
      premium: true,
      updatedAt: _deps.clock.now(),
      source: 'store',
    );
    _commit();
  }

  void _onNotification(String? payload) {
    if (payload != null && payload.startsWith('call:')) {
      _ringScheduled(payload.substring(5), _deps.clock.now());
      _commit();
      return;
    }
    _applyTick();
  }

  Future<void> _reschedule() {
    return _deps.notifications.syncSchedules(
      state: _db,
      copy: notificationCopy(_deps.languageCode()),
      now: _deps.clock.now(),
    );
  }

  void _flashCode(String code, [String? detail]) {
    _flashNonce++;
    _flash = Flash(nonce: _flashNonce, code: code, detail: detail);
    _emit();
  }

  Caller? _findCaller(String id) {
    for (final caller in _db.callers) {
      if (caller.id == id) return caller;
    }
    return null;
  }

  bool get _premium => _db.entitlement.premium;

  Future<void> _save() {
    _deps.store.state = _db;
    return _deps.store.save();
  }

  void _commit() {
    unawaited(_save());
    unawaited(_reschedule());
    _scheduleSync();
    _emit();
  }

  void _emit() {
    if (!ref.mounted) return;
    state = _view();
  }

  AppState _view() {
    return AppState(
      ready: _booted,
      firebaseConfigured: _deps.firebaseConfigured,
      auth: _auth,
      settings: _db.settings,
      session: _db.session,
      history: List.unmodifiable(_db.history),
      patterns: List.unmodifiable(_db.patterns),
      week: _db.week,
      overrides: List.unmodifiable(_db.overrides),
      callers: List.unmodifiable(_db.callers),
      scheduledCalls: List.unmodifiable(_db.scheduledCalls),
      credits: List.unmodifiable(_db.credits),
      premium: _premium,
      prompt: _prompt,
      camouflage: _camouflage,
      liveCall: _live,
      burstCount: _burstCount,
      burstNonce: _burstNonce,
      pendingFreedom: _db.pendingFreedom,
      freedomHistoryId: _db.freedomHistoryId,
      encouragementIndex: _encourageIndex,
      encouragementNonce: _encourageNonce,
      flash: _flash,
      offline: _offline,
      mood: _mood,
    );
  }

  String _hm(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
