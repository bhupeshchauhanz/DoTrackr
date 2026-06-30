import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/todo_model.dart';
import '../../providers/providers.dart';
import '../../../data/services/notification_service.dart';

class AddTodoScreen extends ConsumerStatefulWidget {
  final TodoModel? todo;
  const AddTodoScreen({super.key, this.todo});

  @override
  ConsumerState<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends ConsumerState<AddTodoScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _dueDate;
  TimeOfDay? _deadlineTime;
  List<TimeOfDay> _reminderTimes = [];
  Priority _priority = Priority.medium;
  bool _isLoading = false;

  bool get _isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.todo?.description ?? '');
    if (widget.todo != null) {
      _dueDate = widget.todo!.dueDate;
      if (widget.todo!.hasDueTime) {
        _deadlineTime = TimeOfDay(
            hour: widget.todo!.dueTimeHour!,
            minute: widget.todo!.dueTimeMinute!);
      }
      _priority = widget.todo!.priority;
      // Load saved reminder times
      if (widget.todo!.reminderTimes.isNotEmpty) {
        _reminderTimes = widget.todo!.reminderTimes.map((t) {
          final parts = t.split(':');
          return TimeOfDay(
              hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }).toList();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Todo' : 'New Todo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _deleteTodo,
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              _label('Title'),
              const SizedBox(height: 8),
              _textField(_titleController, 'What needs to be done?', fontSize: 18),
              const SizedBox(height: 24),

              // Description
              _label('Description (optional)'),
              const SizedBox(height: 8),
              _textField(_descriptionController, 'Add some details...', maxLines: 3),
              const SizedBox(height: 24),

              // ─── DEADLINE SECTION ───
              Row(
                children: [
                  _label('Deadline'),
                  const Spacer(),
                  _todayButton(),
                ],
              ),
              const SizedBox(height: 8),
              // Due Date
              _datePickerTile(
                icon: Icons.calendar_today,
                text: _dueDate != null
                    ? DateFormat('EEE, MMM d, yyyy').format(_dueDate!)
                    : 'Select date',
                hasValue: _dueDate != null,
                onTap: _selectDueDate,
                onClear: () => setState(() {
                  _dueDate = null;
                  _deadlineTime = null;
                }),
              ),
              const SizedBox(height: 8),
              // Deadline Time
              _datePickerTile(
                icon: Icons.schedule,
                text: _deadlineTime != null
                    ? 'Due by ${_deadlineTime!.format(context)}'
                    : 'Set deadline time (optional)',
                hasValue: _deadlineTime != null,
                onTap: _selectDeadlineTime,
                onClear: () => setState(() => _deadlineTime = null),
              ),
              const SizedBox(height: 24),

              // ─── REMINDERS SECTION (separate from deadline) ───
              _label('Reminders (alarm will ring)'),
              const SizedBox(height: 4),
              Text(
                'Set times to get reminded. Can be before or after deadline.',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 8),
              ..._reminderTimes.asMap().entries.map((entry) {
                final i = entry.key;
                final rt = entry.value;
                return _reminderTile(i, rt);
              }),
              _addReminderButton(),
              const SizedBox(height: 24),

              // ─── PRIORITY ───
              _label('Priority'),
              const SizedBox(height: 8),
              _priorityRow(),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTodo,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.backgroundPrimary,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEditing ? 'Update Todo' : 'Create Todo',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  // ─── UI HELPERS ───

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary));

  Widget _textField(TextEditingController ctrl, String hint,
      {double fontSize = 16, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.inter(fontSize: fontSize, color: AppColors.textPrimary),
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.textPrimary, width: 2)),
      ),
    );
  }

  Widget _todayButton() {
    return GestureDetector(
      onTap: () => setState(() => _dueDate = DateTime.now()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('Today',
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
      ),
    );
  }

  Widget _datePickerTile({
    required IconData icon,
    required String text,
    required bool hasValue,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      color: hasValue ? AppColors.textPrimary : AppColors.textTertiary)),
            ),
            if (hasValue)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 18, color: AppColors.textTertiary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _reminderTile(int index, TimeOfDay time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _editReminderTime(index),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.alarm, size: 20, color: AppColors.warning),
              const SizedBox(width: 12),
              Text('Alarm ${index + 1}: ${time.format(context)}',
                  style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _reminderTimes.removeAt(index)),
                child: const Icon(Icons.close, size: 18, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addReminderButton() {
    return GestureDetector(
      onTap: _addReminderTime,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_alarm, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              _reminderTimes.isEmpty ? 'Add Alarm Reminder' : 'Add Another Alarm',
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priorityRow() {
    return Row(
      children: Priority.values.map((p) {
        final isSelected = _priority == p;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _priority = p),
            child: Container(
              margin: EdgeInsets.only(right: p != Priority.urgent ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? _priorityColor(p) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? _priorityColor(p) : AppColors.border),
              ),
              child: Column(
                children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: _priorityColor(p), shape: BoxShape.circle)),
                  const SizedBox(height: 4),
                  Text(_priorityLabel(p),
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500,
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.low: return AppColors.priorityLow;
      case Priority.medium: return AppColors.priorityMedium;
      case Priority.high: return AppColors.priorityHigh;
      case Priority.urgent: return AppColors.priorityUrgent;
    }
  }

  String _priorityLabel(Priority p) {
    switch (p) {
      case Priority.low: return 'Low';
      case Priority.medium: return 'Medium';
      case Priority.high: return 'High';
      case Priority.urgent: return 'Urgent';
    }
  }

  // ─── ACTIONS ───

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: _darkPickerBuilder,
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _selectDeadlineTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _deadlineTime ?? TimeOfDay.now(),
      builder: _darkPickerBuilder,
    );
    if (picked != null) setState(() => _deadlineTime = picked);
  }

  Future<void> _addReminderTime() async {
    if (_reminderTimes.length >= 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 5 reminders allowed')));
      }
      return;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: _darkPickerBuilder,
    );
    if (picked != null) {
      if (_reminderTimes.any((t) => t.hour == picked.hour && t.minute == picked.minute)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This time is already added')));
        }
        return;
      }
      setState(() => _reminderTimes.add(picked));
    }
  }

  Future<void> _editReminderTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTimes[index],
      builder: _darkPickerBuilder,
    );
    if (picked != null) {
      if (_reminderTimes.asMap().entries.any((e) =>
          e.key != index && e.value.hour == picked.hour && e.value.minute == picked.minute)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This time is already added')));
        }
        return;
      }
      setState(() => _reminderTimes[index] = picked);
    }
  }

  Widget _darkPickerBuilder(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.textPrimary,
          surface: AppColors.backgroundSecondary,
        ),
      ),
      child: child!,
    );
  }

  Future<void> _saveTodo() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_reminderTimes.isNotEmpty) {
        await NotificationService().requestPermission();
      }

      final reminderTimesStr = _reminderTimes
          .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
          .toList();

      if (_isEditing) {
        final updated = widget.todo!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null : _descriptionController.text.trim(),
          dueDate: _dueDate,
          dueTimeHour: _deadlineTime?.hour,
          dueTimeMinute: _deadlineTime?.minute,
          priority: _priority,
          reminderTimes: reminderTimesStr,
        );
        await ref.read(todosProvider.notifier).updateTodo(updated);
      } else {
        await ref.read(todosProvider.notifier).addTodo(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null : _descriptionController.text.trim(),
          dueDate: _dueDate,
          dueTimeHour: _deadlineTime?.hour,
          dueTimeMinute: _deadlineTime?.minute,
          priority: _priority,
          reminderTimes: reminderTimesStr,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTodo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Todo'),
        content: const Text('Are you sure you want to delete this todo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(todosProvider.notifier).deleteTodo(widget.todo!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}
