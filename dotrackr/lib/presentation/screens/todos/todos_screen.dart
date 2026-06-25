import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../widgets/todo_tile.dart';
import '../../widgets/empty_state.dart';
import 'add_todo_screen.dart';

class TodosScreen extends ConsumerStatefulWidget {
  const TodosScreen({super.key});

  @override
  ConsumerState<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends ConsumerState<TodosScreen> {
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(todosProvider);
    final filter = _selectedFilter;

    final filteredTodos = todos.where((todo) {
      switch (filter) {
        case 0:
          return true;
        case 1:
          return !todo.isCompleted;
        case 2:
          if (todo.dueDate == null || todo.isCompleted) return false;
          final dueDay = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
          final today = DateTime.now();
          final todayOnly = DateTime(today.year, today.month, today.day);
          return dueDay.isAtSameMomentAs(todayOnly) || dueDay.isBefore(todayOnly);
        case 3:
          if (todo.dueDate == null || todo.isCompleted) return false;
          final dueDay = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
          final today = DateTime.now();
          final todayOnly = DateTime(today.year, today.month, today.day);
          return dueDay.isAfter(todayOnly);
        case 4:
          return todo.isCompleted;
        default:
          return true;
      }
    }).toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

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
                  Text(
                    'Todos',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 0),
                        const SizedBox(width: 8),
                        _buildFilterChip('Active', 1),
                        const SizedBox(width: 8),
                        _buildFilterChip('Today', 2),
                        const SizedBox(width: 8),
                        _buildFilterChip('Upcoming', 3),
                        const SizedBox(width: 8),
                        _buildFilterChip('Completed', 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredTodos.isEmpty
                  ? EmptyState(
                      icon: Icons.check_circle_outline,
                      title: _getEmptyTitle(),
                      message: _getEmptyMessage(),
                      actionLabel: filter == 0 ? 'Add Todo' : null,
                      onAction: filter == 0
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddTodoScreen(),
                                ),
                              );
                            }
                          : null,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filteredTodos.length,
                      itemBuilder: (context, index) {
                        final todo = filteredTodos[index];
                        return Padding(
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
                        );
                      },
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
              builder: (_) => const AddTodoScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.backgroundPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  String _getEmptyTitle() {
    switch (_selectedFilter) {
      case 0:
        return 'No todos yet';
      case 1:
        return 'All tasks completed';
      case 2:
        return 'Nothing due today';
      case 3:
        return 'No upcoming tasks';
      case 4:
        return 'No completed tasks';
      default:
        return 'No todos';
    }
  }

  String _getEmptyMessage() {
    switch (_selectedFilter) {
      case 0:
        return 'Create your first todo to get started';
      case 1:
        return 'You\'ve completed all your active tasks';
      case 2:
        return 'Enjoy your day with no tasks due';
      case 3:
        return 'Check back later for upcoming tasks';
      case 4:
        return 'Complete some tasks to see them here';
      default:
        return '';
    }
  }
}