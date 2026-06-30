import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/habit_model.dart';
import '../../data/services/notification_service.dart';
import '../providers/providers.dart';

class _TimerState {
  static final Map<String, int> _pausedSeconds = {};
  static int? get(String habitId) => _pausedSeconds[habitId];
  static void save(String habitId, int remaining) => _pausedSeconds[habitId] = remaining;
  static void clear(String habitId) => _pausedSeconds.remove(habitId);
}

class HabitTimerDialog extends ConsumerStatefulWidget {
  final HabitModel habit;
  const HabitTimerDialog({super.key, required this.habit});

  @override
  ConsumerState<HabitTimerDialog> createState() => _HabitTimerDialogState();
}

class _HabitTimerDialogState extends ConsumerState<HabitTimerDialog> {
  late int _remainingSeconds;
  late int _totalSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.habit.durationMinutes * 60;
    _remainingSeconds = _TimerState.get(widget.habit.id) ?? _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!_isCompleted && _remainingSeconds < _totalSeconds) {
      _TimerState.save(widget.habit.id, _remainingSeconds);
    }
    super.dispose();
  }

  void _start() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        _onComplete();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    _TimerState.save(widget.habit.id, _remainingSeconds);
  }

  Future<void> _onComplete() async {
    setState(() => _isCompleted = true);
    _TimerState.clear(widget.habit.id);
    // Auto-log habit completion on timer finish
    if (mounted) {
      await ref.read(habitLogsProvider.notifier).completeHabit(
        habitId: widget.habit.id,
        durationSeconds: _totalSeconds,
        note: 'Completed via timer',
      );
    }
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) Navigator.pop(context, _totalSeconds);
  }

  void _finishEarly() {
    _timer?.cancel();
    _TimerState.clear(widget.habit.id);
    final spent = _totalSeconds - _remainingSeconds;
    Navigator.pop(context, spent > 0 ? spent : 1);
  }

  void _cancel() {
    _timer?.cancel();
    if (_remainingSeconds < _totalSeconds) {
      _TimerState.save(widget.habit.id, _remainingSeconds);
    }
    Navigator.pop(context, 0);
  }

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds > 0 ? 1.0 - (_remainingSeconds / _totalSeconds) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(widget.habit.name),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _cancel),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 220, height: 220,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(width: 220, height: 220, child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation(_isCompleted ? AppColors.success : Color(widget.habit.colorValue)),
                  )),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      _isCompleted ? '✓' : _fmt(_remainingSeconds),
                      style: GoogleFonts.inter(fontSize: _isCompleted ? 48 : 40, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isCompleted ? 'Done!' : _isRunning ? 'Running' : _remainingSeconds < _totalSeconds ? 'Paused' : 'Ready',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(height: 48),
              if (!_isCompleted) ...[
                GestureDetector(
                  onTap: _isRunning ? _pause : _start,
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(color: _isRunning ? AppColors.warning : AppColors.success, shape: BoxShape.circle),
                    child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 36, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                if (_remainingSeconds < _totalSeconds)
                  TextButton(
                    onPressed: _finishEarly,
                    child: Text('Complete Now', style: GoogleFonts.inter(fontSize: 16, color: AppColors.success, fontWeight: FontWeight.w600)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
