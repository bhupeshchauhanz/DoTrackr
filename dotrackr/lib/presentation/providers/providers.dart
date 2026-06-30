import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/todo_model.dart';
import '../../data/models/habit_model.dart';
import '../../data/models/habit_log_model.dart';
import '../../data/models/category_model.dart';
import '../../data/services/database_service.dart';
import '../../data/services/notification_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final todosProvider = StateNotifierProvider<TodosNotifier, List<TodoModel>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return TodosNotifier(db);
});

class TodosNotifier extends StateNotifier<List<TodoModel>> {
  final DatabaseService _db;

  static int _notifIdFor(String id, int offset) {
    return (id.hashCode & 0x3FFFFFFF) + offset;
  }

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
    List<String> reminderTimes = const [],
  }) async {
    final todo = await _db.createTodo(
      title: title,
      description: description,
      dueDate: dueDate,
      dueTimeHour: dueTimeHour,
      dueTimeMinute: dueTimeMinute,
      priority: priority,
      categoryId: categoryId,
      reminderTimes: reminderTimes,
    );
    loadTodos();
    _scheduleTodoNotifications(todo);
    return todo;
  }

  Future<void> updateTodo(TodoModel todo) async {
    await _db.updateTodo(todo);
    loadTodos();
    _cancelTodoNotifications(todo.id);
    _scheduleTodoNotifications(todo);
  }

  void _cancelTodoNotifications(String id) {
    NotificationService().cancelItemNotifications('todo', id);
  }

  void _scheduleTodoNotifications(TodoModel todo) {
    final base = _notifIdFor(todo.id, 0);
    int offset = 0;
    if (todo.hasDueTime && todo.dueDate != null) {
      final scheduledTime = DateTime(
        todo.dueDate!.year,
        todo.dueDate!.month,
        todo.dueDate!.day,
        todo.dueTimeHour!,
        todo.dueTimeMinute!,
      );
      if (scheduledTime.isAfter(DateTime.now())) {
        NotificationService().scheduleOneTime(
          id: base + offset,
          title: 'Reminder: ${todo.title}',
          body: 'Tap to view your todo.',
          scheduledTime: scheduledTime,
          payload: buildPayload(type: 'todo', id: todo.id, action: 'reminder'),
        );
      }
      offset++;
    }
    if (todo.dueDate != null && todo.reminderTimes.isNotEmpty) {
      for (int i = 0; i < todo.reminderTimes.length && offset < 6; i++) {
        final parts = todo.reminderTimes[i].split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final scheduledTime = DateTime(
          todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day, hour, minute);
        final now = DateTime.now();
        var finalScheduledTime = scheduledTime;
        if (scheduledTime.isBefore(now) && scheduledTime.isAfter(now.subtract(const Duration(minutes: 1)))) {
          finalScheduledTime = now.add(const Duration(seconds: 5));
        }
        if (finalScheduledTime.isAfter(now)) {
          NotificationService().scheduleOneTime(
            id: base + i + 1,
            title: todo.title,
            body: 'Reminder for your task',
            scheduledTime: finalScheduledTime,
            payload: buildPayload(type: 'todo', id: todo.id, action: 'alarm', title: todo.title),
          );
        }
        offset++;
      }
    }
  }

  Future<void> toggleComplete(TodoModel todo) async {
    final updated = todo.copyWith(
      isCompleted: !todo.isCompleted,
      completedAt: !todo.isCompleted ? DateTime.now() : null,
    );
    await _db.updateTodo(updated);
    loadTodos();
    if (updated.isCompleted) {
      _cancelTodoNotifications(todo.id);
    } else {
      _scheduleTodoNotifications(updated);
    }
  }

  Future<void> deleteTodo(String id) async {
    await _db.deleteTodo(id);
    loadTodos();
    _cancelTodoNotifications(id);
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
  return HabitsNotifier(db, ref);
});

class HabitsNotifier extends StateNotifier<List<HabitModel>> {
  final DatabaseService _db;
  final Ref _ref;

  HabitsNotifier(this._db, this._ref) : super([]) {
    loadHabits();
  }

