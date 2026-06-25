import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/habit_model.dart';
import '../../providers/providers.dart';
import '../../widgets/premium_text_field.dart';
import '../../widgets/premium_button.dart';

class AddHabitScreen extends ConsumerStatefulWidget {
  final HabitModel? habit;

  const AddHabitScreen({super.key, this.habit});

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  HabitFrequency _frequency = HabitFrequency.daily;
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];
  TimeOfDay? _reminderTime;
  int _selectedColor = 0xFFFFFFFF;
  String _selectedIcon = 'check_circle';
  bool _isLoading = false;

  bool get _isEditing => widget.habit != null;

  final List<int> _colorOptions = [
    0xFFFFFFFF,
    0xFF4ADE80,
    0xFF3B82F6,
    0xFFF59E0B,
    0xFFEF4444,
    0xFF8B5CF6,
    0xFFEC4899,
  ];

  final Map<String, IconData> _iconOptions = {
    'check_circle': Icons.check_circle,
    'fitness_center': Icons.fitness_center,
    'book': Icons.book,
    'water_drop': Icons.water_drop,
    'self_improvement': Icons.self_improvement,
    'code': Icons.code,
    'brush': Icons.brush,
    'music_note': Icons.music_note,
    'directions_run': Icons.directions_run,
    'medical_services': Icons.medical_services,
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit?.name ?? '');
    _descriptionController = TextEditingController(text: widget.habit?.description ?? '');

    if (widget.habit != null) {
      _frequency = widget.habit!.frequency;
      _selectedDays = widget.habit!.daysOfWeek ?? [1, 2, 3, 4, 5, 6, 7];
      if (widget.habit!.hasReminder) {
        _reminderTime = TimeOfDay(
          hour: widget.habit!.reminderHour!,
          minute: widget.habit!.reminderMinute!,
        );
      }
      _selectedColor = widget.habit!.colorValue;
      _selectedIcon = widget.habit!.iconName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Habit' : 'New Habit'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _deleteHabit,
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumTextField(
              controller: _nameController,
              label: 'Habit Name',
              hint: 'e.g., Morning Exercise',
            ),
            const SizedBox(height: 24),
            PremiumTextField(
              controller: _descriptionController,
              label: 'Description (optional)',
              hint: 'Add some details...',
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Text(
              'Frequency',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildFrequencyOption('Daily', HabitFrequency.daily),
                const SizedBox(width: 8),
                _buildFrequencyOption('Weekly', HabitFrequency.weekly),
                const SizedBox(width: 8),
                _buildFrequencyOption('Custom', HabitFrequency.custom),
              ],
            ),
            if (_frequency == HabitFrequency.custom) ...[
              const SizedBox(height: 16),
              Text(
                'Select Days',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final isSelected = _selectedDays.contains(day);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDays.remove(day);
                        } else {
                          _selectedDays.add(day);
                        }
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.textPrimary : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.textPrimary : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          AppConstants.weekDays[index],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.backgroundPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Reminder (optional)',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectReminderTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _reminderTime != null
                          ? _reminderTime!.format(context)
                          : 'Set reminder time',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: _reminderTime != null
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    if (_reminderTime != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _reminderTime = null;
                          });
                        },
                        child: const Icon(Icons.close, size: 20),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Color',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: _colorOptions.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(color),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.textPrimary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 20,
                            color: AppColors.backgroundPrimary,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Icon',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _iconOptions.entries.map((entry) {
                final isSelected = _selectedIcon == entry.key;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = entry.key;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(_selectedColor).withValues(alpha: 0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Color(_selectedColor) : AppColors.border,
                      ),
                    ),
                    child: Icon(
                      entry.value,
                      color: isSelected ? Color(_selectedColor) : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            PremiumButton(
              label: _isEditing ? 'Update Habit' : 'Create Habit',
              width: double.infinity,
              isLoading: _isLoading,
              onPressed: _saveHabit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyOption(String label, HabitFrequency frequency) {
    final isSelected = _frequency == frequency;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _frequency = frequency;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.textPrimary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.textPrimary : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppColors.backgroundPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.textPrimary,
              surface: AppColors.backgroundSecondary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _saveHabit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a habit name')),
      );
      return;
    }

    if (_frequency == HabitFrequency.custom && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing) {
        final updated = widget.habit!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          frequency: _frequency,
          daysOfWeek: _frequency == HabitFrequency.custom ? _selectedDays : null,
          reminderHour: _reminderTime?.hour,
          reminderMinute: _reminderTime?.minute,
          colorValue: _selectedColor,
          iconName: _selectedIcon,
        );
        await ref.read(habitsProvider.notifier).updateHabit(updated);
      } else {
        await ref.read(habitsProvider.notifier).addHabit(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          frequency: _frequency,
          daysOfWeek: _frequency == HabitFrequency.custom ? _selectedDays : null,
          reminderHour: _reminderTime?.hour,
          reminderMinute: _reminderTime?.minute,
          colorValue: _selectedColor,
          iconName: _selectedIcon,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteHabit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: const Text('Are you sure you want to delete this habit? All history will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(habitsProvider.notifier).deleteHabit(widget.habit!.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}