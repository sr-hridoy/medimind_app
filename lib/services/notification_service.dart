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

  // Callback for handling notification actions
  static Function(String medicineId, String time, String action)?
  onActionCallback;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    // Request permissions on Android 13+
    if (!kIsWeb && Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    _handleAction(response);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    _handleAction(response);
  }

  static void _handleAction(NotificationResponse response) {
    final payload = response.payload;
    final actionId = response.actionId;

    if (payload == null || actionId == null) return;

    // Parse payload: "medicineId|time"
    final parts = payload.split('|');
    if (parts.length < 2) return;

    final medicineId = parts[0];
    final time = parts[1];

    if (onActionCallback != null) {
      onActionCallback!(medicineId, time, actionId);
    }
  }

  /// Schedule a notification for a specific medicine dose
  Future<void> scheduleDoseNotification({
    required String medicineId,
    required String medicineName,
    required String dose,
    required String time, // Format: "HH:MM AM/PM"
    required int notificationId,
  }) async {
    if (kIsWeb) return;

    try {
      final scheduledTime = _parseTimeToday(time);
      if (scheduledTime == null || scheduledTime.isBefore(DateTime.now())) {
        debugPrint('Skipping past/invalid time: $time');
        return; // Don't schedule past times
      }

      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'medicine_reminders',
        'Medicine Reminders',
        channelDescription: 'Notifications for medicine reminders',
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          AndroidNotificationAction('taken', 'Taken', showsUserInterface: true),
          AndroidNotificationAction(
            'missed',
            'Missed',
            showsUserInterface: true,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        notificationId,
        'Time for your medicine!',
        '$medicineName - $dose',
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '$medicineId|$time',
      );
      debugPrint('Scheduled notification $notificationId for $time');
    } catch (e, stack) {
      debugPrint('Error scheduling notification: $e');
      debugPrint(stack.toString());
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int notificationId) async {
    if (kIsWeb) return;
    await _notifications.cancel(notificationId);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }

  /// Show an immediate notification (for testing)
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'medicine_reminders',
      'Medicine Reminders',
      channelDescription: 'Notifications for medicine reminders',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction('taken', 'Taken', showsUserInterface: true),
        AndroidNotificationAction('missed', 'Missed', showsUserInterface: true),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Parse "HH:MM AM/PM" to DateTime today
  /// Parse "HH:MM AM/PM" to DateTime today
  DateTime? _parseTimeToday(String timeStr) {
    try {
      // Create a regex to match HH:MM AM/PM (handling various spaces)
      final regex = RegExp(
        r'^(\d{1,2}):(\d{2})\s*([AP]M)$',
        caseSensitive: false,
      );
      final match = regex.firstMatch(timeStr.trim());

      if (match == null) {
        debugPrint('Invalid time format: $timeStr');
        return null;
      }

      int hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final period = match.group(3)!.toUpperCase();

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      debugPrint('Error parsing time: $e');
      return null;
    }
  }

  /// Generate a unique notification ID from medicineId and time
  static int generateNotificationId(String medicineId, String time) {
    return '$medicineId$time'.hashCode.abs() % 2147483647;
  }
}
