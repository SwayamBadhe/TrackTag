// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static const String _channelId = 'ble_tracker_channel';
  static const String _channelName = 'BLE Tracker Alerts';
  static const String _channelDescription = 'Notifications for BLE device tracking';

  NotificationService() {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings settings = InitializationSettings(android: androidSettings);
      await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );

      AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true, // Channel supports sound, controlled per notification
        sound: const RawResourceAndroidNotificationSound('alert'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      );
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  // For tracking alerts (sound, vibration, notification)
  Future<void> showStatusAlert({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    try {
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alert'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        showWhen: true,
        ticker: 'BLE Tracker Alert',
      );
      NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 500, 200, 500]);
      }
      debugPrint('Status alert shown: $title - $body');
    } catch (e) {
      debugPrint('Error showing status alert: $e');
    }
  }

  // For general notifications (no sound, no vibration)
  Future<void> showSimpleNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: false, // No sound
        enableVibration: false, // No vibration
        showWhen: true,
      );
      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
      debugPrint('Simple notification shown: $title - $body');
    } catch (e) {
      debugPrint('Error showing simple notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      debugPrint('Notification $id cancelled');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }
}