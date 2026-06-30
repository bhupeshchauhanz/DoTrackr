import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('About DoTrackr', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipOval(
                  child: Image.asset(
                    'assets/icon/app_icon.jpg',
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.check_circle, size: 56, color: AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(AppConstants.appName, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('v${AppConstants.appVersion}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success)),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _infoRow(Icons.person, 'Developer', AppConstants.developerName),
                    const Divider(color: AppColors.border, height: 24),
                    _infoRow(Icons.description, 'Description', 'A premium todo and habit tracker with countdown timers, smart reminders, heatmaps, and statistics.'),
                    const Divider(color: AppColors.border, height: 24),
                    _infoRow(Icons.category, 'Features', 'Todos, Habits, Timers, Streaks, Heatmaps, Statistics, Smart Notifications'),
                    const Divider(color: AppColors.border, height: 24),
                    _infoRow(Icons.security, 'Privacy', '100% locally stored. No internet tracking, no data sharing. Encrypted using AES-256 for complete data safety.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connect with Me', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    _buildSocialLink(context, Icons.link, 'LinkedIn', 'https://www.linkedin.com/in/bhupeshchauhanz/'),
                    const SizedBox(height: 10),
                    _buildSocialLink(context, Icons.camera_alt_outlined, 'Instagram', 'https://www.instagram.com/bhupeshchauhanz/'),
                    const SizedBox(height: 10),
                    _buildSocialLink(context, Icons.email_outlined, 'Email', 'mailto:support@bhupeshchauhan.in'),
                    const SizedBox(height: 10),
                    _buildSocialLink(context, Icons.language, 'Website', 'https://www.bhupeshchauhan.in/'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Made with ❤️ by ${AppConstants.developerName}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary)),
        ),
      ],
    );
  }

  Widget _buildSocialLink(BuildContext context, IconData icon, String label, String url) {
    return GestureDetector(
      onTap: () async {
        final scaffold = ScaffoldMessenger.of(context);
        try {
          final uri = url.startsWith('mailto:') ? Uri.parse(url) : Uri.parse(url);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          scaffold.showSnackBar(
            SnackBar(content: Text('Could not open $label. Please open it manually.')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
            ),
            Icon(Icons.open_in_new, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
