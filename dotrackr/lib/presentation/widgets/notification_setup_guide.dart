import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';

/// Detects device brand and shows the appropriate battery optimization guide.
class NotificationSetupGuide extends StatefulWidget {
  const NotificationSetupGuide({super.key});

  @override
  State<NotificationSetupGuide> createState() => _NotificationSetupGuideState();
}

class _NotificationSetupGuideState extends State<NotificationSetupGuide> {
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

  Future<void> _requestBatteryOptimizationExemption() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      if (mounted) {
        setState(() => _batteryOptimizationExempt = status.isGranted);
        if (status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Notifications will now work reliably!',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (_) {
      // Fallback: open app settings
      await openAppSettings();
    }
  }

  static _BrandGuide _detectBrand() => _detectDeviceBrand();

  @override
  Widget build(BuildContext context) {
    return Container(); // Used externally via showGuide()
  }

  /// Call this static method to show the guide as a bottom sheet.
  static void showGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationGuideSheet(),
    );
  }
}

// ─── Top-level helpers (accessible to all classes in this file) ──────────────

String get _deviceBrand {
  if (!Platform.isAndroid) return 'android';
  return Platform.operatingSystemVersion.toLowerCase();
}

_BrandGuide _detectDeviceBrand() {
  final version = _deviceBrand;
  if (version.contains('miui') || version.contains('xiaomi') ||
      version.contains('redmi') || version.contains('poco')) {
    return _BrandGuide.miui;
  }
  if (version.contains('samsung') || version.contains('sm-') ||
      version.contains('galaxy')) {
    return _BrandGuide.samsung;
  }
  if (version.contains('oneplus') || version.contains('oxygen')) {
    return _BrandGuide.oneplus;
  }
  if (version.contains('huawei') || version.contains('emui') ||
      version.contains('honor')) {
    return _BrandGuide.huawei;
  }
  if (version.contains('oppo') || version.contains('realme') ||
      version.contains('coloros')) {
    return _BrandGuide.oppo;
  }
  if (version.contains('vivo') || version.contains('funtouch')) {
    return _BrandGuide.vivo;
  }
  return _BrandGuide.stock;
}

// ─────────────────────────────────────────────────────────────────────────────

enum _BrandGuide { miui, samsung, oneplus, huawei, oppo, vivo, stock }

class NotificationGuideSheet extends StatefulWidget {
  const NotificationGuideSheet();

  @override
  State<NotificationGuideSheet> createState() => _NotificationGuideSheetState();
}

