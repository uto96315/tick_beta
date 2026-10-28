import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:tick/data/persisted_state.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/domain/segments.dart';
import 'package:tick/services/gateways.dart';
import 'package:tick/services/notification_copy.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules local notifications and then lets the OS deliver them.
/// Tick does not stay running in the background just to notify.
class LocalNotificationGateway implements NotificationGateway {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;

  @override
  Future<void> init({required void Function(String? payload) onTap}) async {
    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) => onTap(response.payload),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: false, sound: true);
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        onTap(launch?.notificationResponse?.payload);
      }
      _ready = true;
    } catch (error) {
      debugPrint('notification init failed: $error');
    }
  }

  @override
  Future<void> syncSchedules({
    required PersistedState state,
    required NotificationCopy copy,
    required DateTime now,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      await _scheduleSession(state, copy, now);
      await _scheduleCalls(state, copy, now);
    } catch (error) {
      debugPrint('notification schedule failed: $error');
    }
  }

  Future<void> _scheduleSession(PersistedState state, NotificationCopy copy, DateTime now) async {
    final session = state.session;
    if (session == null) return;
    final details = _details(state.settings.notifySound);
    final segments = buildSegments(
      start: session.actualStart,
      end: session.plannedEnd,
      intervalMinutes: session.intervalMinutes,
    );
    // iOS keeps about 64 pending local notifications. Leave room for the
    // end notification and fake calls, and refresh the window whenever the
    // app opens.
    var scheduled = 0;
    if (state.settings.notifySegment) {
      for (var i = 0; i < segments.length && scheduled < 40; i++) {
        final end = segments[i].end;
        if (!end.isAfter(now)) continue;
        await _plugin.zonedSchedule(
          id: 100 + i,
          title: copy.segmentTitle,
          body: fill(copy.segmentBody, {'done': '${i + 1}', 'total': '${segments.length}'}),
          scheduledDate: tz.TZDateTime.from(end, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'segment:$i',
        );
        scheduled++;
      }
    }
    if (state.settings.notifyEnd && session.plannedEnd.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: 20,
        title: copy.endTitle,
        body: copy.endBody,
        scheduledDate: tz.TZDateTime.from(session.plannedEnd, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'end',
      );
    }
  }

  Future<void> _scheduleCalls(PersistedState state, NotificationCopy copy, DateTime now) async {
    final details = _details(state.settings.notifySound);
    var scheduled = 0;
    for (final call in state.scheduledCalls) {
      if (call.fired || !call.fireAt.isAfter(now) || scheduled >= 10) continue;
      Caller? caller;
      for (final item in state.callers) {
        if (item.id == call.callerId) caller = item;
      }
      await _plugin.zonedSchedule(
        id: 1000 + (call.id.hashCode.abs() % 500),
        title: copy.callTitle,
        body: fill(copy.callBody, {'name': caller?.name ?? ''}),
        scheduledDate: tz.TZDateTime.from(call.fireAt, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'call:${call.id}',
      );
      scheduled++;
    }
  }

  NotificationDetails _details(bool sound) {
    return NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: sound,
        presentBadge: false,
        sound: sound ? '' : null,
      ),
    );
  }
}
