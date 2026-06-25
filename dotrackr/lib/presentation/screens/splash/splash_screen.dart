import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          widget.onComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isTablet = screenSize.width > 400;
    
    final logoSize = isTablet ? 90.0 : (isSmallScreen ? 70.0 : 80.0);
    final checkMarkSize = isTablet ? 48.0 : (isSmallScreen ? 36.0 : 42.0);
    final titleSize = isTablet ? 32.0 : (isSmallScreen ? 26.0 : 28.0);
    final subtitleSize = isTablet ? 14.0 : 12.0;
    final bottomPadding = isSmallScreen ? 40.0 : 60.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 48.0 : 32.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    
                    // Logo container
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Circular background
                          Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.textPrimary,
                                width: 3,
                              ),
                            ),
                          ),
                          // Inner circle
                          Container(
                            width: logoSize - 8,
                            height: logoSize - 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.textPrimary,
                                width: 2,
                              ),
                            ),
                          ),
                          // Checkmark
                          Icon(
                            Icons.check,
                            color: AppColors.textPrimary,
                            size: checkMarkSize,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // DoTrackr - NOT animated
                    Opacity(
                      opacity: 1.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Do',
                            style: GoogleFonts.inter(
                              fontSize: titleSize + 4,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              'Trackr',
                              style: GoogleFonts.inter(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w300,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Track Your Life - animated
                    Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Text(
                          'Track Your Life',
                          style: GoogleFonts.inter(
                            fontSize: subtitleSize,
                            color: AppColors.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    
                    const Spacer(flex: 3),
                    
                    // Powered by - at bottom
                    Padding(
                      padding: EdgeInsets.only(bottom: bottomPadding),
                      child: Column(
                        children: [
                          Text(
                            'Powered by',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bhupesh Chauhan',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}