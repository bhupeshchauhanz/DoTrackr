import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../providers/user_provider.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/notification_setup_guide.dart';
import '../profile/profile_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _batteryOptimizationExempt = false;

  @override
  void initState() {
    super.initState();
    _checkBatteryStatus();
  }

  Future<void> _checkBatteryStatus() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (mounted) {
        setState(() => _batteryOptimizationExempt = status.isGranted);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 32),

                // ─────────────────────────────────────────────────────────
                // FIX NOTIFICATIONS CARD (shows warning if not exempt)
                // ─────────────────────────────────────────────────────────
                _buildNotificationFixCard(context),

                const SizedBox(height: 32),

                // ─────────────────────────────────────────────────────────
                // Personal Info
                // ─────────────────────────────────────────────────────────
                Text(
                  'Personal Info',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                PremiumCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_outline, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.firstName ?? 'Profile',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'Edit your profile',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ─────────────────────────────────────────────────────────
                // About
                // ─────────────────────────────────────────────────────────
                Text(
                  'About',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                PremiumCard(
                  onTap: () => _showAboutDialog(context),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.info_outline, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About ${AppConstants.appName}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Version ${AppConstants.appVersion}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ─────────────────────────────────────────────────────────
                // Data
                // ─────────────────────────────────────────────────────────
                Text(
                  'Data',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                PremiumCard(
                  onTap: () => _showClearDataDialog(context, ref),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.delete_outline, color: AppColors.error),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clear All Data',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Delete all todos, habits, and logs',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ─────────────────────────────────────────────────────────
                // Preferences
                // ─────────────────────────────────────────────────────────
                Text(
                  'Preferences',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                PremiumCard(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Coming soon',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.lock_outline, size: 16, color: AppColors.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Footer
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: AppColors.textPrimary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppConstants.appName,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Made by ${AppConstants.developerName}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'v${AppConstants.appVersion}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
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
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Fix Notifications Card
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildNotificationFixCard(BuildContext context) {
    final isFixed = _batteryOptimizationExempt;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const NotificationGuideSheet(),
        ).then((_) {
          // Re-check status after guide is closed
          Future.delayed(const Duration(milliseconds: 500), _checkBatteryStatus);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isFixed
              ? AppColors.success.withValues(alpha: 0.08)
              : const Color(0xFFFB923C).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFixed
                ? AppColors.success.withValues(alpha: 0.4)
                : const Color(0xFFFB923C).withValues(alpha: 0.6),
            width: isFixed ? 1 : 1.5,
          ),
        ),
        child: Row(
          children: [
            // Animated icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isFixed
                    ? AppColors.success.withValues(alpha: 0.15)
                    : const Color(0xFFFB923C).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isFixed ? Icons.check_circle_outline : Icons.battery_alert_outlined,
                color: isFixed ? AppColors.success : const Color(0xFFFB923C),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isFixed ? 'Notifications Ready' : 'Fix Notifications',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (!isFixed) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFB923C),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ACTION NEEDED',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isFixed
                        ? 'Battery optimization is disabled. Alarms will ring on time.'
                        : 'Battery saver may prevent alarms from ringing. Tap to fix.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isFixed ? AppColors.success : AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isFixed ? AppColors.success : const Color(0xFFFB923C),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Dialogs
  // ───────────────────────────────────────────────────────────────────────────

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppConstants.appName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${AppConstants.appVersion}',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'A premium productivity app combining Todo management and Habit tracking with a minimalist design.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              'Features:',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem('Task management with priorities'),
            _buildFeatureItem('Habit tracking with streaks'),
            _buildFeatureItem('Weekly statistics'),
            _buildFeatureItem('Dark premium design'),
            _buildFeatureItem('Personalized dashboard'),
            _buildFeatureItem('Profile management'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your todos, habits, and habit logs. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(databaseServiceProvider).clearAllData();
              ref.read(todosProvider.notifier).loadTodos();
              ref.read(habitsProvider.notifier).loadHabits();
              ref.read(habitLogsProvider.notifier).loadLogs();
              ref.read(categoriesProvider.notifier).loadCategories();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}