  void loadHabits() {
    final habits = _db.getAllHabits();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final habit in habits) {
      final updatedDate = DateTime(habit.updatedAt.year, habit.updatedAt.month, habit.updatedAt.day);
      if (updatedDate.isBefore(today)) {
        bool habitUpdated = false;
        if (habit.durationScope == 'today' && habit.durationMinutes > 0) {
          habit.durationMinutes = 0;
          habit.durationScope = 'all';
          habitUpdated = true;
        }
        if (habit.reminderTimes.isNotEmpty) {
          final newReminders = <String>[];
          for (final rt in habit.reminderTimes) {
            final parts = rt.split('|');
            final scope = parts.length > 1 ? parts[1] : 'all';
            if (scope != 'today') {
              newReminders.add(rt);
            }
          }
          if (newReminders.length != habit.reminderTimes.length) {
            _cancelHabitNotifications(habit.id);
            habit.reminderTimes = newReminders;
            habit.reminderScope = 'all'; // deprecated global scope
            habitUpdated = true;
          }
        }
        if (habitUpdated) {
          habit.updatedAt = now;
          _db.updateHabit(habit);
        }
      }
    }
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
    List<String> reminderTimes = const [],
    int colorValue = 0xFFFFFFFF,
    String iconName = 'check_circle',
    int durationMinutes = 0,
    String durationScope = 'all',
    String reminderScope = 'all',
  }) async {
    final habit = await _db.createHabit(
      name: name,
      description: description,
      frequency: frequency,
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
    loadHabits();
    _scheduleHabitNotifications(habit);
    return habit;
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _db.updateHabit(habit);
    loadHabits();
    _cancelHabitNotifications(habit.id);
    _scheduleHabitNotifications(habit);
  }

  Future<void> deleteHabit(String id) async {
    await _db.deleteHabit(id);
    loadHabits();
    _cancelHabitNotifications(id);
  }

  void rescheduleHabit(HabitModel habit) {
    _cancelHabitNotifications(habit.id);
    _scheduleHabitNotifications(habit);
  }

  void _cancelHabitNotifications(String id) {
    NotificationService().cancelItemNotifications('habit', id);
  }

  void _scheduleHabitNotifications(HabitModel habit) {
    final todayCompleted = _ref.read(habitLogsProvider.notifier).isHabitCompletedToday(habit.id);
    final base = (habit.id.hashCode & 0x1FFFFFFF) + 0x40000000;
    
    final now = DateTime.now();
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      if (dayOffset == 0 && todayCompleted) {
        continue;
      }
      if (!habit.isScheduledForDay(targetDate)) {
        continue;
      }
      for (int i = 0; i < habit.reminderTimes.length && i < 10; i++) {
        final rt = habit.reminderTimes[i];
        final parts = rt.split('|');
        final timeStr = parts[0];
        final scope = parts.length > 1 ? parts[1] : 'all';
        if (scope == 'today' && dayOffset > 0) {
          continue; // skip "Only Today" reminders for future days
        }
        final timeParts = timeStr.split(':');
        final h = int.parse(timeParts[0]);
        final m = int.parse(timeParts[1]);
        final scheduledTime = DateTime(targetDate.year, targetDate.month, targetDate.day, h, m);
        final now = DateTime.now();
        var finalScheduledTime = scheduledTime;
        if (scheduledTime.isBefore(now) && scheduledTime.isAfter(now.subtract(const Duration(minutes: 1)))) {
          finalScheduledTime = now.add(const Duration(seconds: 5));
        }
        if (finalScheduledTime.isAfter(now)) {
          NotificationService().scheduleOneTime(
            id: base + (dayOffset * 10) + i,
            title: habit.name,
            body: 'Time for your habit!',
            scheduledTime: finalScheduledTime,
            payload: buildPayload(type: 'habit', id: habit.id, action: 'alarm', title: habit.name),
          );
        }
      }
    }
  }

  List<HabitModel> get todayHabits {
    final now = DateTime.now();
    return state.where((habit) => habit.isScheduledForDay(now)).toList();
  }
}

final habitLogsProvider = StateNotifierProvider<HabitLogsNotifier, List<HabitLogModel>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return HabitLogsNotifier(db, ref);
});

class HabitLogsNotifier extends StateNotifier<List<HabitLogModel>> {
  final DatabaseService _db;
  final Ref _ref;

  HabitLogsNotifier(this._db, this._ref) : super([]) {
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
    int durationSeconds = 0,
  }) async {
    if (durationSeconds == 0) {
      final allHabits = _db.getAllHabits();
      final habit = allHabits.cast<HabitModel?>().firstWhere(
        (h) => h?.id == habitId,
        orElse: () => null,
      );
      if (habit != null && habit.hasTimer) {
        durationSeconds = habit.durationMinutes * 60;
      }
    }
    await _db.logHabitCompletion(habitId: habitId, note: note, durationSeconds: durationSeconds);
    NotificationService().cancelItemNotifications('habit', habitId);
    loadLogs();

    final allHabits = _db.getAllHabits();
    final habit = allHabits.cast<HabitModel?>().firstWhere((h) => h?.id == habitId, orElse: () => null);
    if (habit != null) {
      _ref.read(habitsProvider.notifier).rescheduleHabit(habit);
    }
  }

  Future<void> uncompleteHabit(String habitId) async {
    final today = DateTime.now();
    final logs = _db.getHabitLogs(habitId);
    final logsToRemove = logs.where((log) =>
        log.completedAt.year == today.year &&
        log.completedAt.month == today.month &&
        log.completedAt.day == today.day);
    for (final log in logsToRemove) {
      await _db.habitLogBox.delete(log.id);
    }
    loadLogs();

    final allHabits = _db.getAllHabits();
    final habit = allHabits.cast<HabitModel?>().firstWhere((h) => h?.id == habitId, orElse: () => null);
    if (habit != null) {
      _ref.read(habitsProvider.notifier).rescheduleHabit(habit);
    }
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

  /// Get total duration in seconds spent on a habit (all time)
  int getTotalDuration(String habitId) {
    final logs = _db.getHabitLogs(habitId);
    return logs.fold(0, (sum, log) => sum + log.durationSeconds);
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