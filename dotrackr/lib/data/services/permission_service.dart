import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezone database
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Create notification channels on Android 8+
    await _createNotificationChannels();

    _isInitialized = true;
  }

  /// Create all notification channels (required for Android 8.0+)
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    // Reminder channel — for scheduled alarms (sound + vibration)
    const reminderChannel = AndroidNotificationChannel(
      'dotrackr_reminders',
      'DoTrackr Reminders',
      description: 'Scheduled reminders for todos and habits',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Alert channel — for instant alerts (sound + vibration)
    const alertChannel = AndroidNotificationChannel(
      'dotrackr_alerts',
      'DoTrackr Alerts',
      description: 'Instant notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin.createNotificationChannel(reminderChannel);
    await androidPlugin.createNotificationChannel(alertChannel);
  }

  Future<bool> requestNotificationPermission() async {
    try {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkNotificationPermission() async {
    try {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted = await androidImplementation.areNotificationsEnabled();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestExactAlarmPermission() async {
    try {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestExactAlarmsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Show an instant notification with sound and vibration
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'dotrackr_alerts',
      'DoTrackr Alerts',
      channelDescription: 'Instant notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(id, title, body, notificationDetails,
        payload: payload);
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> vibrateForReminder() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Schedule a ONE-TIME notification (for todos — fires once at exact time)
  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'dotrackr_reminders',
      'DoTrackr Reminders',
      channelDescription: 'Scheduled reminders',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) return; // already past

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // No matchDateTimeComponents → fires ONCE only
      );
    } catch (e) {
      // Fallback: inexact but still fires
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Schedule a DAILY REPEATING notification (for habits — fires every day at same time)
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'dotrackr_reminders',
      'DoTrackr Reminders',
      channelDescription: 'Scheduled reminders',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    // Schedule for today at the given time; if already past, schedule for tomorrow
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      );
    } catch (e) {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Legacy method kept for compatibility — uses one-time scheduling
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) => scheduleOneTimeNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
      );
}