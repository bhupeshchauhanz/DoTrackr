import 'package:hive/hive.dart';

part 'habit_model.g.dart';

enum HabitFrequency {
  daily,
  weekly,
  custom,
}

@HiveType(typeId: 1)
class HabitModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  int frequencyIndex;

  @HiveField(4)
  List<int>? daysOfWeek;

  @HiveField(5)
  int timesPerDay;

  @HiveField(6)
  int? reminderHour;

  @HiveField(7)
  int? reminderMinute;

  @HiveField(12)
  List<String> reminderTimes; // "HH:MM" strings for multiple reminders

  @HiveField(8)
  int colorValue;

  @HiveField(9)
  String iconName;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  @HiveField(13)
  int durationMinutes; // target duration in minutes (0 = no timer)

  @HiveField(14)
  String durationScope; // 'today' = apply only today, 'all' = apply from today onwards

  @HiveField(15)
  String reminderScope; // 'today' = apply only today, 'all' = apply from today onwards

  HabitModel({
    required this.id,
    required this.name,
    this.description,
    this.frequencyIndex = 0,
    this.daysOfWeek,
    this.timesPerDay = 1,
    this.reminderHour,
    this.reminderMinute,
    this.reminderTimes = const [],
    this.colorValue = 0xFFFFFFFF,
    this.iconName = 'check_circle',
    this.durationMinutes = 0,
    this.durationScope = 'all',
    this.reminderScope = 'all',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  HabitFrequency get frequency => HabitFrequency.values[frequencyIndex];

  set frequency(HabitFrequency value) {
    frequencyIndex = value.index;
  }

  bool get hasReminder =>
      reminderTimes.isNotEmpty ||
      (reminderHour != null && reminderMinute != null);

  bool isScheduledForDay(DateTime date) {
    switch (frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekly:
        return date.weekday == DateTime.monday;
      case HabitFrequency.custom:
        final days = daysOfWeek;
        if (days == null || days.isEmpty) return false;
        return days.contains(date.weekday);
    }
  }

  bool get hasTimer => durationMinutes > 0;

  bool get isDurationForTodayOnly => durationScope == 'today';
  bool get isReminderForTodayOnly => reminderScope == 'today';

  HabitModel copyWith({
    String? id,
    String? name,
    String? description,
    HabitFrequency? frequency,
    List<int>? daysOfWeek,
    int? timesPerDay,
    Object? reminderHour = _sentinel,
    Object? reminderMinute = _sentinel,
    List<String>? reminderTimes,
    int? colorValue,
    String? iconName,
    int? durationMinutes,
    String? durationScope,
    String? reminderScope,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequencyIndex: frequency?.index ?? frequencyIndex,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      reminderHour: reminderHour == _sentinel ? this.reminderHour : reminderHour as int?,
      reminderMinute: reminderMinute == _sentinel ? this.reminderMinute : reminderMinute as int?,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      durationScope: durationScope ?? this.durationScope,
      reminderScope: reminderScope ?? this.reminderScope,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

// Sentinel object to distinguish "not provided" from explicit null
const _sentinel = Object();