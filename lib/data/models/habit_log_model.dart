import 'package:hive/hive.dart';

part 'habit_log_model.g.dart';

@HiveType(typeId: 2)
class HabitLogModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String habitId;

  @HiveField(2)
  final DateTime completedAt;

  @HiveField(3)
  String? note;

  @HiveField(4)
  int count;

  @HiveField(5)
  int durationSeconds; // actual time spent in seconds

  HabitLogModel({
    required this.id,
    required this.habitId,
    required this.completedAt,
    this.note,
    this.count = 1,
    this.durationSeconds = 0,
  });

  bool isSameDay(DateTime other) {
    return completedAt.year == other.year &&
        completedAt.month == other.month &&
        completedAt.day == other.day;
  }

  HabitLogModel copyWith({
    String? id,
    String? habitId,
    DateTime? completedAt,
    String? note,
    int? count,
    int? durationSeconds,
  }) {
    return HabitLogModel(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      completedAt: completedAt ?? this.completedAt,
      note: note ?? this.note,
      count: count ?? this.count,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}