class _NotificationGuideSheetState extends State<NotificationGuideSheet> {
  bool _batteryExempt = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkBattery();
  }

  Future<void> _checkBattery() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (mounted) setState(() => _batteryExempt = status.isGranted);
    } catch (_) {}
  }

  Future<void> _requestBatteryExemption() async {
    setState(() => _loading = true);
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      if (mounted) {
        setState(() {
          _batteryExempt = status.isGranted;
          _loading = false;
        });
        if (status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Battery optimization disabled! Notifications will work perfectly.',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = _detectDeviceBrand();
    final guide = _getGuideForBrand(brand);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _batteryExempt
                                ? AppColors.success.withValues(alpha: 0.15)
                                : const Color(0xFFFB923C).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _batteryExempt ? Icons.check_circle : Icons.battery_alert,
                            color: _batteryExempt ? AppColors.success : const Color(0xFFFB923C),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fix Notifications',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _batteryExempt
                                    ? 'Notifications are set up correctly ✅'
                                    : 'Alarms may not ring without this',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _batteryExempt
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Why this matters
                    _buildInfoBox(
                      icon: Icons.info_outline,
                      text:
                          'Android\'s battery saver kills background apps to save power. This prevents alarms and reminders from ringing on time. You need to exempt DoTrackr from this restriction.',
                    ),

                    const SizedBox(height: 20),

                    // ONE-TAP FIX button
                    if (!_batteryExempt) ...[
                      Text(
                        'Quick Fix',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _requestBatteryExemption,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.textPrimary,
                            foregroundColor: AppColors.backgroundPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.backgroundPrimary,
                                  ),
                                )
                              : const Icon(Icons.flash_on, size: 20),
                          label: Text(
                            _loading ? 'Opening...' : 'Disable Battery Optimization',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Battery optimization is already disabled. Your reminders will ring on time!',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Manual steps for the detected brand
                    Text(
                      'Manual Steps${guide.brand != 'Android' ? ' for ${guide.brand}' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ...guide.steps.asMap().entries.map((entry) {
                      return _buildStep(entry.key + 1, entry.value);
                    }),

                    const SizedBox(height: 20),

                    // Show steps for ALL brands
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        'Steps for Other Devices',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      iconColor: AppColors.textTertiary,
                      collapsedIconColor: AppColors.textTertiary,
                      children: [
                        ..._allBrandGuides
                            .where((g) => g.brand != guide.brand)
                            .map((g) => _buildBrandSection(g)),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoBox({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandSection(_BrandSteps guide) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                guide.emoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                guide.brand,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...guide.steps.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.key + 1}. ',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  _BrandSteps _getGuideForBrand(_BrandGuide brand) {
    switch (brand) {
      case _BrandGuide.miui:
        return _allBrandGuides.firstWhere((g) => g.brand == 'Xiaomi / MIUI');
      case _BrandGuide.samsung:
        return _allBrandGuides.firstWhere((g) => g.brand == 'Samsung');
      case _BrandGuide.oneplus:
        return _allBrandGuides.firstWhere((g) => g.brand == 'OnePlus');
      case _BrandGuide.huawei:
        return _allBrandGuides.firstWhere((g) => g.brand == 'Huawei / Honor');
      case _BrandGuide.oppo:
        return _allBrandGuides.firstWhere((g) => g.brand == 'OPPO / Realme');
      case _BrandGuide.vivo:
        return _allBrandGuides.firstWhere((g) => g.brand == 'Vivo');
      case _BrandGuide.stock:
        return _allBrandGuides.firstWhere((g) => g.brand == 'Android (Stock)');
    }
  }

  static final List<_BrandSteps> _allBrandGuides = [
    _BrandSteps(
      brand: 'Xiaomi / MIUI',
      emoji: '📱',
      steps: [
        'Open Settings',
        'Tap Apps → Manage apps',
        'Search for DoTrackr and tap it',
        'Tap Battery saver',
        'Select No restrictions',
        'Also go back and tap Autostart → Enable it',
      ],
    ),
    _BrandSteps(
      brand: 'Samsung',
      emoji: '🌀',
      steps: [
        'Open Settings',
        'Tap Battery and device care → Battery',
        'Tap Background usage limits',
        'Make sure DoTrackr is NOT in the restricted list',
        'Alternatively: Settings → Apps → DoTrackr → Battery → Unrestricted',
      ],
    ),
    _BrandSteps(
      brand: 'OnePlus',
      emoji: '⚡',
      steps: [
        'Open Settings',
        'Tap Battery → Battery optimization',
        'Tap the ⋮ menu and select All apps',
        'Find DoTrackr → Tap → Select Don\'t optimize',
        'Also enable: Settings → Apps → Special app access → Autostart → DoTrackr',
      ],
    ),
    _BrandSteps(
      brand: 'Huawei / Honor',
      emoji: '🔴',
      steps: [
        'Open Settings',
        'Tap Apps → Apps',
        'Tap DoTrackr → Battery',
        'Enable Run in background',
        'Also: Settings → Battery → App launch → DoTrackr → Manage manually → Enable all 3 toggles',
      ],
    ),
    _BrandSteps(
      brand: 'OPPO / Realme',
      emoji: '🟢',
      steps: [
        'Open Settings',
        'Tap Battery → More battery settings',
        'Tap Battery optimization → Find DoTrackr',
        'Select Don\'t optimize',
        'Also: Settings → Apps → Special access → Autostart → DoTrackr → Enable',
      ],
    ),
    _BrandSteps(
      brand: 'Vivo',
      emoji: '🔵',
      steps: [
        'Open Settings',
        'Tap Battery',
        'Tap Background power consumption management',
        'Find DoTrackr → Tap → Select Don\'t restrict',
        'Also go to iManager → App Manager → Autostart Management → Enable DoTrackr',
      ],
    ),
    _BrandSteps(
      brand: 'Android (Stock)',
      emoji: '🤖',
      steps: [
        'Open Settings',
        'Tap Apps → See all apps',
        'Tap DoTrackr',
        'Tap Battery → Select Unrestricted',
        'This allows DoTrackr to send notifications at any time',
      ],
    ),
  ];
}

class _BrandSteps {
  final String brand;
  final String emoji;
  final List<String> steps;

  const _BrandSteps({
    required this.brand,
    required this.emoji,
    required this.steps,
  });
}
