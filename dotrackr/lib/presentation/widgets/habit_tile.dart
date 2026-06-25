import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/habit_model.dart';

class HabitTile extends StatelessWidget {
  final HabitModel habit;
  final int streak;
  final bool isCompletedToday;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  const HabitTile({
    super.key,
    required this.habit,
    required this.streak,
    required this.isCompletedToday,
    this.onTap,
    this.onComplete,
  });

  IconData _getIcon() {
    switch (habit.iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'book':
        return Icons.book;
      case 'water_drop':
        return Icons.water_drop;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'code':
        return Icons.code;
      case 'brush':
        return Icons.brush;
      case 'music_note':
        return Icons.music_note;
      case 'directions_run':
        return Icons.directions_run;
      case 'medical_services':
        return Icons.medical_services;
      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitColor = Color(habit.colorValue);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: habitColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(),
                color: habitColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: streak > 0 ? AppColors.warning : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$streak day streak',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: streak > 0 ? AppColors.warning : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onComplete,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompletedToday
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompletedToday
                        ? AppColors.success
                        : AppColors.border,
                  ),
                ),
                child: Icon(
                  isCompletedToday ? Icons.check : Icons.add,
                  size: 18,
                  color: isCompletedToday
                      ? AppColors.success
                      : AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}