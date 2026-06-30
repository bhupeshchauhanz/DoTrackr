import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/habit_model.dart';
import '../../../data/models/habit_log_model.dart';
import '../../providers/providers.dart';
import '../../widgets/habit_tile.dart';
import '../../widgets/habit_timer_dialog.dart';
import '../../widgets/empty_state.dart';
import 'add_habit_screen.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  late DateTime _selectedDate;
  final ScrollController _dateScrollController = ScrollController();
  bool _hasScrolled = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  /// Returns all days in the month including future days
  List<DateTime> _getDaysInMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    final days = <DateTime>[];
    for (int d = firstDay.day; d <= lastDay.day; d++) {
      days.add(DateTime(date.year, date.month, d));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider);
    final now = DateTime.now();
    final habitLogs = ref.watch(habitLogsProvider);

    final daysInMonth = _getDaysInMonth(_selectedDate);
    final habitsForSelectedDate = habits.where((h) {
      if (!h.isScheduledForDay(_selectedDate)) return false;
      // Only hide habits created AFTER this date (not scheduled yet)
      final createdDay = DateTime(
          h.createdAt.year, h.createdAt.month, h.createdAt.day);
      final selectedDay = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day);
      if (createdDay.isAfter(selectedDay)) return false;
      return true;
    }).toList();

    final todayOnly = DateTime(now.year, now.month, now.day);
    final selectedOnly = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);
    final isPastDate = selectedOnly.isBefore(todayOnly);
    final isFutureDate = selectedOnly.isAfter(todayOnly);

    if (!_hasScrolled) {
      _hasScrolled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToSelected();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Habits',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showMonthPicker,
                        icon: const Icon(Icons.calendar_month, size: 20),
                        label: Text(
                          DateFormat('MMM yyyy').format(_selectedDate),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Date picker row (no Today button)
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      controller: _dateScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: daysInMonth.length,
                      itemBuilder: (context, index) {
                        final date = daysInMonth[index];
                        return _buildDateChip(
                            date, _isSelectedDate(date), habitLogs);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: habits.isEmpty
                  ? EmptyState(
                      icon: Icons.track_changes,
                      title: 'No habits yet',
                      message: 'Create your first habit to start tracking',
                      actionLabel: 'Add Habit',
                      onAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddHabitScreen()),
                        );
                      },
                    )
                  : habitsForSelectedDate.isEmpty
                      ? EmptyState(
                          icon: Icons.event_busy,
                          title: isFutureDate
                              ? 'Upcoming day'
                              : 'No habits scheduled',
                          message: isFutureDate
                              ? 'No habits are scheduled for this day yet'
                              : 'No habits were scheduled for this day',
                        )
                      : Column(
                          children: [
                            // Legend and status
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Completed',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.success)),
                                  const SizedBox(width: 16),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Pending',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color:
                                              AppColors.textTertiary)),
                                  const Spacer(),
                                  if (isPastDate)
                                    _buildStatusBadge(
                                        'Past', AppColors.textTertiary),
                                  if (isFutureDate)
                                    _buildStatusBadge(
                                        'Upcoming', AppColors.priorityMedium),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24),
                                itemCount:
                                    habitsForSelectedDate.length,
                                itemBuilder: (context, index) {
                                  final habit =
                                      habitsForSelectedDate[index];
                                  final streak = ref
                                      .read(habitLogsProvider.notifier)
                                      .getStreak(habit);
                                  final isCompleted =
                                      _isHabitCompletedOnDate(
                                          habit.id);

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 12),
                                    child: Opacity(
                                      opacity:
                                          (isPastDate || isFutureDate)
                                              ? 0.6
                                              : 1.0,
                                      child: HabitTile(
                                        habit: habit,
                                        streak: streak,
                                        isCompletedToday: isCompleted,
                                        onComplete:
                                            (isPastDate || isFutureDate)
                                                ? null
                                                : () {
                                                    if (isCompleted) {
                                                      _uncompleteHabit(
                                                          habit.id);
                                                    } else {
                                                      ref
                                                          .read(habitLogsProvider
                                                              .notifier)
                                                          .completeHabit(
                                                              habitId:
                                                                  habit
                                                                      .id);
                                                    }
                                                  },
                                        onStartTimer:
                                            (isPastDate || isFutureDate || !habit.hasTimer)
                                                ? null
                                                : () => _startHabitTimer(habit),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AddHabitScreen(
                                                      habit: habit),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddHabitScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10, color: color),
      ),
    );
  }

  void _scrollToSelected() {
    if (!mounted || !_dateScrollController.hasClients) return;
    final daysInMonth = _getDaysInMonth(_selectedDate);
    final selectedIndex = daysInMonth.indexWhere((d) =>
        d.year == _selectedDate.year &&
        d.month == _selectedDate.month &&
        d.day == _selectedDate.day);
    if (selectedIndex >= 0) {
      final maxScroll = _dateScrollController.position.maxScrollExtent;
      final targetOffset = (selectedIndex * 56.0) - 80;
      final offset =
          maxScroll > 0 ? targetOffset.clamp(0.0, maxScroll) : 0.0;
      _dateScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildDateChip(
      DateTime date, bool isSelected, List<HabitLogModel> habitLogs) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));
    final hasLogs = habitLogs.any((log) =>
        log.completedAt.year == date.year &&
        log.completedAt.month == date.month &&
        log.completedAt.day == date.day);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      child: Container(
        width: 48,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.textPrimary
              : isToday
                  ? AppColors.surfaceElevated
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.textPrimary
                : isToday
                    ? AppColors.textSecondary
                    : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppConstants.weekDays[date.weekday - 1],
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isSelected
                    ? AppColors.backgroundPrimary
                    : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight:
                    isToday || isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColors.backgroundPrimary
                    : isFuture
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: hasLogs
                    ? (isSelected
                        ? AppColors.backgroundPrimary
                        : AppColors.success)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSelectedDate(DateTime date) {
    return _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;
  }

  void _showMonthPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _hasScrolled = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToSelected();
      });
    }
  }

  bool _isHabitCompletedOnDate(String habitId) {
    final habitLogs = ref.watch(habitLogsProvider);
    return habitLogs.any((log) =>
        log.habitId == habitId &&
        log.completedAt.year == _selectedDate.year &&
        log.completedAt.month == _selectedDate.month &&
        log.completedAt.day == _selectedDate.day);
  }

  Future<void> _uncompleteHabit(String habitId) async {
    await ref.read(habitLogsProvider.notifier).uncompleteHabit(habitId);
  }

  Future<void> _startHabitTimer(HabitModel habit) async {
    final secondsSpent = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => HabitTimerDialog(habit: habit),
      ),
    );
    if (secondsSpent != null && secondsSpent > 0) {
      // Auto-complete the habit with the time spent
      await ref.read(habitLogsProvider.notifier).completeHabit(
        habitId: habit.id,
        durationSeconds: secondsSpent,
      );
    }
  }
}
