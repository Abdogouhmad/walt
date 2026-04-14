import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/features/settings/settings_screen.dart';
import 'package:walt/shared/bottom_nav.dart';
// Providers
import 'providers/settings_provider.dart';
// Screens
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'features/transactions/transaction_list_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/budgets/budgets_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/onboarding',

  // Fixed Redirect Logic
  redirect: (BuildContext context, GoRouterState state) {
    final settings = ProviderScope.containerOf(context).read(settingsProvider);
    final bool isOnboardingCompleted = settings.isOnboardingCompleted;

    // If user has NOT completed onboarding → force them to onboarding page
    if (!isOnboardingCompleted && state.matchedLocation != '/onboarding') {
      return '/onboarding';
    }

    // If user has completed onboarding but is still on onboarding page → go to home
    if (isOnboardingCompleted && state.matchedLocation == '/onboarding') {
      return '/';
    }

    return null; // No redirect needed
  },

  routes: [
    // Onboarding Route (Outside the bottom nav shell)
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Main App Shell with Bottom Navigation
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/transactions',
          builder: (context, state) => const TransactionListScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/budgets',
          builder: (context, state) => const BudgetsScreen(),
        ),
      ],
    ),
  ],
);
