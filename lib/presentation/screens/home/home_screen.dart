import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../providers/user_provider.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/todo_tile.dart';
import '../../widgets/habit_tile.dart';
import '../todos/add_todo_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todosProvider);
    final habits = ref.watch(habitsProvider);
    final habitLogs = ref.watch(habitLogsProvider);
    final user = ref.watch(userProvider);

    final firstName = user?.firstName ?? 'User';
    final profileImagePath = user?.profileImagePath ?? '';
    final hasProfileImage = profileImagePath.isNotEmpty && _fileExists(profileImagePath);

    final greeting = _getGreeting();

    final todayTodos = todos.where((t) {
      if (t.isCompleted) return false;
      if (t.dueDate == null) return false;
      final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      return dueDay.isAtSameMomentAs(todayOnly) || dueDay.isBefore(todayOnly);
    }).toList();

    final overdueTodos = todos.where((t) => t.isOverdue).toList();
    final completedToday = todos.where((t) {
      if (!t.isCompleted || t.completedAt == null) return false;
      final now = DateTime.now();
      return t.completedAt!.year == now.year &&
          t.completedAt!.month == now.month &&
          t.completedAt!.day == now.day;
    }).length;

    final todayHabits = habits.where((h) => h.isScheduledForDay(DateTime.now())).toList();
    final completedHabits = todayHabits.where((h) {
      final today = DateTime.now();
      return habitLogs.any((log) => 
          log.habitId == h.id &&
          log.completedAt.year == today.year &&
          log.completedAt.month == today.month &&
          log.completedAt.day == today.day);
    }).length;

    final totalHabits = todayHabits.length;
    final completionRate = totalHabits > 0 ? completedHabits / totalHabits : 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting,',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              firstName,
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: hasProfileImage
                                  ? Image.file(
                                      File(profileImagePath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person_outline,
                                          color: AppColors.textPrimary,
                                        );
                                      },
                                    )
                                  : const Icon(
                                      Icons.person_outline,
                                      color: AppColors.textPrimary,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'Due Today',
                            value: '${todayTodos.length}',
                            subtitle: overdueTodos.isNotEmpty
                                ? '${overdueTodos.length} overdue'
                                : 'All on track',
                            color: overdueTodos.isNotEmpty
                                ? AppColors.error
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'Completed',
                            value: '$completedToday',
                            subtitle: 'tasks today',
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PremiumCard(
                      child: Row(
                        children: [
                          CircularPercentIndicator(
                            radius: 35,
                            lineWidth: 6,
                            percent: completionRate.clamp(0.0, 1.0),
                            center: Text(
                              '${(completionRate * 100).toInt()}%',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            progressColor: AppColors.success,
                            backgroundColor: AppColors.surfaceElevated,
                            circularStrokeCap: CircularStrokeCap.round,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Habits Today',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$completedHabits of $totalHabits completed',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pending Tasks',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(selectedTabProvider.notifier).state = 1;
                          },
                          child: Text(
                            'See all',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (todayTodos.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: PremiumCard(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'All caught up!',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No tasks due today. Great job!',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= todayTodos.length || index >= 5) return null;
                    final todo = todayTodos[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TodoTile(
                          todo: todo,
                          onToggleComplete: () {
                            ref.read(todosProvider.notifier).toggleComplete(todo);
                          },
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddTodoScreen(todo: todo),
                              ),
                            );
                          },
                          onDelete: () {
                            ref.read(todosProvider.notifier).deleteTodo(todo.id);
                          },
                        ),
                      ),
                    );
                  },
                  childCount: todayTodos.length > 5 ? 5 : todayTodos.length,
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Today's Habits",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(selectedTabProvider.notifier).state = 2;
                          },
                          child: Text(
                            'See all',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (todayHabits.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: PremiumCard(
                    child: Column(
                      children: [
                        Icon(
                          Icons.track_changes,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No habits for today',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create habits to build consistency',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= todayHabits.length || index >= 3) return null;
                    final habit = todayHabits[index];
                    final streak = ref.read(habitLogsProvider.notifier).getStreak(habit);
                    final isCompleted = ref.read(habitLogsProvider.notifier).isHabitCompletedToday(habit.id);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: HabitTile(
                          habit: habit,
                          streak: streak,
                          isCompletedToday: isCompleted,
                          onComplete: () {
                            if (isCompleted) {
                              ref.read(habitLogsProvider.notifier).uncompleteHabit(habit.id);
                            } else {
                              ref.read(habitLogsProvider.notifier).completeHabit(habitId: habit.id);
                            }
                          },
                        ),
                      ),
                    );
                  },
                  childCount: todayHabits.length > 3 ? 3 : todayHabits.length,
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  bool _fileExists(String path) {
    try {
      final file = File(path);
      return file.existsSync();
    } catch (e) {
      return false;
    }
  }
}