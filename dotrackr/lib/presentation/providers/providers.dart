import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/todo_model.dart';
import '../../data/models/habit_model.dart';
import '../../data/models/habit_log_model.dart';
import '../../data/models/category_model.dart';
import '../../data/services/database_service.dart';
import '../../data/services/permission_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final todosProvider = StateNotifierProvider<TodosNotifier, List<TodoModel>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return TodosNotifier(db);
});

class TodosNotifier extends StateNotifier<List<TodoModel>> {
  final DatabaseService _db;

  TodosNotifier(this._db) : super([]) {
    loadTodos();
  }

  void loadTodos() {
    state = _db.getAllTodos();
  }

  Future<TodoModel> addTodo({
    required String title,
    String? description,
    DateTime? dueDate,
    int? dueTimeHour,
    int? dueTimeMinute,
    Priority priority = Priority.medium,
    String? categoryId,
  }) async {
    final todo = await _db.createTodo(
      title: title,
      description: description,
      dueDate: dueDate,
      dueTimeHour: dueTimeHour,
      dueTimeMinute: dueTimeMinute,
      priority: priority,
      categoryId: categoryId,
    );
    loadTodos();
    if (todo.hasDueTime && todo.dueDate != null) {
      final scheduledTime = DateTime(
        todo.dueDate!.year,
        todo.dueDate!.month,
        todo.dueDate!.day,
        todo.dueTimeHour!,
        todo.dueTimeMinute!,
      );
      if (scheduledTime.isAfter(DateTime.now())) {
        // One-time notification — fires only at the scheduled moment
        await PermissionService().scheduleOneTimeNotification(
          id: todo.id.hashCode,
          title: '⏰ Todo Reminder',
          body: todo.title,
          scheduledTime: scheduledTime,
        );
      }
    }
    return todo;
  }

  Future<void> updateTodo(TodoModel todo) async {
    await _db.updateTodo(todo);
    loadTodos();
    if (todo.hasDueTime && todo.dueDate != null) {
      final scheduledTime = DateTime(
        todo.dueDate!.year,
        todo.dueDate!.month,
        todo.dueDate!.day,
        todo.dueTimeHour!,
        todo.dueTimeMinute!,
      );
      if (scheduledTime.isAfter(DateTime.now())) {
        await PermissionService().scheduleOneTimeNotification(
          id: todo.id.hashCode,
          title: '⏰ Todo Reminder',
          body: todo.title,
          scheduledTime: scheduledTime,
        );
      } else {
        // Past time — cancel any stale notification
        await PermissionService().cancelNotification(todo.id.hashCode);
      }
    } else {
      await PermissionService().cancelNotification(todo.id.hashCode);
    }
  }

  Future<void> toggleComplete(TodoModel todo) async {
    final updated = todo.copyWith(
      isCompleted: !todo.isCompleted,
      completedAt: !todo.isCompleted ? DateTime.now() : null,
    );
    await _db.updateTodo(updated);
    loadTodos();
  }

  Future<void> deleteTodo(String id) async {
    await _db.deleteTodo(id);
    loadTodos();
    await PermissionService().cancelNotification(id.hashCode);
  }

  List<TodoModel> get todayTodos {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return state.where((todo) {
      if (todo.isCompleted) return false;
      if (todo.dueDate == null) return false;
      final dueDay = DateTime(
        todo.dueDate!.year,
        todo.dueDate!.month,
        todo.dueDate!.day,
      );
      return dueDay.isAtSameMomentAs(today) ||
          dueDay.isBefore(today);
    }).toList();
  }

  List<TodoModel> get upcomingTodos {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return state.where((todo) {
      if (todo.isCompleted) return false;
      if (todo.dueDate == null) return false;
      final dueDay = DateTime(
        todo.dueDate!.year,
        todo.dueDate!.month,
        todo.dueDate!.day,
      );
      return dueDay.isAfter(today);
    }).toList();
  }

  List<TodoModel> get completedTodos {
    return state.where((todo) => todo.isCompleted).toList();
  }

