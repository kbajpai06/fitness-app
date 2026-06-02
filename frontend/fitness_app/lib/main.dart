import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme.dart';
import 'core/api_client.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';  // ADD THIS

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitCoach AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
      routes: {
        '/login':       (_) => const LoginScreen(),
        '/home':        (_) => const HomeScreen(),
        '/onboarding':  (_) => const OnboardingScreen(),  // ADD THIS
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final token = await ApiClient.getToken();
    if (!mounted) return;

    if (token == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Check if profile is complete
    try {
      final profile = await ApiClient.get('/users/profile');
      final hasProfile = profile['fitness_goal'] != null &&
                         profile['weight_kg'] != null;
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          hasProfile ? '/home' : '/onboarding',
        );
      }
    } catch (_) {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.bolt,
                  color: AppColors.background, size: 36),
              ),
              const SizedBox(height: 20),
              Text('FitCoach AI',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text('Your personal fitness companion',
                style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
// Smooth slide transition
class SlideRoute extends PageRouteBuilder {
  final Widget page;
  final AxisDirection direction;

  SlideRoute({
    required this.page,
    this.direction = AxisDirection.left,
  }) : super(
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final begin = direction == AxisDirection.left
        ? const Offset(1.0, 0.0)
        : const Offset(-1.0, 0.0);
      return SlideTransition(
        position: Tween(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

// Fade transition
class FadeRoute extends PageRouteBuilder {
  final Widget page;
  FadeRoute({required this.page}) : super(
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) =>
      FadeTransition(opacity: animation, child: child),
  );
}