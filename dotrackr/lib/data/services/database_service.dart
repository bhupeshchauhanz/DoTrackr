import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
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

      final encryptionKey = await _getEncryptionKey();
      final cipher = HiveAesCipher(encryptionKey);

      Hive.registerAdapter(TodoModelAdapter());
      Hive.registerAdapter(HabitModelAdapter());
      Hive.registerAdapter(HabitLogModelAdapter());
      Hive.registerAdapter(CategoryModelAdapter());
      Hive.registerAdapter(UserModelAdapter());

      _todoBox = await Hive.openBox<TodoModel>(AppConstants.todoBoxName,
          encryptionCipher: cipher);
      _habitBox = await Hive.openBox<HabitModel>(AppConstants.habitBoxName,
          encryptionCipher: cipher);
      _habitLogBox = await Hive.openBox<HabitLogModel>(AppConstants.habitLogBoxName,
          encryptionCipher: cipher);
      _categoryBox = await Hive.openBox<CategoryModel>(AppConstants.categoryBoxName,
          encryptionCipher: cipher);
      _userBox = await Hive.openBox<UserModel>(AppConstants.userBoxName,
          encryptionCipher: cipher);

      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  Future<Uint8List> _getEncryptionKey() async {
    final dir = await getApplicationDocumentsDirectory();
    final keyFile = File('${dir.path}/dotrackr_encryption.key');

    if (await keyFile.exists()) {
      return await keyFile.readAsBytes();
    }

    final key = Uint8List.fromList(Hive.generateSecureKey());
    await keyFile.writeAsBytes(key);
    return key;
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
    List<String> reminderTimes = const [],
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
      reminderTimes: reminderTimes,
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
    List<String> reminderTimes = const [],
    int colorValue = 0xFFFFFFFF,
    String iconName = 'check_circle',
    int durationMinutes = 0,
    String durationScope = 'all',
    String reminderScope = 'all',
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
      reminderTimes: reminderTimes,
      colorValue: colorValue,
      iconName: iconName,
      durationMinutes: durationMinutes,
      durationScope: durationScope,
      reminderScope: reminderScope,
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
    int durationSeconds = 0,
  }) async {
    final log = HabitLogModel(
      id: generateId(),
      habitId: habitId,
      completedAt: completedAt ?? DateTime.now(),
      note: note,
      count: count,
      durationSeconds: durationSeconds,
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
      if (checkDate.isBefore(habit.createdAt.subtract(const Duration(days: 1))) ||
          now.difference(checkDate).inDays > 365) {
        break;
      }

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

  /// Export all data to a JSON file in Downloads or Documents directory.
  /// Returns the file path, or null on failure.
  Future<String?> exportData() async {
    try {
      final todos = _todoBox.values.map((t) => {
        'id': t.id,
        'title': t.title,
        'description': t.description,
        'dueDate': t.dueDate?.toIso8601String(),
        'dueTimeHour': t.dueTimeHour,
        'dueTimeMinute': t.dueTimeMinute,
        'priorityIndex': t.priorityIndex,
        'categoryId': t.categoryId,
        'isCompleted': t.isCompleted,
        'completedAt': t.completedAt?.toIso8601String(),
        'createdAt': t.createdAt.toIso8601String(),
        'updatedAt': t.updatedAt.toIso8601String(),
        'reminderTimes': t.reminderTimes,
      }).toList();

      final habits = _habitBox.values.map((h) => {
        'id': h.id,
        'name': h.name,
        'description': h.description,
        'frequencyIndex': h.frequencyIndex,
        'daysOfWeek': h.daysOfWeek,
        'timesPerDay': h.timesPerDay,
        'reminderHour': h.reminderHour,
        'reminderMinute': h.reminderMinute,
        'reminderTimes': h.reminderTimes,
        'colorValue': h.colorValue,
        'iconName': h.iconName,
        'durationMinutes': h.durationMinutes,
        'durationScope': h.durationScope,
        'reminderScope': h.reminderScope,
        'createdAt': h.createdAt.toIso8601String(),
        'updatedAt': h.updatedAt.toIso8601String(),
      }).toList();

      final habitLogs = _habitLogBox.values.map((l) => {
        'id': l.id,
        'habitId': l.habitId,
        'completedAt': l.completedAt.toIso8601String(),
        'note': l.note,
        'count': l.count,
        'durationSeconds': l.durationSeconds,
      }).toList();

      final categories = _categoryBox.values.map((c) => {
        'id': c.id,
        'name': c.name,
        'colorValue': c.colorValue,
        'iconName': c.iconName,
      }).toList();

      final backup = jsonEncode({
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'todos': todos,
        'habits': habits,
        'habitLogs': habitLogs,
        'categories': categories,
      });

      // Try Downloads first, fallback to Documents
      Directory? dir;
      try {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) dir = null;
      } catch (_) {}
      dir ??= await getApplicationDocumentsDirectory();

      final fileName = 'dotrackr_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(backup);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Import data from a JSON backup file path.
  /// Returns true on success, false on failure.
  Future<bool> importData(String filePath) async {
    try {
      final file = File(filePath);
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final version = data['version'] as int? ?? 1;
      if (version != 1) return false;

      // Clear existing data
      await clearAllData();

      // Restore categories
      final categories = (data['categories'] as List? ?? []).cast<Map<String, dynamic>>();
      for (final c in categories) {
        final cat = CategoryModel(
          id: c['id'] as String,
          name: c['name'] as String,
          colorValue: c['colorValue'] as int? ?? 0xFFB0B0B0,
          iconName: c['iconName'] as String? ?? 'folder',
        );
        await _categoryBox.put(cat.id, cat);
      }

      // Restore todos
      final todos = (data['todos'] as List? ?? []).cast<Map<String, dynamic>>();
      for (final t in todos) {
        final todo = TodoModel(
          id: t['id'] as String,
          title: t['title'] as String,
          description: t['description'] as String?,
          dueDate: t['dueDate'] != null ? DateTime.parse(t['dueDate'] as String) : null,
          dueTimeHour: t['dueTimeHour'] as int?,
          dueTimeMinute: t['dueTimeMinute'] as int?,
          priorityIndex: t['priorityIndex'] as int? ?? 1,
          categoryId: t['categoryId'] as String?,
          isCompleted: t['isCompleted'] as bool? ?? false,
          completedAt: t['completedAt'] != null ? DateTime.parse(t['completedAt'] as String) : null,
          reminderTimes: (t['reminderTimes'] as List? ?? []).cast<String>(),
          createdAt: DateTime.parse(t['createdAt'] as String),
          updatedAt: DateTime.parse(t['updatedAt'] as String),
        );
        await _todoBox.put(todo.id, todo);
      }

      // Restore habits
      final habits = (data['habits'] as List? ?? []).cast<Map<String, dynamic>>();
      for (final h in habits) {
        final habit = HabitModel(
          id: h['id'] as String,
          name: h['name'] as String,
          description: h['description'] as String?,
          frequencyIndex: h['frequencyIndex'] as int? ?? 0,
          daysOfWeek: (h['daysOfWeek'] as List?)?.cast<int>(),
          timesPerDay: h['timesPerDay'] as int? ?? 1,
          reminderHour: h['reminderHour'] as int?,
          reminderMinute: h['reminderMinute'] as int?,
          reminderTimes: (h['reminderTimes'] as List? ?? []).cast<String>(),
          colorValue: h['colorValue'] as int? ?? 0xFFFFFFFF,
          iconName: h['iconName'] as String? ?? 'check_circle',
          durationMinutes: h['durationMinutes'] as int? ?? 0,
          durationScope: h['durationScope'] as String? ?? 'all',
          reminderScope: h['reminderScope'] as String? ?? 'all',
        );
        await _habitBox.put(habit.id, habit);
      }

      // Restore habit logs
      final habitLogs = (data['habitLogs'] as List? ?? []).cast<Map<String, dynamic>>();
      for (final l in habitLogs) {
        final log = HabitLogModel(
          id: l['id'] as String,
          habitId: l['habitId'] as String,
          completedAt: DateTime.parse(l['completedAt'] as String),
          note: l['note'] as String?,
          count: l['count'] as int? ?? 1,
          durationSeconds: l['durationSeconds'] as int? ?? 0,
        );
        await _habitLogBox.put(log.id, log);
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}