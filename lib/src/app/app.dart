import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import '../features/base_camp/presentation/base_camp_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/review/presentation/review_arena_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const bootstrap = '/bootstrap';
  static const home = '/';
  static const baseCamp = '/base-camp';
  static const reviewArena = '/review-arena';
  static const onboarding = '/onboarding';
  static const senseiIntro = '/sensei-intro';
}

class AppPrefsKeys {
  const AppPrefsKeys._();

  static const userName = 'user_name';
  static const dailyGoal = 'daily_goal';
  static const startingPath = 'starting_path';
  static const onboardingComplete = 'onboarding_complete';
}

class KanaQuestApp extends StatelessWidget {
  const KanaQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kana Quest',
        theme: AppTheme.light(),
        initialRoute: AppRoutes.bootstrap,
        routes: {
          AppRoutes.bootstrap: (context) => const _AppBootstrapScreen(),
          AppRoutes.home: (context) => const HomeScreen(),
          AppRoutes.baseCamp: (context) => const BaseCampScreen(),
          AppRoutes.reviewArena: (context) => const ReviewArenaScreen(),
          AppRoutes.onboarding: (context) => const OnboardingScreen(),
        },
      ),
    );
  }
}

class _AppBootstrapScreen extends StatefulWidget {
  const _AppBootstrapScreen();

  @override
  State<_AppBootstrapScreen> createState() => _AppBootstrapScreenState();
}

class _AppBootstrapScreenState extends State<_AppBootstrapScreen> {
  @override
  void initState() {
    super.initState();
    _resolveFirstRoute();
  }

  Future<void> _resolveFirstRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete =
        prefs.getBool(AppPrefsKeys.onboardingComplete) ?? false;

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      onboardingComplete ? AppRoutes.home : AppRoutes.onboarding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
