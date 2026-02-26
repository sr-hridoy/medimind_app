import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static Function(String, String, String)? onActionCallback;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz_data.initializeTimeZones();

    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _handleAction,
      onDidReceiveBackgroundNotificationResponse: _handleAction,
    );

    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
    _initialized = true;
  }

  @pragma('vm:entry-point')
  static void _handleAction(NotificationResponse response) {
    final parts = response.payload?.split('|');
    if (parts != null &&
        parts.length >= 2 &&
        response.actionId != null &&
        onActionCallback != null) {
      onActionCallback!(parts[0], parts[1], response.actionId!);
    }
  }

  NotificationDetails _getDetails() => const NotificationDetails(
    android: AndroidNotificationDetails(
      'medicine_reminders',
      'Medicine Reminders',
      channelDescription: 'Notifications for medicine reminders',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction('taken', 'Taken', showsUserInterface: true),
        AndroidNotificationAction('missed', 'Missed', showsUserInterface: true),
      ],
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  Future<void> scheduleDoseNotification({
    required String medicineId,
    required String medicineName,
    required String dose,
    required String time,
    required int notificationId,
  }) async {
    if (kIsWeb) return;
    final scheduledTime = _parseTimeToday(time);
    if (scheduledTime == null || scheduledTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      notificationId,
      'Time for your medicine!',
      '$medicineName - $dose',
      tz.TZDateTime.from(scheduledTime, tz.local),
      _getDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '$medicineId|$time',
    );
  }

  Future<void> cancelNotification(int id) async =>
      !kIsWeb ? await _notifications.cancel(id) : null;
  Future<void> cancelAllNotifications() async =>
      !kIsWeb ? await _notifications.cancelAll() : null;

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!kIsWeb)
      await _notifications.show(
        id,
        title,
        body,
        _getDetails(),
        payload: payload,
      );
  }

  DateTime? _parseTimeToday(String timeStr) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([AP]M)$',
      caseSensitive: false,
    ).firstMatch(timeStr.trim());
    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final isPM = match.group(3)!.toUpperCase() == 'PM';

    if (isPM && hour != 12)
      hour += 12;
    else if (!isPM && hour == 12)
      hour = 0;

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static int generateNotificationId(String medicineId, String time) =>
      '$medicineId$time'.hashCode.abs() % 2147483647;
}
