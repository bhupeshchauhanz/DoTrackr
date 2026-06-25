import 'package:hive/hive.dart';

part 'todo_model.g.dart';

enum Priority {
  low,
  medium,
  high,
  urgent,
}

@HiveType(typeId: 0)
class TodoModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  int? dueTimeHour;

  @HiveField(5)
  int? dueTimeMinute;

  @HiveField(6)
  int priorityIndex;

  @HiveField(7)
  String? categoryId;

  @HiveField(8)
  bool isCompleted;

  @HiveField(9)
  DateTime? completedAt;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  TodoModel({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.dueTimeHour,
    this.dueTimeMinute,
    this.priorityIndex = 1,
    this.categoryId,
    this.isCompleted = false,
    this.completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Priority get priority => Priority.values[priorityIndex];

  set priority(Priority value) {
    priorityIndex = value.index;
  }

  bool get hasDueTime => dueTimeHour != null && dueTimeMinute != null;

  DateTime? get dueDateTime {
    if (dueDate == null) return null;
    if (dueTimeHour == null || dueTimeMinute == null) return dueDate;
    return DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      dueTimeHour!,
      dueTimeMinute!,
    );
  }

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    if (hasDueTime) {
      return dueDateTime!.isBefore(now);
    }
    return dueDate!.isBefore(DateTime(now.year, now.month, now.day));
  }

  TodoModel copyWith({
    String? id,
    String? title,
    Object? description = _sentinel,
    Object? dueDate = _sentinel,
    Object? dueTimeHour = _sentinel,
    Object? dueTimeMinute = _sentinel,
    Priority? priority,
    Object? categoryId = _sentinel,
    bool? isCompleted,
    Object? completedAt = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description == _sentinel ? this.description : description as String?,
      dueDate: dueDate == _sentinel ? this.dueDate : dueDate as DateTime?,
      dueTimeHour: dueTimeHour == _sentinel ? this.dueTimeHour : dueTimeHour as int?,
      dueTimeMinute: dueTimeMinute == _sentinel ? this.dueTimeMinute : dueTimeMinute as int?,
      priorityIndex: priority?.index ?? priorityIndex,
      categoryId: categoryId == _sentinel ? this.categoryId : categoryId as String?,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt == _sentinel ? this.completedAt : completedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

// Sentinel object to distinguish "not provided" from explicit null
const _sentinel = Object();