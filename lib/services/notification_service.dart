import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (_) {},
    );

    _initialized = true;
  }

  static Future<void> showGeofenceNotification(dynamic event) async {
    final entered = event.entered as bool;
    final fence = event.geofence;

    final androidDetails = AndroidNotificationDetails(
      'geofence_channel',
      'Geofence Alerts',
      channelDescription: 'Notifications for geofence enter/exit events',
      importance: Importance.high,
      priority: Priority.high,
      color: entered
          ? const AndroidColor(0xFF4CAF50) // green
          : const AndroidColor(0xFFF44336), // red
    );

    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = entered
        ? '📍 Entered: ${fence.name}'
        : '📍 Exited: ${fence.name}';
    final body = entered
        ? 'You entered the geofence "${fence.name}". (Total: ${fence.enterCount})'
        : 'You left the geofence "${fence.name}". (Total: ${fence.exitCount})';

    // Use fence id hash as notification id to allow overwrite
    final id = fence.id.hashCode & 0x7FFFFFFF;

    await _plugin.show(id, title, body, details);
  }

  static Future<void> showLocationNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'location_channel',
      'Location Updates',
      channelDescription: 'Background location tracking notifications',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
    );

    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(0, title, body, details);
  }
}
