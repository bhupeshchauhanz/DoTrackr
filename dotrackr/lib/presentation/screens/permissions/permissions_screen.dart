import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';

class PermissionsScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const PermissionsScreen({super.key, required this.onComplete});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _notificationsGranted = false;
  bool _alarmGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final notifyStatus = await Permission.notification.status;
      final alarmStatus = await Permission.scheduleExactAlarm.status;

      if (mounted) {
        setState(() {
          _notificationsGranted = notifyStatus.isGranted;
          _alarmGranted = alarmStatus.isGranted || alarmStatus.isLimited;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmall = screenSize.height < 700;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 20 : 32),
          child: Column(
            children: [
              // Skip button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onComplete,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Icon
              Container(
                width: isSmall ? 80 : 100,
                height: isSmall ? 80 : 100,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppColors.textPrimary, width: 2),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  size: 48,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Enable Permissions',
                style: GoogleFonts.inter(
                  fontSize: isSmall ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'DoTrackr needs these permissions to send you timely reminders for your habits and tasks.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 40),

              // Notification permission
              _buildPermissionCard(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                description: 'Get notified about your tasks and habits',
                isGranted: _notificationsGranted,
                onRequest: _requestNotificationPermission,
              ),

              const SizedBox(height: 12),

              // Exact alarm permission
              _buildPermissionCard(
                icon: Icons.alarm,
                title: 'Exact Alarms',
                description: 'Ring at the precise time you set',
                isGranted: _alarmGranted,
                onRequest: _requestAlarmPermission,
              ),

              const Spacer(),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onComplete,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.backgroundPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue to DoTrackr',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'You can change permissions anytime in Settings',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return GestureDetector(
      onTap: isGranted ? null : onRequest,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGranted ? AppColors.success : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isGranted
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isGranted ? Icons.check : icon,
                color: isGranted ? AppColors.success : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isGranted)
              const Icon(Icons.check_circle, color: AppColors.success)
            else
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      if (mounted) {
        setState(() => _notificationsGranted = status.isGranted);
      }
    } catch (_) {}
  }

  Future<void> _requestAlarmPermission() async {
    try {
      final status = await Permission.scheduleExactAlarm.request();
      if (mounted) {
        setState(() => _alarmGranted = status.isGranted || status.isLimited);
      }
      // On some devices exact alarm opens system settings; re-check on return
      if (!status.isGranted) {
        await Future.delayed(const Duration(seconds: 1));
        final recheck = await Permission.scheduleExactAlarm.status;
        if (mounted) {
          setState(() => _alarmGranted = recheck.isGranted || recheck.isLimited);
        }
      }
    } catch (_) {}
  }
}