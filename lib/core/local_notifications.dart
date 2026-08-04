import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// On-device alarm for a patient's own medication reminder times (set by their Provider) —
// entirely local, no server round-trip and no push infra needed, unlike the WhatsApp-style
// "new consultation message" push notification (separate feature, needs Firebase/APNs).
//
// ponytail: hardcoded to Asia/Jakarta (this app's target region — Register Patient's
// timezone picker defaults the same way for the same reason) rather than adding a
// device-timezone-detection package for one feature; revisit if this app ever serves
// patients outside Indonesia's timezone in practice.
class LocalNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final android = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return (ios ?? android ?? false);
  }

  // Cancels any previously scheduled reminder alarms and reschedules from the given
  // "HH:MM, HH:MM" times string — safe to call every time the reminder is (re)loaded, since
  // stale times from a since-edited reminder must not keep firing.
  static Future<void> scheduleReminder({required String times, required String? title}) async {
    await cancelReminder();
    final slots = times
        .split(',')
        .map((s) => s.trim())
        .where((s) => RegExp(r'^\d{1,2}:\d{2}$').hasMatch(s))
        .toList();

    for (var i = 0; i < slots.length; i++) {
      final parts = slots[i].split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      await _plugin.zonedSchedule(
        1000 + i,
        title ?? 'Medication reminder',
        'It\'s time to take your ARV medication.',
        _nextInstanceOf(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_reminder',
            'Medication Reminders',
            channelDescription: 'ARV medication reminder alarms',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> cancelReminder() async {
    // reminders occupy ids 1000..1000+N; a generous fixed range covers the realistic max
    // number of times-per-day a patient would ever have, without tracking count separately
    for (var i = 1000; i < 1020; i++) {
      await _plugin.cancel(i);
    }
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
