import 'package:tick/domain/fake_call_policy.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/domain/schedule.dart';
import 'package:tick/services/gateways.dart';

class Flash {
  const Flash({required this.nonce, required this.code, this.detail});

  final int nonce;
  final String code;
  final String? detail;
}

class AppState {
  const AppState({
    required this.ready,
    required this.firebaseConfigured,
    required this.auth,
    required this.settings,
    required this.session,
    required this.history,
    required this.patterns,
    required this.week,
    required this.overrides,
    required this.callers,
    required this.scheduledCalls,
    required this.credits,
    required this.premium,
    required this.prompt,
    required this.camouflage,
    required this.liveCall,
    required this.burstCount,
    required this.burstNonce,
    required this.pendingFreedom,
    required this.freedomHistoryId,
    required this.encouragementIndex,
    required this.encouragementNonce,
    required this.flash,
    required this.offline,
  });

  final bool ready;
  final bool firebaseConfigured;
  final AuthUser? auth;
  final AppSettings settings;
  final TimerSession? session;
  final List<WorkRecord> history;
  final List<WorkPattern> patterns;
  final WeekPlan week;
  final List<DateOverride> overrides;
  final List<Caller> callers;
  final List<ScheduledFakeCall> scheduledCalls;
  final List<CallCredit> credits;
  final bool premium;
  final ResolvedShift? prompt;
  final bool camouflage;
  final LiveCall? liveCall;
  final int burstCount;
  final int burstNonce;
  final bool pendingFreedom;
  final String? freedomHistoryId;
  final int encouragementIndex;
  final int encouragementNonce;
  final Flash? flash;
  final bool offline;

  factory AppState.initial() {
    final now = DateTime.fromMillisecondsSinceEpoch(0);
    return AppState(
      ready: false,
      firebaseConfigured: false,
      auth: null,
      settings: AppSettings.initial(now),
      session: null,
      history: const [],
      patterns: const [],
      week: WeekPlan(days: const {}, updatedAt: now),
      overrides: const [],
      callers: const [],
      scheduledCalls: const [],
      credits: const [],
      premium: false,
      prompt: null,
      camouflage: false,
      liveCall: null,
      burstCount: 0,
      burstNonce: 0,
      pendingFreedom: false,
      freedomHistoryId: null,
      encouragementIndex: 0,
      encouragementNonce: 0,
      flash: null,
      offline: false,
    );
  }
}
