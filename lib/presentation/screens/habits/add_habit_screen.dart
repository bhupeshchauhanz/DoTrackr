import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/habit_model.dart';
import '../../../data/services/notification_service.dart';
import '../../providers/providers.dart';
import '../../widgets/premium_text_field.dart';
import '../../widgets/premium_button.dart';

class ReminderConfig {
  TimeOfDay time;
  String scope;
  ReminderConfig({required this.time, this.scope = 'all'});
}

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
  List<ReminderConfig> _reminderTimes = [];
  int _selectedColor = 0xFFFFFFFF;
  String _selectedIcon = 'check_circle';
  bool _isLoading = false;
  int _durationMinutes = 0;
  String _durationScope = 'all';
  

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
      if (widget.habit!.reminderTimes.isNotEmpty) {
        _reminderTimes = widget.habit!.reminderTimes.map((t) {
          final parts = t.split('|');
          final timeStr = parts[0];
          final scopeStr = parts.length > 1 ? parts[1] : 'all';
          final timeParts = timeStr.split(':');
          return ReminderConfig(
            time: TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])),
            scope: scopeStr,
          );
        }).toList();
      } else if (widget.habit!.hasReminder && widget.habit!.reminderHour != null && widget.habit!.reminderMinute != null) {
        _reminderTimes = [
          ReminderConfig(time: TimeOfDay(hour: widget.habit!.reminderHour!, minute: widget.habit!.reminderMinute!)),
        ];
      }
      _selectedColor = widget.habit!.colorValue;
      _selectedIcon = widget.habit!.iconName;
      _durationMinutes = widget.habit!.durationMinutes;
      _durationScope = widget.habit!.durationScope;
      
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
                runSpacing: 8,
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
              'Reminders',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
              ..._reminderTimes.asMap().entries.map((entry) {
              final i = entry.key;
              final rt = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => _editReminderTime(i),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.notifications_active_rounded, size: 18, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            rt.time.format(context),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 95,
                          child: Container(
                            height: 30,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: rt.scope,
                                isDense: true,
                                icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                                dropdownColor: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                items: const [
                                  DropdownMenuItem(value: 'all', child: Text('Everyday', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'today', child: Text('Only Today', overflow: TextOverflow.ellipsis)),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => rt.scope = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _removeReminder(i),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            GestureDetector(
              onTap: _addReminderTime,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded, size: 22, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      _reminderTimes.isEmpty ? 'Set Reminder' : 'Add Another Reminder',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Duration / Timer
            Text(
              'Duration (optional timer)',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Set a target time. A countdown timer will appear to track this habit.',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDuration,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 20,
                        color: _durationMinutes > 0 ? AppColors.warning : AppColors.textTertiary),
                    const SizedBox(width: 12),
                    Text(
                      _durationMinutes > 0
                          ? '${_durationMinutes ~/ 60 > 0 ? '${_durationMinutes ~/ 60}h ' : ''}${_durationMinutes % 60}min'
                          : 'No timer (tap to set)',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: _durationMinutes > 0 ? AppColors.textPrimary : AppColors.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    if (_durationMinutes > 0)
                      GestureDetector(
                        onTap: () => setState(() => _durationMinutes = 0),
                        child: const Icon(Icons.close, size: 20, color: AppColors.textTertiary),
                      ),
                  ],
                ),
              ),
            ),
            if (_durationMinutes > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Apply Duration', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _durationScope = 'today'),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: _durationScope == 'today' ? AppColors.success.withValues(alpha: 0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _durationScope == 'today' ? AppColors.success : AppColors.border),
                            ),
                            child: Row(children: [
                              Icon(_durationScope == 'today' ? Icons.radio_button_checked : Icons.radio_button_off, size: 16, color: _durationScope == 'today' ? AppColors.success : AppColors.textTertiary),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Only Today', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary))),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _durationScope = 'all'),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: _durationScope == 'all' ? AppColors.success.withValues(alpha: 0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _durationScope == 'all' ? AppColors.success : AppColors.border),
                            ),
                            child: Row(children: [
                              Icon(_durationScope == 'all' ? Icons.radio_button_checked : Icons.radio_button_off, size: 16, color: _durationScope == 'all' ? AppColors.success : AppColors.textTertiary),
                              const SizedBox(width: 8),
                              Expanded(child: Text('From Today Onwards', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary))),
                            ]),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
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

  Future<void> _addReminderTime() async {
    if (_reminderTimes.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 reminders are allowed per habit')),
      );
      return;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
      if (_reminderTimes.any((t) => t.time.hour == picked.hour && t.time.minute == picked.minute)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This reminder time is already added')),
          );
        }
        return;
      }
      setState(() {
        _reminderTimes.add(ReminderConfig(time: picked));
      });
    }
  }

  Future<void> _editReminderTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTimes[index].time,
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
      if (_reminderTimes.asMap().entries.any((entry) =>
          entry.key != index && entry.value.time.hour == picked.hour && entry.value.time.minute == picked.minute)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This reminder time is already added')),
          );
        }
        return;
      }
      setState(() {
        _reminderTimes[index].time = picked;
      });
    }
  }

  void _removeReminder(int index) {
    setState(() {
      _reminderTimes.removeAt(index);
    });
  }

  Future<void> _pickDuration() async {
    int hours = _durationMinutes ~/ 60;
    int mins = _durationMinutes % 60;

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        int tempH = hours;
        int tempM = mins;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Set Duration'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Hours
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Hours', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => setDialogState(() { if (tempH > 0) tempH--; }),
                                icon: const Icon(Icons.remove_circle_outline, size: 22),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                              SizedBox(
                                width: 30,
                                child: Text('$tempH', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ),
                              IconButton(
                                onPressed: () => setDialogState(() { if (tempH < 12) tempH++; }),
                                icon: const Icon(Icons.add_circle_outline, size: 22),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(':', style: GoogleFonts.inter(fontSize: 22, color: AppColors.textPrimary)),
                      // Minutes
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Minutes', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => setDialogState(() { if (tempM > 0) tempM -= 5; }),
                                icon: const Icon(Icons.remove_circle_outline, size: 22),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                              SizedBox(
                                width: 30,
                                child: Text(tempM.toString().padLeft(2, '0'), textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ),
                              IconButton(
                                onPressed: () => setDialogState(() { if (tempM < 55) tempM += 5; }),
                                icon: const Icon(Icons.add_circle_outline, size: 22),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, 0), child: const Text('No Timer')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, tempH * 60 + tempM),
                  child: const Text('Set'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != null) {
      setState(() => _durationMinutes = result);
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
      if (_reminderTimes.isNotEmpty) {
        await NotificationService().requestPermission();
      }

      final reminderTimesStr = _reminderTimes.map((t) =>
          '${t.time.hour.toString().padLeft(2, '0')}:${t.time.minute.toString().padLeft(2, '0')}|${t.scope}').toList();

      if (_isEditing) {
        final updated = widget.habit!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          frequency: _frequency,
          daysOfWeek: _frequency == HabitFrequency.custom ? _selectedDays : null,
          reminderHour: _reminderTimes.isNotEmpty ? _reminderTimes.first.time.hour : null,
          reminderMinute: _reminderTimes.isNotEmpty ? _reminderTimes.first.time.minute : null,
          reminderTimes: reminderTimesStr,
          colorValue: _selectedColor,
          iconName: _selectedIcon,
           durationMinutes: _durationMinutes,
          durationScope: _durationScope,
          reminderScope: 'all',
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
          reminderHour: _reminderTimes.isNotEmpty ? _reminderTimes.first.time.hour : null,
          reminderMinute: _reminderTimes.isNotEmpty ? _reminderTimes.first.time.minute : null,
          reminderTimes: reminderTimesStr,
          colorValue: _selectedColor,
          iconName: _selectedIcon,
          durationMinutes: _durationMinutes,
          durationScope: _durationScope,
          reminderScope: 'all',
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