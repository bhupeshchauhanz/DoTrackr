import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/todo_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TodoTile extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onDelete;

  const TodoTile({
    super.key,
    required this.todo,
    this.onTap,
    this.onToggleComplete,
    this.onDelete,
  });

  Color _getPriorityColor() {
    switch (todo.priority) {
      case Priority.low:
        return AppColors.priorityLow;
      case Priority.medium:
        return AppColors.priorityMedium;
      case Priority.high:
        return AppColors.priorityHigh;
      case Priority.urgent:
        return AppColors.priorityUrgent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onDelete?.call(),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(16),
            ),
          ),
        ],
      ),
      child: GestureDetector(
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
              GestureDetector(
                onTap: onToggleComplete,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.transparent,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: todo.isCompleted
                          ? AppColors.textPrimary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: todo.isCompleted
                            ? AppColors.textPrimary
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: todo.isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.backgroundPrimary,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getPriorityColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            todo.title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: todo.isCompleted
                                  ? AppColors.textTertiary
                                  : AppColors.textPrimary,
                              decoration: todo.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (todo.dueDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDueDate(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: todo.isOverdue
                              ? AppColors.error
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDueDate() {
    final date = todo.dueDate!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(date.year, date.month, date.day);

    if (dueDay.isAtSameMomentAs(today)) {
      if (todo.hasDueTime) {
        return 'Today at ${_formatTime()}';
      }
      return 'Today';
    } else if (dueDay.isBefore(today)) {
      final diff = today.difference(dueDay).inDays;
      if (diff == 1) {
        return 'Yesterday';
      }
      return '$diff days ago';
    } else {
      final diff = dueDay.difference(today).inDays;
      if (diff == 1) {
        if (todo.hasDueTime) {
          return 'Tomorrow at ${_formatTime()}';
        }
        return 'Tomorrow';
      }
      if (todo.hasDueTime) {
        return '${date.day}/${date.month} at ${_formatTime()}';
      }
      return '${date.day}/${date.month}';
    }
  }

  String _formatTime() {
    if (!todo.hasDueTime) return '';
    final hour = todo.dueTimeHour!;
    final minute = todo.dueTimeMinute!;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}