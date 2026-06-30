import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

const String _channelId = 'dotrackr_standard_v8';
const String _channelName = 'DoTrackr Reminders';

String buildPayload({
  required String type,
  required String id,
  String action = 'reminder',
  String title = '',
  String? dueDate,
  bool isPeriodic = false,
}) {
  return jsonEncode({
    'type': type,
    'id': id,
    'action': action,
    'title': title,
    'dueDate': dueDate,
    'isPeriodic': isPeriodic,
  });
}

@pragma('vm:entry-point')
void backgroundNotificationHandler(NotificationResponse response) {
  // Simple handler, if needed
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  void Function(String? payload)? onNotificationTap;

  Future<void> init() async {
    if (_isInitialized) return;
    tz_data.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e) {
      debugPrint('timezone fallback: $e');
      try { tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); } catch (_) {}
    }
    const androidSettings = AndroidInitializationSettings('ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, 
      requestBadgePermission: false, 
      requestSoundPermission: false
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse: backgroundNotificationHandler,
    );
    await _createChannel();
    _isInitialized = true;
  }

  void _onForegroundResponse(NotificationResponse response) {
    onNotificationTap?.call(response.payload);
  }

  Future<void> _createChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _channelId, _channelName,
      description: 'Standard reminders for tasks and habits',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    ));
  }

  Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) return await android.requestNotificationsPermission() ?? false;
      return true;
    } catch (e) { return false; }
  }

  Future<bool> hasPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) return await android.areNotificationsEnabled() ?? false;
      return true;
    } catch (e) { return false; }
  }

  void cancel(int id) {
    try { _plugin.cancel(id); } catch (e) { debugPrint('cancel $id: $e'); }
  }

  void cancelAll() { 
      _plugin.cancelAll(); 
  }

  void cancelItemNotifications(String type, String id) {
    if (type == 'habit') {
      final base = (id.hashCode & 0x1FFFFFFF) + 0x40000000;
      for (int i = 0; i < 70; i++) { cancel(base + i); }
    } else {
      final base = (id.hashCode & 0x3FFFFFFF);
      for (int i = 0; i < 7; i++) { cancel(base + i); }
    }
  }

  AndroidNotificationDetails _details() {
    return const AndroidNotificationDetails(
      _channelId, _channelName,
      channelDescription: 'Standard Reminders',
      importance: Importance.max, priority: Priority.high,
      playSound: true, enableVibration: true,
    );
  }

  Future<void> scheduleOneTime({
    required int id, 
    required String title, 
    required String body, 
    required DateTime scheduledTime, 
    String? payload
  }) async {
    if (!_isInitialized) await init();
    if (!await hasPermission()) return;
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) return;
    
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      NotificationDetails(android: _details()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> scheduleDaily({
    required int id, 
    required String title, 
    required String body, 
    required int hour, 
    required int minute, 
    String? payload
  }) async {
    if (!_isInitialized) await init();
    if (!await hasPermission()) return;
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) { scheduledDate = scheduledDate.add(const Duration(days: 1)); }
    
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(android: _details()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> updateDailySummary(int pendingTodos, int pendingHabits) async {
    if (!_isInitialized) await init();
    final id = 999999;
    
    if (pendingTodos == 0 && pendingHabits == 0) {
      cancel(id);
      return;
    }
    
    if (!await hasPermission()) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 23, 0); // 11:00 PM
    if (scheduledDate.isBefore(now)) { scheduledDate = scheduledDate.add(const Duration(days: 1)); }

    String body = '1 hr left in today. You have ';
    List<String> parts = [];
    if (pendingHabits > 0) parts.add('$pendingHabits habit${pendingHabits > 1 ? 's' : ''}');
    if (pendingTodos > 0) parts.add('$pendingTodos todo${pendingTodos > 1 ? 's' : ''}');
    body += parts.join(' and ') + ' pending. Kindly complete them!';

    await _plugin.zonedSchedule(
      id,
      'End of Day Summary',
      body,
      scheduledDate,
      NotificationDetails(android: _details()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
  Future<void> scheduleBirthdayNotifications(DateTime dob, String name) async {
    if (!_isInitialized) await init();
    if (!await hasPermission()) return;
    
    final id12am = 888888;
    final id12pm = 888889;

    cancel(id12am);
    cancel(id12pm);

    final now = tz.TZDateTime.now(tz.local);
    var nextBirthday = tz.TZDateTime(tz.local, now.year, dob.month, dob.day);
    if (nextBirthday.isBefore(now) && !(now.month == dob.month && now.day == dob.day)) {
      nextBirthday = tz.TZDateTime(tz.local, now.year + 1, dob.month, dob.day);
    }

    var date12am = tz.TZDateTime(tz.local, nextBirthday.year, nextBirthday.month, nextBirthday.day, 0, 1);
    var date12pm = tz.TZDateTime(tz.local, nextBirthday.year, nextBirthday.month, nextBirthday.day, 12, 0);
    
    if (date12am.isBefore(now)) date12am = date12am.add(const Duration(days: 365));
    if (date12pm.isBefore(now)) date12pm = date12pm.add(const Duration(days: 365));

    final title = 'Happy Birthday $name! 🎉🎂';
    final body = 'Wishing you a fantastic day filled with joy and success! Have a wonderful year ahead. 😊';

    await _plugin.zonedSchedule(
      id12am, title, body, date12am,
      NotificationDetails(android: _details()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );

    await _plugin.zonedSchedule(
      id12pm, title, body, date12pm,
      NotificationDetails(android: _details()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }
}
