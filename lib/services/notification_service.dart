import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/video_link.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  NotificationService._()
    : _notificationsPlugin = FlutterLocalNotificationsPlugin() {
    _init();
  }

  Future<void> _init() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        debugPrint('Notification tapped: ${details.payload}');
      },
    );
  }

  Future<void> scheduleNotification(VideoLink videoLink) async {
    if (videoLink.reminder == null) return;

    final androidDetails = AndroidNotificationDetails(
      'video_reminders_channel',
      'Video Reminders',
      channelDescription: 'Notifications for video reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      videoLink.id.hashCode,
      'Recordatorio de video: ${videoLink.title}',
      videoLink.description,
      tz.TZDateTime.from(videoLink.reminder!, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: videoLink.id,
    );
  }

  Future<void> cancelNotification(VideoLink videoLink) async {
    await _notificationsPlugin.cancel(videoLink.id.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