  int get overdueCount {
    return state.where((todo) => todo.isOverdue).length;
  }
}

final habitsProvider = StateNotifierProvider<HabitsNotifier, List<HabitModel>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return HabitsNotifier(db);
});

class HabitsNotifier extends StateNotifier<List<HabitModel>> {
  final DatabaseService _db;

  HabitsNotifier(this._db) : super([]) {
    loadHabits();
  }

  void loadHabits() {
    state = _db.getAllHabits();
  }

  Future<HabitModel> addHabit({
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
    final habit = await _db.createHabit(
      name: name,
      description: description,
      frequency: frequency,
      daysOfWeek: daysOfWeek,
      timesPerDay: timesPerDay,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      colorValue: colorValue,
      iconName: iconName,
    );
    loadHabits();
    if (habit.hasReminder) {
      // Daily repeating notification at the same time each day
      await PermissionService().scheduleDailyNotification(
        id: habit.id.hashCode,
        title: '🔔 Habit Reminder',
        body: 'Time for ${habit.name}!',
        hour: habit.reminderHour!,
        minute: habit.reminderMinute!,
      );
    }
    return habit;
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _db.updateHabit(habit);
    loadHabits();
    if (habit.hasReminder) {
      await PermissionService().scheduleDailyNotification(
        id: habit.id.hashCode,
        title: '🔔 Habit Reminder',
        body: 'Time for ${habit.name}!',
        hour: habit.reminderHour!,
        minute: habit.reminderMinute!,
      );
    } else {
      await PermissionService().cancelNotification(habit.id.hashCode);
    }
  }

  Future<void> deleteHabit(String id) async {
    await _db.deleteHabit(id);
    loadHabits();
    await PermissionService().cancelNotification(id.hashCode);
  }

  List<HabitModel> get todayHabits {
    final now = DateTime.now();
    return state.where((habit) => habit.isScheduledForDay(now)).toList();
  }
}

final habitLogsProvider = StateNotifierProvider<HabitLogsNotifier, List<HabitLogModel>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return HabitLogsNotifier(db);
});

class HabitLogsNotifier extends StateNotifier<List<HabitLogModel>> {
  final DatabaseService _db;

  HabitLogsNotifier(this._db) : super([]) {
    loadLogs();
  }

  void loadLogs() {
    state = _db.habitLogBox.values.toList();
  }

  List<HabitLogModel> getLogsForHabit(String habitId) {
    return _db.getHabitLogs(habitId);
  }

  int getStreak(HabitModel habit) {
    return _db.getHabitStreak(habit);
  }

  Future<void> completeHabit({
    required String habitId,
    String? note,
  }) async {
    await _db.logHabitCompletion(habitId: habitId, note: note);
    loadLogs();
  }

  bool isHabitCompletedToday(String habitId) {
    final today = DateTime.now();
    final logs = _db.getHabitLogs(habitId);
    return logs.any((log) => log.isSameDay(today));
  }

  int getCompletionCountToday(String habitId) {
    final today = DateTime.now();
    final logs = _db.getHabitLogs(habitId);
    return logs.where((log) => log.isSameDay(today)).fold(0, (sum, log) => sum + log.count);
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<CategoryModel>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return CategoriesNotifier(db);
});

class CategoriesNotifier extends StateNotifier<List<CategoryModel>> {
  final DatabaseService _db;

  CategoriesNotifier(this._db) : super([]) {
    loadCategories();
  }

  void loadCategories() {
    state = _db.getAllCategories();
  }

  Future<void> addCategory({
    required String name,
    int colorValue = 0xFFB0B0B0,
    String iconName = 'folder',
  }) async {
    await _db.createCategory(
      name: name,
      colorValue: colorValue,
      iconName: iconName,
    );
    loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
    loadCategories();
  }
}

final selectedTabProvider = StateProvider<int>((ref) => 0);

final todoFilterProvider = StateProvider<int>((ref) => 0);