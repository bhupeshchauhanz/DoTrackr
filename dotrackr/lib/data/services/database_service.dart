import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/todo_model.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final _uuid = const Uuid();

  late Box<TodoModel> _todoBox;
  late Box<HabitModel> _habitBox;
  late Box<HabitLogModel> _habitLogBox;
  late Box<CategoryModel> _categoryBox;
  late Box<UserModel> _userBox;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      Hive.registerAdapter(TodoModelAdapter());
      Hive.registerAdapter(HabitModelAdapter());
      Hive.registerAdapter(HabitLogModelAdapter());
      Hive.registerAdapter(CategoryModelAdapter());
      Hive.registerAdapter(UserModelAdapter());

      _todoBox = await Hive.openBox<TodoModel>(AppConstants.todoBoxName);
      _habitBox = await Hive.openBox<HabitModel>(AppConstants.habitBoxName);
      _habitLogBox = await Hive.openBox<HabitLogModel>(AppConstants.habitLogBoxName);
      _categoryBox = await Hive.openBox<CategoryModel>(AppConstants.categoryBoxName);
      _userBox = await Hive.openBox<UserModel>('users');

      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  String generateId() => _uuid.v4();

  Box<TodoModel> get todoBox => _todoBox;
  Box<HabitModel> get habitBox => _habitBox;
  Box<HabitLogModel> get habitLogBox => _habitLogBox;
  Box<CategoryModel> get categoryBox => _categoryBox;
  Box<UserModel> get userBox => _userBox;

  Future<TodoModel> createTodo({
    required String title,
    String? description,
    DateTime? dueDate,
    int? dueTimeHour,
    int? dueTimeMinute,
    Priority priority = Priority.medium,
    String? categoryId,
  }) async {
    final todo = TodoModel(
      id: generateId(),
      title: title,
      description: description,
      dueDate: dueDate,
      dueTimeHour: dueTimeHour,
      dueTimeMinute: dueTimeMinute,
      priorityIndex: priority.index,
      categoryId: categoryId,
    );
    await _todoBox.put(todo.id, todo);
    return todo;
  }

  Future<TodoModel> updateTodo(TodoModel todo) async {
    todo.updatedAt = DateTime.now();
    await _todoBox.put(todo.id, todo);
    return todo;
  }

  Future<void> deleteTodo(String id) async {
    await _todoBox.delete(id);
  }

  List<TodoModel> getAllTodos() {
    return _todoBox.values.toList();
  }

  TodoModel? getTodoById(String id) {
    return _todoBox.get(id);
  }

  Future<HabitModel> createHabit({
    required String name,
    String? description,
    HabitFrequency frequency = HabitFrequency.daily,
    List<int>? daysOfWeek,
    int timesPerDay = 1,
    int? reminderHour,
    int? reminderMinute,
    int colorValue = 0xFFFFFFFF,
    String iconName = 'check_circle',
  }) async {
    final habit = HabitModel(
      id: generateId(),
      name: name,
      description: description,
      frequencyIndex: frequency.index,
      daysOfWeek: daysOfWeek,
      timesPerDay: timesPerDay,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      colorValue: colorValue,
      iconName: iconName,
    );
    await _habitBox.put(habit.id, habit);
    return habit;
  }

  Future<HabitModel> updateHabit(HabitModel habit) async {
    habit.updatedAt = DateTime.now();
    await _habitBox.put(habit.id, habit);
    return habit;
  }

  Future<void> deleteHabit(String id) async {
    await _habitBox.delete(id);
    final logsToDelete = _habitLogBox.values
        .where((log) => log.habitId == id)
        .map((log) => log.id)
        .toList();
    for (final logId in logsToDelete) {
      await _habitLogBox.delete(logId);
    }
  }

  List<HabitModel> getAllHabits() {
    return _habitBox.values.toList();
  }

  HabitModel? getHabitById(String id) {
    return _habitBox.get(id);
  }

  Future<HabitLogModel> logHabitCompletion({
    required String habitId,
    DateTime? completedAt,
    String? note,
    int count = 1,
  }) async {
    final log = HabitLogModel(
      id: generateId(),
      habitId: habitId,
      completedAt: completedAt ?? DateTime.now(),
      note: note,
      count: count,
    );
    await _habitLogBox.put(log.id, log);
    return log;
  }

  List<HabitLogModel> getHabitLogs(String habitId) {
    return _habitLogBox.values
        .where((log) => log.habitId == habitId)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  List<HabitLogModel> getLogsForDate(DateTime date) {
    return _habitLogBox.values.where((log) {
      return log.completedAt.year == date.year &&
          log.completedAt.month == date.month &&
          log.completedAt.day == date.day;
    }).toList();
  }

  List<HabitLogModel> getLogsForDateRange(DateTime start, DateTime end) {
    return _habitLogBox.values.where((log) {
      return log.completedAt.isAfter(start.subtract(const Duration(days: 1))) &&
          log.completedAt.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  int getHabitStreak(HabitModel habit) {
    final logs = getHabitLogs(habit.id);
    if (logs.isEmpty) return 0;

    int streak = 0;
    DateTime now = DateTime.now();
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    if (habit.isScheduledForDay(checkDate)) {
      final loggedToday = logs.any((log) => log.isSameDay(checkDate));
      if (loggedToday) {
        streak++;
      }
    }

    checkDate = checkDate.subtract(const Duration(days: 1));

    while (true) {
      if (!habit.isScheduledForDay(checkDate)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }

      final hasLog = logs.any((log) => log.isSameDay(checkDate));
      if (hasLog) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }

      if (streak > 365) break;
    }

    return streak;
  }

  Future<CategoryModel> createCategory({
    required String name,
    int colorValue = 0xFFB0B0B0,
    String iconName = 'folder',
  }) async {
    final category = CategoryModel(
      id: generateId(),
      name: name,
      colorValue: colorValue,
      iconName: iconName,
    );
    await _categoryBox.put(category.id, category);
    return category;
  }

  Future<void> deleteCategory(String id) async {
    await _categoryBox.delete(id);
  }

  List<CategoryModel> getAllCategories() {
    return _categoryBox.values.toList();
  }

  Future<void> clearAllData() async {
    await _todoBox.clear();
    await _habitBox.clear();
    await _habitLogBox.clear();
    await _categoryBox.clear();
  }
}