import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../providers/user_provider.dart';
import '../../widgets/habit_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/premium_card.dart';
import 'add_habit_screen.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  late DateTime _selectedDate;
  late PageController _calendarController;
  late ScrollController _horizontalCalendarController;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    final now = DateTime.now();
    final monthOffset = (now.year - 2020) * 12 + now.month - 1;
    _calendarController = PageController(initialPage: monthOffset);
    // 180 days ago to today. Each item is 48 width + 8 margin = 56.0
    // We want to start at index 180 (Today)
    _horizontalCalendarController = ScrollController(initialScrollOffset: 180 * 56.0);
  }

  @override
  void dispose() {
    _calendarController.dispose();
    _horizontalCalendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider);
    final now = DateTime.now();
    final user = ref.watch(userProvider);
    final joinedAt = user?.joinedAt ?? now;

    final habitsForSelectedDate = habits.where((h) => h.isScheduledForDay(_selectedDate)).toList();
    final isSelectedToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final isFutureDate = _selectedDate.isAfter(now);
    final isBeforeJoinDate = _selectedDate.isBefore(joinedAt);

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
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      controller: _horizontalCalendarController,
                      scrollDirection: Axis.horizontal,
                      itemCount: 365,
                      itemBuilder: (context, index) {
                        final date = DateTime.now().subtract(Duration(days: 180 - index));
                        return _buildDateChip(date, isSelectedDate(date));
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PremiumCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _navigateMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    GestureDetector(
                      onTap: _showMonthPicker,
                      child: Column(
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(_selectedDate),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getSelectedDateLabel(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isCurrentMonth()
                          ? null
                          : () => _navigateMonth(1),
                      icon: Icon(
                        Icons.chevron_right,
                        color: _isCurrentMonth()
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                            builder: (_) => const AddHabitScreen(),
                          ),
                        );
                      },
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Completed',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pending',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const Spacer(),
                              if (isFutureDate || isBeforeJoinDate)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Not available',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: habitsForSelectedDate.length,
                            itemBuilder: (context, index) {
                              final habit = habitsForSelectedDate[index];
                              final streak = ref.read(habitLogsProvider.notifier).getStreak(habit);
                              final isCompleted = _isHabitCompletedOnDate(habit.id);
                              final canInteract = !isFutureDate && !isBeforeJoinDate;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Opacity(
                                  opacity: canInteract ? 1.0 : 0.5,
                                  child: HabitTile(
                                    habit: habit,
                                    streak: streak,
                                    isCompletedToday: isCompleted,
                                    onComplete: canInteract
                                        ? () {
                                            if (!isCompleted) {
                                              ref
                                                  .read(habitLogsProvider.notifier)
                                                  .completeHabit(habitId: habit.id);
                                            }
                                          }
                                        : null,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddHabitScreen(habit: habit),
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
            MaterialPageRoute(
              builder: (_) => const AddHabitScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateChip(DateTime date, bool isSelected) {
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;
    final habitLogs = ref.watch(habitLogsProvider);
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
          color: isSelected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.border,
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
                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColors.backgroundPrimary
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

  bool isSelectedDate(DateTime date) {
    return _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;
  }

  String _getSelectedDateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (selected.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (selected.isBefore(today)) {
      final diff = today.difference(selected).inDays;
      if (diff == 1) return 'Yesterday';
      return '$diff days ago';
    } else {
      final diff = selected.difference(today).inDays;
      if (diff == 1) return 'Tomorrow';
      return 'In $diff days';
    }
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _selectedDate.year == now.year && _selectedDate.month == now.month;
  }

  void _navigateMonth(int delta) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + delta,
        _selectedDate.day,
      );
    });
  }

  void _showMonthPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
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
}