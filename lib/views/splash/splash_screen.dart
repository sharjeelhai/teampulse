import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';
import '../dashboard/super_admin_dashboard.dart';
import '../dashboard/chapter_lead_dashboard.dart';
import '../dashboard/team_lead_dashboard.dart';
import '../dashboard/member_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // minimum time to show splash
  static const Duration _minSplashDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // Start animation immediately
    _controller.forward();

    // Kick off initialization and navigation after animation + minimum delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    final DateTime start = DateTime.now();

    try {
      // Attempt to load local user (AuthViewModel handles any internal errors)
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      try {
        await authViewModel.loadUserFromLocal();
        debugPrint(
          'Splash: loadUserFromLocal completed, authenticated=${authViewModel.isAuthenticated}',
        );
      } catch (e, st) {
        // Catch errors from loadUserFromLocal so splash doesn't crash
        debugPrint('Splash: loadUserFromLocal error: $e\n$st');
      }

      // Ensure we show splash for at least _minSplashDuration
      final elapsed = DateTime.now().difference(start);
      if (elapsed < _minSplashDuration) {
        await Future.delayed(_minSplashDuration - elapsed);
      }

      // Wait for the animation to reach completion (if it hasn't yet)
      if (_controller.status != AnimationStatus.completed) {
        try {
          await _controller.forward().orCancel;
        } catch (_) {
          // controller may be disposed if user closed app; ignore
        }
      }

      if (!mounted) return;

      // Navigate based on auth state; guard in try/catch to prevent silent failures
      if (authViewModel.isAuthenticated && authViewModel.currentUser != null) {
        _navigateToDashboard(authViewModel.currentUser!);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e, st) {
      debugPrint('Splash initialization unexpected error: $e\n$st');

      // On unexpected errors, fall back to login screen to allow user to continue
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _navigateToDashboard(UserModel user) {
    Widget dashboard;

    // Choose dashboard by user role
    switch (user.role) {
      case UserRole.superAdmin:
        dashboard = const SuperAdminDashboard();
        break;
      case UserRole.chapterLead:
        dashboard = const ChapterLeadDashboard();
        break;
      case UserRole.teamLead:
        dashboard = const TeamLeadDashboard();
        break;
      case UserRole.member:
        dashboard = const MemberDashboard();
        break;
    }

    try {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => dashboard));
    } catch (e, st) {
      debugPrint('Splash navigation failed: $e\n$st');
      // As a fallback navigate to login so user can retry login/signup
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryPurple, AppTheme.secondaryCyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPurple.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.groups,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'TeamPulse',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'GDG Team Management',
                  style: TextStyle(fontSize: 16, color: Colors.white60),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
