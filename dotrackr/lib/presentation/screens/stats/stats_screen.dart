import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/habit_log_model.dart';
import '../../../data/models/habit_model.dart';
import '../../providers/providers.dart';

// W = current week (Mon–Sun), M = current month, Y = current calendar year
enum StatsPeriod { week, month, year }

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  final ScreenshotController _fullController = ScreenshotController();
  final ScreenshotController _activityController = ScreenshotController();
  final ScreenshotController _heatmapController = ScreenshotController();
  final ScrollController _heatmapScrollController = ScrollController();

  StatsPeriod _period = StatsPeriod.week;
  String? _tappedDate;

  static const _accent = AppColors.success;
  static final _heatmapColors = [
    Colors.black, // Level 0 — empty cell: pure black
    AppColors.success.withValues(alpha: 0.25),
    AppColors.success.withValues(alpha: 0.50),
    AppColors.success.withValues(alpha: 0.75),
    AppColors.success,
  ];



  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToRecent());
  }

  @override
  void dispose() {
    _heatmapScrollController.dispose();
    super.dispose();
  }

  void _scrollToRecent() {
    if (_heatmapScrollController.hasClients) {
      _heatmapScrollController.jumpTo(_heatmapScrollController.position.maxScrollExtent);
    }
  }

  // ─── Data helpers ──────────────────────────────────────────────────────────

  DateTime get _today => DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  /// Timeline bars: (labels, values) for the selected period.
  (List<String>, List<int>) _buildTimelineData(List<HabitLogModel> habitLogs) {
    final today = _today;
    final labels = <String>[];
    final values = <int>[];

    switch (_period) {
      case StatsPeriod.week:
        // Mon–Sun of the CURRENT week
        final monday = today.subtract(Duration(days: today.weekday - 1));
        for (int i = 0; i < 7; i++) {
          final day = monday.add(Duration(days: i));
          labels.add(DateFormat('E').format(day)); // Mon, Tue …
          values.add(habitLogs.where((log) =>
              log.completedAt.year == day.year &&
              log.completedAt.month == day.month &&
              log.completedAt.day == day.day).length);
        }

      case StatsPeriod.month:
        // Day 1 to today of the CURRENT month
        final daysInRange = today.day; // 1 → today.day
        final firstOfMonth = DateTime(today.year, today.month, 1);
        for (int i = 0; i < daysInRange; i++) {
          final day = firstOfMonth.add(Duration(days: i));
          labels.add(DateFormat('d').format(day));
          values.add(habitLogs.where((log) =>
              log.completedAt.year == day.year &&
              log.completedAt.month == day.month &&
              log.completedAt.day == day.day).length);
        }

      case StatsPeriod.year:
        // Jan → current month of CURRENT calendar year
        for (int m = 1; m <= today.month; m++) {
          final date = DateTime(today.year, m, 1);
          labels.add(DateFormat('MMM').format(date));
          values.add(habitLogs.where((log) =>
              log.completedAt.year == today.year &&
              log.completedAt.month == m).length);
        }
    }
    return (labels, values);
  }

  String get _periodLabel {
    switch (_period) {
      case StatsPeriod.week:
        final monday = _today.subtract(Duration(days: _today.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(monday)} – ${DateFormat('MMM d').format(sunday)}';
      case StatsPeriod.month:
        return DateFormat('MMMM yyyy').format(DateTime.now());
      case StatsPeriod.year:
        return '${DateTime.now().year}';
    }
  }

  String get _heatmapLabel {
    switch (_period) {
      case StatsPeriod.week: return 'This Week';
      case StatsPeriod.month: return DateFormat('MMMM yyyy').format(DateTime.now());
      case StatsPeriod.year: return '${DateTime.now().year} Calendar';
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider);
    final habitLogs = ref.watch(habitLogsProvider);

    final totalCompletions = habitLogs.length;

    // Streak calculations
    int bestStreak = 0;
    int currentStreak = 0;
    for (final h in habits) {
      final s = ref.read(habitLogsProvider.notifier).getStreak(h);
      if (s > bestStreak) bestStreak = s;
      final today = _today;
      final logDates = habitLogs
          .where((l) => l.habitId == h.id)
          .map((l) => DateTime(l.completedAt.year, l.completedAt.month, l.completedAt.day))
          .toSet();
      if (logDates.contains(today) || logDates.contains(today.subtract(const Duration(days: 1)))) {
        int streak = 0;
        for (int d = 0; d < 365; d++) {
          if (logDates.contains(today.subtract(Duration(days: d)))) {
            streak++;
          } else {
            break;
          }
        }
        if (streak > currentStreak) currentStreak = streak;
      }
    }

    final (activityLabels, activityValues) = _buildTimelineData(habitLogs);
    final maxActivity = activityValues.fold(0, (a, b) => a > b ? a : b);
    final maxY = (maxActivity * 1.3).ceilToDouble().clamp(3.0, double.infinity);
    final hasData = habitLogs.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Screenshot(
            controller: _fullController,
            child: Container(
              color: AppColors.backgroundPrimary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildOverviewCard(currentStreak, bestStreak, totalCompletions, habits.length),
                  const SizedBox(height: 24),
                  _buildPeriodPill(),
                  const SizedBox(height: 24),
                  if (!hasData) ...[
                    _buildEmptyState(),
                  ] else ...[
                    _sectionHeader('Completions Timeline', _periodLabel),
                    const SizedBox(height: 12),
                    _buildActivityCard(maxY, activityValues, activityLabels),
                    const SizedBox(height: 24),
                    _sectionHeader('Consistency Grid', _heatmapLabel),
                    const SizedBox(height: 12),
                    _buildHeatmapCard(habitLogs, currentStreak),
                    const SizedBox(height: 24),
                    if (habits.isNotEmpty) ...[
                      _sectionHeader('Habit Breakdown', null),
                      const SizedBox(height: 12),
                      _buildHabitBreakdownCard(habits, habitLogs),
                      const SizedBox(height: 24),
                    ],
                    if (habits.isNotEmpty && totalCompletions > 0) ...[
                      _buildTimeSpentCard(habits),
                      const SizedBox(height: 24),
                    ],
                    _sectionHeader('Trophy Room', null),
                    const SizedBox(height: 12),
                    _buildStreakDetailCard(bestStreak),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Statistics',
          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.share_outlined, size: 20, color: AppColors.textPrimary),
          ),
          onSelected: (v) => _shareStats(v),
          color: AppColors.surface,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'full', child: Text('Share Full Dashboard', style: TextStyle(color: AppColors.textPrimary))),
            PopupMenuItem(value: 'activity', child: Text('Share Timeline Only', style: TextStyle(color: AppColors.textPrimary))),
            PopupMenuItem(value: 'heatmap', child: Text('Share Consistency Grid', style: TextStyle(color: AppColors.textPrimary))),
          ],
        ),
      ],
    );
  }

  // ─── Overview Card ─────────────────────────────────────────────────────────

  Widget _buildOverviewCard(int currentStreak, int bestStreak, int totalCompletions, int habitsCount) {
    // 30-day completion rate
    final today = _today;
    final thirtyDaysAgo = today.subtract(const Duration(days: 29));
    final habitLogs = ref.read(habitLogsProvider);
    int scheduledCount = 0;
    for (final h in ref.read(habitsProvider)) {
      for (int i = 0; i < 30; i++) {
        if (h.isScheduledForDay(thirtyDaysAgo.add(Duration(days: i)))) {
          scheduledCount += h.timesPerDay;
        }
      }
    }
    final completedIn30 = habitLogs.where((log) =>
        !log.completedAt.isBefore(thirtyDaysAgo) && !log.completedAt.isAfter(today.add(const Duration(days: 1)))).length;
    final completionRate = scheduledCount == 0 ? 0.0 : (completedIn30 / scheduledCount).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Tooltip(
            message: '30-day completion rate\n$completedIn30 / $scheduledCount sessions',
            child: CircularPercentIndicator(
              radius: 46.0,
              lineWidth: 8.0,
              percent: completionRate,
              center: Text(
                "${(completionRate * 100).toStringAsFixed(0)}%",
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              progressColor: _accent,
              backgroundColor: AppColors.backgroundPrimary,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 1000,
              footer: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '30-day rate',
                  style: GoogleFonts.inter(fontSize: 9, color: AppColors.textTertiary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _overviewMetricRow(Icons.local_fire_department, 'Current Streak', '$currentStreak days', const Color(0xFFF97316)),
                const Divider(color: AppColors.border, height: 16),
                _overviewMetricRow(Icons.emoji_events, 'Best Streak', '$bestStreak days', const Color(0xFFFBBF24)),
                const Divider(color: AppColors.border, height: 16),
                _overviewMetricRow(Icons.check_circle, 'Completions', '$totalCompletions times', _accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewMetricRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  // ─── Period Pill ───────────────────────────────────────────────────────────

  Widget _buildPeriodPill() {
    final items = [
      (StatsPeriod.week, 'W'),
      (StatsPeriod.month, 'M'),
      (StatsPeriod.year, 'Y'),
    ];
    final alignmentX = -1.0 + (_period.index * 1.0);

    return Center(
      child: Container(
        width: 210,
        height: 42,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              alignment: Alignment(alignmentX, 0.0),
              child: FractionallySizedBox(
                widthFactor: 1 / 3,
                heightFactor: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: items.map((entry) {
                final period = entry.$1;
                final label = entry.$2;
                final isSelected = _period == period;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _period = period;
                      _tappedDate = null;
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToRecent());
                    }),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.backgroundPrimary : AppColors.textSecondary,
                        ),
                        child: Text(label),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section Header ────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, String? subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        if (subtitle != null)
          Flexible(
            child: Text(subtitle,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textTertiary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_graph, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Start tracking your habits',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete habits daily to see your\nactivity and progress here',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 24),
          _buildGhostChart(),
        ],
      ),
    );
  }

  Widget _buildGhostChart() {
    return SizedBox(
      height: 80,
      child: CustomPaint(
        size: const Size(double.infinity, 80),
        painter: _GhostChartPainter(),
      ),
    );
  }

  // ─── Activity Chart ────────────────────────────────────────────────────────

  Widget _buildActivityCard(double maxY, List<int> values, List<String> labels) {
    return Screenshot(
      controller: _activityController,
      child: Container(
        color: AppColors.backgroundPrimary,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.fromLTRB(8, 20, 8, 12),
              child: values.isEmpty
                  ? const SizedBox(height: 200, child: Center(child: Text('No data', style: TextStyle(color: AppColors.textTertiary))))
                  : _activityChart(maxY, values, labels),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityChart(double maxY, List<int> values, List<String> labels) {
    final barWidth = _period == StatsPeriod.week
        ? 28.0
        : _period == StatsPeriod.month
            ? 6.0
            : 14.0;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipRoundedRadius: 8,
              getTooltipColor: (_) => const Color(0xFF2A2A2A),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = groupIndex < labels.length ? labels[groupIndex] : '';
                final count = rod.toY.toInt();
                return BarTooltipItem(
                  '$label\n$count ${count == 1 ? 'completion' : 'completions'}',
                  GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                  // Month: show every 5th label to avoid crowding
                  if (_period == StatsPeriod.month && idx % 5 != 0 && idx != labels.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[idx],
                      style: GoogleFonts.inter(fontSize: 9, color: AppColors.textTertiary),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: (maxY / 4).clamp(1.0, double.infinity),
                getTitlesWidget: (value, _) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(value.toInt().toString(),
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY / 4).clamp(1.0, double.infinity),
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withValues(alpha: 0.04),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(values.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: barWidth,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: AppColors.backgroundPrimary,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ─── Heatmap Card ──────────────────────────────────────────────────────────

  Widget _buildHeatmapCard(List<HabitLogModel> habitLogs, int currentStreak) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_tappedDate != null)
                Expanded(
                  child: Text(_tappedDate!,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                ),
              if (currentStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.local_fire_department, size: 12, color: Color(0xFFF97316)),
                    const SizedBox(width: 3),
                    Text('$currentStreak day${currentStreak == 1 ? '' : 's'}',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFFF97316))),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHeatmapContent(habitLogs),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('Less ', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary)),
            ..._heatmapColors.map((color) => Container(
              width: 12, height: 12, margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
                border: color == Colors.black
                    ? Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5)
                    : null,
              ),
            )),
            Text(' More', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary)),
          ]),
        ],
      ),
    );
  }

  Widget _buildHeatmapContent(List<HabitLogModel> habitLogs, {bool isShare = false}) {
    final today = _today;

    int countForDay(DateTime day) => habitLogs.where((log) =>
        log.completedAt.year == day.year &&
        log.completedAt.month == day.month &&
        log.completedAt.day == day.day).length;

    int maxCompletions = 1;

    int level(int count) {
      if (count == 0) return 0;
      if (maxCompletions <= 1) return 4;
      if (maxCompletions == 2) return count == 1 ? 2 : 4;
      if (maxCompletions == 3) {
        if (count == 1) return 1;
        if (count == 2) return 3;
        return 4;
      }
      final ratio = count / maxCompletions;
      if (ratio <= 0.25) return 1;
      if (ratio <= 0.5) return 2;
      if (ratio <= 0.75) return 3;
      return 4;
    }

    Color cellColor(DateTime day) {
      final c = countForDay(day);
      if (c == 0) return Colors.black;
      return _heatmapColors[level(c)];
    }

    Widget tapCell(DateTime day, double size, {double radius = 4}) {
      final count = countForDay(day);
      final isToday = day == today;
      return GestureDetector(
        onTap: () => setState(() {
          _tappedDate = '${DateFormat('MMM d, yyyy').format(day)} — $count ${count == 1 ? 'completion' : 'completions'}';
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size, height: size,
          decoration: BoxDecoration(
            color: cellColor(day),
            borderRadius: BorderRadius.circular(radius),
            border: isToday
                ? Border.all(color: _accent, width: 2)
                : Border.all(
                    color: count == 0 ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
                    width: 0.5),
          ),
        ),
      );
    }

    // ────────────── WEEK VIEW ──────────────
    if (_period == StatsPeriod.week) {
      final monday = today.subtract(Duration(days: today.weekday - 1));
      final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
      maxCompletions = weekDays.fold(1, (m, d) => countForDay(d) > m ? countForDay(d) : m);

      return LayoutBuilder(builder: (ctx, constraints) {
        final available = constraints.maxWidth;
        const gap = 10.0;
        final size = (available - gap * 4) / 5;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: List.generate(5, (i) => Padding(
                padding: EdgeInsets.only(right: i < 4 ? gap : 0),
                child: tapCell(weekDays[i], size, radius: 10),
              )),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                tapCell(weekDays[5], size, radius: 10),
                const SizedBox(width: 10),
                tapCell(weekDays[6], size, radius: 10),
              ],
            ),
          ],
        );
      });
    }

    // ────────────── MONTH VIEW ──────────────
    if (_period == StatsPeriod.month) {
      final firstOfMonth = DateTime(today.year, today.month, 1);
      final daysInMonth = DateUtils.getDaysInMonth(today.year, today.month);
      final startOffset = firstOfMonth.weekday - 1;
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      for (int i = 0; i < daysInMonth; i++) {
        final d = DateTime(today.year, today.month, i + 1);
        if (!d.isAfter(today)) {
          final c = countForDay(d);
          if (c > maxCompletions) maxCompletions = c;
        }
      }

      return LayoutBuilder(builder: (ctx, constraints) {
        final available = constraints.maxWidth;
        const gap = 5.0;
        final cellSize = (available - gap * 6) / 7;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(7, (i) => SizedBox(
                width: cellSize + (i < 6 ? gap : 0),
                child: Center(
                  child: Text(dayNames[i],
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
                ),
              )),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                ...List.generate(startOffset, (_) => Container(
                  width: cellSize, height: cellSize,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
                  ),
                )),
                ...List.generate(daysInMonth, (i) {
                  final day = DateTime(today.year, today.month, i + 1);
                  if (day.isAfter(today)) {
                    return Container(
                      width: cellSize, height: cellSize,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
                      ),
                    );
                  }
                  return SizedBox(width: cellSize, height: cellSize, child: tapCell(day, cellSize, radius: 4));
                }),
              ],
            ),
          ],
        );
      });
    }

    // ────────────── YEAR VIEW (current calendar year, month by month, horizontal, compact) ──────────────
    final year = today.year;
    final monthsToShow = today.month; // Issue 2: show up to current month

    for (int m = 1; m <= monthsToShow; m++) {
      final days = DateUtils.getDaysInMonth(year, m);
      for (int d = 1; d <= days; d++) {
        final c = countForDay(DateTime(year, m, d));
        if (c > maxCompletions) maxCompletions = c;
      }
    }

    final double cellSize = isShare ? 12.0 : 16.0;
    final double cellGap = isShare ? 3.0 : 4.0;
    final double dayLabelWidth = isShare ? 20.0 : 24.0;
    const dayNames2 = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final monthWidgets = List.generate(monthsToShow, (monthIdx) {
      final month = monthIdx + 1;
      final firstDay = DateTime(year, month, 1);
      final daysInMonth = DateUtils.getDaysInMonth(year, month);
      final startOffset = firstDay.weekday - 1;

      final totalCells = startOffset + daysInMonth;
      final weekCount = (totalCells / 7).ceil();

      final grid = List.generate(weekCount, (w) =>
          List.generate(7, (d) {
            final cellIdx = w * 7 + d;
            if (cellIdx < startOffset) return null;
            final dayNum = cellIdx - startOffset + 1;
            if (dayNum > daysInMonth) return null;
            return DateTime(year, month, dayNum);
          }));

      return Padding(
        padding: EdgeInsets.only(right: (monthIdx < monthsToShow - 1 && !isShare) ? 16 : 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                SizedBox(
                  height: 14,
                  width: dayLabelWidth,
                  child: Text(
                    DateFormat('MMM').format(firstDay),
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
                ),
                ...List.generate(7, (i) => SizedBox(
                  width: dayLabelWidth,
                  height: cellSize + cellGap,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(dayNames2[i],
                        style: GoogleFonts.inter(fontSize: 7, color: AppColors.textTertiary)),
                  ),
                )),
              ],
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                ...List.generate(7, (dayIdx) => Row(
                  children: List.generate(weekCount, (weekIdx) {
                    final day = grid[weekIdx][dayIdx];
                    if (day == null) {
                      return Container(
                        width: cellSize,
                        height: cellSize,
                        margin: EdgeInsets.only(right: cellGap, bottom: cellGap),
                        color: Colors.transparent,
                      );
                    }
                    return Container(
                      width: cellSize, height: cellSize,
                      margin: EdgeInsets.only(right: cellGap, bottom: cellGap),
                      child: tapCell(day, cellSize, radius: 3),
                    );
                  }),
                )),
              ],
            ),
          ],
        ),
      );
    });

    if (isShare) {
      // Force 3 columns using explicit Rows to guarantee layout in headless rendering
      final double containerWidth = isShare ? 112.0 : 175.0;
      final List<Widget> rows = [];
      for (int i = 0; i < monthWidgets.length; i += 3) {
        final w1 = SizedBox(width: containerWidth, child: monthWidgets[i]);
        final w2 = (i + 1 < monthWidgets.length)
            ? SizedBox(width: containerWidth, child: monthWidgets[i + 1])
            : SizedBox(width: containerWidth);
        final w3 = (i + 2 < monthWidgets.length)
            ? SizedBox(width: containerWidth, child: monthWidgets[i + 2])
            : SizedBox(width: containerWidth);
        
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [w1, const SizedBox(width: 6), w2, const SizedBox(width: 6), w3],
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      );
    }

    return SingleChildScrollView(
      controller: _heatmapScrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: monthWidgets,
      ),
    );
  }

  // ─── Habit Breakdown ───────────────────────────────────────────────────────

  Widget _buildHabitBreakdownCard(List<HabitModel> habits, List<HabitLogModel> allLogs) {
    final today = _today;
    final DateTime startDate;
    switch (_period) {
      case StatsPeriod.week:
        startDate = today.subtract(Duration(days: today.weekday - 1)); // Monday
      case StatsPeriod.month:
        startDate = DateTime(today.year, today.month, 1);
      case StatsPeriod.year:
        startDate = DateTime(today.year, 1, 1);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 8),
              Text('Habit Completion Rates',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          ...habits.map((habit) {
            final habitLogs = allLogs.where((log) =>
                log.habitId == habit.id &&
                !log.completedAt.isBefore(startDate) &&
                !log.completedAt.isAfter(today.add(const Duration(days: 1)))).toList();

            int target = 0;
            for (int i = 0; i <= today.difference(startDate).inDays; i++) {
              final date = startDate.add(Duration(days: i));
              if (habit.isScheduledForDay(date)) {
                target += habit.timesPerDay;
              }
            }
            if (target == 0) target = 1;

            final completedCount = habitLogs.fold<int>(0, (sum, log) => sum + log.count);
            final rate = (completedCount / target).clamp(0.0, 1.0);
            final color = Color(habit.colorValue);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(habit.name,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Text('$completedCount/$target (${(rate * 100).toStringAsFixed(0)}%)',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(color: AppColors.backgroundPrimary, borderRadius: BorderRadius.circular(4)),
                      ),
                      FractionallySizedBox(
                        widthFactor: rate,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Time Spent ────────────────────────────────────────────────────────────

  Widget _buildTimeSpentCard(List<dynamic> habits) {
    final totalSecs = habits.fold<int>(0, (sum, habit) {
      return sum + ref.read(habitLogsProvider.notifier).getTotalDuration(habit.id);
    });
    if (totalSecs == 0) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Focus Allocation', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text(_formatDuration(totalSecs), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.warning)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: habits.map((habit) {
                  final duration = ref.read(habitLogsProvider.notifier).getTotalDuration(habit.id);
                  if (duration == 0) return const SizedBox.shrink();
                  final percentage = duration / totalSecs;
                  return Expanded(
                    flex: (percentage * 100).round().clamp(1, 100),
                    child: Container(color: Color(habit.colorValue)),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...habits.map((habit) {
            final duration = ref.read(habitLogsProvider.notifier).getTotalDuration(habit.id);
            if (duration == 0) return const SizedBox.shrink();
            final pct = (duration / totalSecs * 100).toStringAsFixed(0);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Color(habit.colorValue), shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(habit.name, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary))),
                  Text('$pct% • ${_formatDuration(duration)}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDuration(int totalSecs) {
    final h = totalSecs ~/ 3600;
    final m = (totalSecs % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  // ─── Trophy Room ───────────────────────────────────────────────────────────

  Widget _buildStreakDetailCard(int bestStreak) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.emoji_events, size: 28, color: AppColors.warning),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Best Record Streak',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textTertiary)),
              const SizedBox(height: 4),
              Text('$bestStreak days',
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Share ─────────────────────────────────────────────────────────────────

  Widget _shareTitle(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        Text(
          _periodLabel, // uses the existing getter on line 119
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildActivityShareInfographic(double maxY, List<int> values, List<String> labels) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            color: AppColors.backgroundPrimary,
            width: 375,
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _shareTitle('Completions Timeline'),
                  const SizedBox(height: 16),
                  _activityChart(maxY, values, labels),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmapShareInfographic(List<HabitLogModel> habitLogs, int currentStreak) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            color: AppColors.backgroundPrimary,
            width: 420, // Increased to comfortably fit 3 columns
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _shareTitle('Consistency Grid'),
                  const SizedBox(height: 12),
                  if (currentStreak > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.local_fire_department, size: 12, color: Color(0xFFF97316)),
                            const SizedBox(width: 3),
                            Text('$currentStreak day${currentStreak == 1 ? '' : 's'}',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFFF97316))),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildHeatmapContent(habitLogs, isShare: true),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text('Less ', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary)),
                    ..._heatmapColors.map((color) => Container(
                      width: 12, height: 12, margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                        border: color == Colors.black
                            ? Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5)
                            : null,
                      ),
                    )),
                    Text(' More', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary)),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _calculateCurrentStreak(List<HabitModel> habits, List<HabitLogModel> habitLogs) {
    int currentStreak = 0;
    final today = _today;
    for (final h in habits) {
      final logDates = habitLogs
          .where((l) => l.habitId == h.id)
          .map((l) => DateTime(l.completedAt.year, l.completedAt.month, l.completedAt.day))
          .toSet();
      if (logDates.contains(today) || logDates.contains(today.subtract(const Duration(days: 1)))) {
        int streak = 0;
        for (int d = 0; d < 365; d++) {
          if (logDates.contains(today.subtract(Duration(days: d)))) {
            streak++;
          } else {
            break;
          }
        }
        if (streak > currentStreak) currentStreak = streak;
      }
    }
    return currentStreak;
  }

  Future<void> _shareStats(String mode) async {
    try {
      final habits = ref.read(habitsProvider);
      final habitLogs = ref.read(habitLogsProvider);

      final Uint8List? image;

      if (mode == 'activity') {
        final (labels, values) = _buildTimelineData(habitLogs);
        double maxY = 1.0;
        if (values.isNotEmpty) {
          final m = values.reduce((curr, next) => curr > next ? curr : next);
          if (m > 0) maxY = m.toDouble();
        }
        image = await _activityController.captureFromWidget(
          _buildActivityShareInfographic(maxY, values, labels),
          delay: const Duration(milliseconds: 600),
          pixelRatio: 4.0,
        );
      } else if (mode == 'heatmap') {
        final currentStreak = _calculateCurrentStreak(habits, habitLogs);
        final int monthsToShow = _today.month;
        final int rowCount = (monthsToShow / 3).ceil();
        final double estimatedHeight = 145.0 + (rowCount * 149.0);

        image = await _heatmapController.captureFromWidget(
          _buildHeatmapShareInfographic(habitLogs, currentStreak),
          delay: const Duration(milliseconds: 600),
          pixelRatio: 4.0,
          targetSize: Size(420, estimatedHeight),
        );
      } else {
        image = await _fullController.capture(
          delay: const Duration(milliseconds: 600),
          pixelRatio: 4.0,
        );
      }

      if (image == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/dotrackr_stats_$mode.png');
      await file.writeAsBytes(image);

      final text = mode == 'activity'
          ? 'My activity on ${AppConstants.appName}!'
          : mode == 'heatmap'
              ? 'My habit consistency on ${AppConstants.appName}!'
              : 'My stats dashboard on ${AppConstants.appName}!';

      await Share.shareXFiles([XFile(file.path)], text: text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }
}

// ─── Ghost Chart Painter ───────────────────────────────────────────────────

class _GhostChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = [0.2, 0.4, 0.15, 0.5, 0.3, 0.6, 0.25, 0.7, 0.4, 0.8, 0.35, 0.9, 0.5];
    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - (points[i] * size.height);
      if (i == 0) { path.moveTo(x, y); }
      else { path.lineTo(x, y); }
    }
    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withValues(alpha: 0.06), Colors.white.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
