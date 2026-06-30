import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'data/services/database_service.dart';
import 'data/services/notification_service.dart';
import 'presentation/providers/providers.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/permissions/permissions_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/todos/todos_screen.dart';
import 'presentation/screens/habits/habits_screen.dart';
import 'presentation/screens/stats/stats_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF121212),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    const ProviderScope(
      child: DoTrackrApp(),
    ),
  );
}

class DoTrackrApp extends StatelessWidget {
  const DoTrackrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoTrackr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppWrapper(),
    );
  }
}

enum AppStage { loading, error, splash, onboarding, permissions, main }

class AppWrapper extends ConsumerStatefulWidget {
  const AppWrapper({super.key});

  @override
  ConsumerState<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends ConsumerState<AppWrapper> with WidgetsBindingObserver {
  AppStage _stage = AppStage.loading;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _scheduleDailySummary();
    }
  }

  void _scheduleDailySummary() {
    try {
      final today = DateTime.now();
      
      // Calculate pending todos
      final todos = ref.read(todosProvider);
      final pendingTodos = todos.where((t) => !t.isCompleted).length;

      // Calculate pending habits
      final habits = ref.read(habitsProvider);
      final habitLogs = ref.read(habitLogsProvider);
      int pendingHabits = 0;
      for (final habit in habits) {
        final hasLogToday = habitLogs.any((log) {
          return log.habitId == habit.id && 
                 log.completedAt.year == today.year && 
                 log.completedAt.month == today.month && 
                 log.completedAt.day == today.day;
        });
        if (!hasLogToday) pendingHabits++;
      }
      
      NotificationService().updateDailySummary(pendingTodos, pendingHabits);
    } catch (e) {
      debugPrint('scheduleDailySummary error: $e');
    }
  }

  Future<void> _initialize() async {
    try {
      await DatabaseService().init();
      await NotificationService().init();
      await ref.read(userProvider.notifier).loadUser();

      final notif = NotificationService();
      notif.onNotificationTap = _handleNotificationTap;

      // Read native crash log (from MainActivity crash catcher)
      const platform = MethodChannel('com.dotrackr.crash');
      try {
        final String? crashLog = await platform.invokeMethod('getCrashLog');
        if (crashLog != null && crashLog.isNotEmpty) {
          debugPrint('NATIVE CRASH LOG:\n$crashLog');
          if (mounted) {
            setState(() {
              _stage = AppStage.error;
              _errorMessage = 'CRASH TRACE:\n$crashLog';
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('getCrashLog channel error: $e');
      }

      if (mounted) {
        setState(() {
          _stage = AppStage.splash;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stage = AppStage.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _handleNotificationTap(String? rawPayload) {
    if (rawPayload == null) return;
    try {
      final data = jsonDecode(rawPayload) as Map<String, dynamic>;
      final type = data['type'] as String?;
      if (type == 'todo') {
        ref.read(selectedTabProvider.notifier).state = 1;
      } else if (type == 'habit') {
        ref.read(selectedTabProvider.notifier).state = 2;
      }
    } catch (e) {
      debugPrint('handleNotificationTap: $e');
    }
  }

  void _nextStage() {
    setState(() {
      switch (_stage) {
        case AppStage.splash:
          final user = ref.read(userProvider);
          if (user != null && user.isOnboardingComplete) {
            _stage = AppStage.main;
          } else {
            _stage = AppStage.onboarding;
          }
          break;
        case AppStage.onboarding:
          _stage = AppStage.permissions;
          break;
        case AppStage.permissions:
          _stage = AppStage.main;
          break;
        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (_stage) {
      case AppStage.loading:
        child = const Scaffold(
          backgroundColor: Color(0xFF000000),
          body: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        );
        break;

      case AppStage.error:
        child = Scaffold(
          backgroundColor: const Color(0xFF000000),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to start DoTrackr',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _errorMessage ?? 'Unknown error',
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _stage = AppStage.loading;
                        _errorMessage = null;
                      });
                      _initialize();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        break;

      case AppStage.splash:
        child = SplashScreen(onComplete: _nextStage);
        break;

      case AppStage.onboarding:
        child = OnboardingScreen(onComplete: _nextStage);
        break;

      case AppStage.permissions:
        child = PermissionsScreen(onComplete: _nextStage);
        break;

      case AppStage.main:
        child = const MainNavigationScreen();
        break;
    }

    return child;
  }
}

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: selectedTab,
        children: const [
          HomeScreen(),
          TodosScreen(),
          HabitsScreen(),
          StatsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF3A3A3A), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedTab,
          onTap: (index) {
            ref.read(selectedTabProvider.notifier).state = index;
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF121212),
          selectedItemColor: Colors.white,
          unselectedItemColor: const Color(0xFF707070),
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: 'Todos'),
            BottomNavigationBarItem(icon: Icon(Icons.track_changes_outlined), activeIcon: Icon(Icons.track_changes), label: 'Habits'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Stats'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}