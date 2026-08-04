import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'api_client.dart';
import 'local_notifications.dart';
import 'router.dart';

// Real FCM push for consultation chat messages — separate mechanism from
// LocalNotifications (on-device scheduled alarm, no server involved). Both platforms'
// native config are wired (see HIV-Project-App/CLAUDE.md) — Android verified end-to-end in
// production; iOS verified only via xcrun simctl push's local simulation, since Simulator
// can never receive a real backend-triggered push (no real APNs registration exists for
// it) — only a real device can prove that leg.
class PushNotifications {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Firebase.initializeApp();
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    // FCM doesn't auto-display a banner on Android while the app is in the foreground —
    // hand it to the existing LocalNotifications plugin to actually show it.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      LocalNotifications.showNow(
        id: message.hashCode,
        title: notification.title ?? '',
        body: notification.body ?? '',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleTap(initial);

    _initialized = true;
  }

  static void _handleTap(RemoteMessage message) {
    if (message.data['type'] != 'consultation_message') return;
    final consultationId = message.data['consultationId'];
    if (consultationId == null) return;
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    context.go('/consultations/$consultationId');
  }

  static Future<void> _registerToken(String token) async {
    await dio.post('/device-tokens', data: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'});
  }

  // Called after login — registers the current device's token against the now-known user.
  // Best-effort: a network blip here must never block a successful login.
  static Future<void> registerCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(token);
    } catch (_) {
      // next onTokenRefresh, or the next login, will retry this — safe to ignore here.
    }
  }

  // Called before logout (while the Bearer token is still valid to authenticate this call).
  // Best-effort: a network blip here must never block the user from actually logging out.
  static Future<void> unregisterCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await dio.delete('/device-tokens', data: {'token': token});
    } catch (_) {
      // stale token stays registered; sendPushToUser prunes it once FCM reports it dead.
    }
  }
}
