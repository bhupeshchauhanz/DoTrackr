import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../widgets/premium_card.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _selectedView = 0;
  final List<String> _viewOptions = ['Weekly', 'Monthly', 'Yearly'];
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(todosProvider);
    final habits = ref.watch(habitsProvider);
    final habitLogs = ref.watch(habitLogsProvider);

    final completedTodos = todos.where((t) => t.isCompleted).length;
    final totalTodos = todos.length;
    final todoCompletionRate = totalTodos > 0 ? completedTodos / totalTodos : 0.0;

    int longestStreak = 0;
    String topHabit = '';
    for (final habit in habits) {
      final streak = ref.read(habitLogsProvider.notifier).getStreak(habit);
      if (streak > longestStreak) {
        longestStreak = streak;
        topHabit = habit.name;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Screenshot(
          controller: _screenshotController,
          child: SingleChildScrollView(
            child: Container(
              color: AppColors.backgroundPrimary,
              padding: const EdgeInsets.all(24),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Statistics',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _shareHeatmap,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.share_outlined,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: PremiumCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tasks Completed',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$completedTodos',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'of $totalTodos total',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PremiumCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Completion Rate',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(todoCompletionRate * 100).toInt()}%',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            Text(
                              'tasks done',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PremiumCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Best Streak',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$longestStreak',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                            Text(
                              topHabit.isEmpty ? 'no habits yet' : 'days',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PremiumCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Habits',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${habits.length}',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'habits tracked',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Activity',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: _viewOptions.asMap().entries.map((entry) {
                        final isSelected = _selectedView == entry.key;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedView = entry.key;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              entry.value,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? AppColors.backgroundPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: _buildActivityChart(),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Habit Heatmap',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _shareHeatmap,
                          icon: const Icon(
                            Icons.share,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getHeatmapTitle(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildHeatmap(habitLogs),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Less',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildHeatmapLegend(),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildActivityChart() {
    final now = DateTime.now();
    final dailyCompletions = <int, int>{};

    if (_selectedView == 0) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        dailyCompletions[i] = _getCompletionCountForDate(day);
      }

      return SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: dailyCompletions.values.isEmpty
                ? 5
                : (dailyCompletions.values.reduce((a, b) => a > b ? a : b) + 2)
                    .toDouble(),
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    if (value >= 0 && value < 7) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          days[value.toInt()],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: List.generate(7, (index) {
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: dailyCompletions[index]?.toDouble() ?? 0,
                    color: AppColors.textPrimary,
                    width: 24,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      );
    } else if (_selectedView == 1) {
      final monthDays = DateTime(now.year, now.month + 1, 0).day;
      final weekDays = [0, 0, 0, 0, 0, 0, 0];
      for (int i = 1; i <= monthDays; i++) {
        final date = DateTime(now.year, now.month, i);
        if (date.isAfter(now)) continue;
        weekDays[date.weekday - 1] += 1;
      }

      return SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: weekDays.reduce((a, b) => a > b ? a : b).toDouble() + 2,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    if (value >= 0 && value < 7) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          days[value.toInt()].substring(0, 1),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: List.generate(7, (index) {
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: weekDays[index].toDouble(),
                    color: AppColors.textPrimary,
                    width: 32,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      );
    } else {
      final monthCompletions = <int, int>{};
      for (int m = 1; m <= 12; m++) {
        monthCompletions[m] = 0;
        final daysInMonth = DateTime(now.year, m + 1, 0).day;
        for (int d = 1; d <= daysInMonth; d++) {
          final date = DateTime(now.year, m, d);
          if (date.isAfter(now)) continue;
          monthCompletions[m] = monthCompletions[m]! + _getCompletionCountForDate(date);
        }
      }

      return SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: monthCompletions.values.isEmpty
                ? 10
                : (monthCompletions.values.reduce((a, b) => a > b ? a : b) + 5)
                    .toDouble(),
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final months = [
                      'J',
                      'F',
                      'M',
                      'A',
                      'M',
                      'J',
                      'J',
                      'A',
                      'S',
                      'O',
                      'N',
                      'D'
                    ];
                    if (value >= 0 && value < 12) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          months[value.toInt()],
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: List.generate(12, (index) {
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: monthCompletions[index + 1]?.toDouble() ?? 0,
                    color: AppColors.textPrimary,
                    width: 16,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      );
    }
  }

  int _getCompletionCountForDate(DateTime date) {
    final habitLogs = ref.read(habitLogsProvider);
    return habitLogs
        .where((log) =>
            log.completedAt.year == date.year &&
            log.completedAt.month == date.month &&
            log.completedAt.day == date.day)
        .length;
  }

  String _getHeatmapTitle() {
    switch (_selectedView) {
      case 0:
        return 'This Week';
      case 1:
        return DateFormat('MMMM yyyy').format(DateTime.now());
      case 2:
        return DateFormat('yyyy').format(DateTime.now());
      default:
        return 'Activity';
    }
  }

  Widget _buildHeatmap(List<dynamic> habitLogs) {
    final now = DateTime.now();
    final weeks = <List<DateTime>>[];

    int numWeeks = 4;
    if (_selectedView == 1) {
      numWeeks = 4;
    } else if (_selectedView == 2) {
      numWeeks = 12;
    }

    for (int w = numWeeks - 1; w >= 0; w--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + (w * 7)));
      final weekDays = <DateTime>[];
      for (int d = 0; d < 7; d++) {
        final day = weekStart.add(Duration(days: d));
        if (!day.isAfter(now)) {
          weekDays.add(day);
        }
      }
      weeks.add(weekDays);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: weeks.map((week) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: week.map((day) {
                final count = habitLogs.where((log) {
                  return log.completedAt.year == day.year &&
                      log.completedAt.month == day.month &&
                      log.completedAt.day == day.day;
                }).length;

                final intensity = count == 0
                    ? 0.0
                    : count <= 2
                        ? 0.3
                        : count <= 5
                            ? 0.6
                            : 1.0;

                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: intensity),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.0),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: AppColors.border),
          ),
        ),
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 1.0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Future<void> _shareHeatmap() async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/dotrackr_stats.png';
      
      final image = await _screenshotController.capture(delay: const Duration(milliseconds: 10));
      if (image != null) {
        final file = await File(imagePath).create();
        await file.writeAsBytes(image);
        
        final caption = 'Track your habits with ${AppConstants.appName}. Download now!\nMade by ${AppConstants.developerName}';
        await Share.shareXFiles([XFile(imagePath)], text: caption);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing stats: $e')),
        );
      }
    }
  }
}