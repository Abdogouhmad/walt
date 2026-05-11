import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/features/settings/settings_screen.dart';
import 'package:walt/shared/bottom_nav.dart';
// Providers
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
// Screens
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'features/transactions/transaction_list_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/budgets/budgets_screen.dart';
import 'features/auth/lock_screen.dart';
import 'shared/splash_screen.dart';

/// A Listenable that notifies GoRouter when to re-evaluate the redirect logic.
class RouterListenable extends ChangeNotifier {
  final Ref _ref;

  RouterListenable(this._ref) {
    _ref.listen(settingsProvider, (_, _) => notifyListeners());
    _ref.listen(authProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = RouterListenable(ref);

  return GoRouter(
    refreshListenable: listenable,
    initialLocation: '/splash',

    redirect: (BuildContext context, GoRouterState state) {
      final settings = ref.read(settingsProvider);
      final auth = ref.read(authProvider);

      // 1. Wait until settings are loaded
      if (!settings.isLoaded) return '/splash';

      final bool isOnboardingCompleted = settings.isOnboardingCompleted;
      final bool isFingerprintEnabled = settings.isFingerprintEnabled;
      final bool isAuthenticated = auth.isAuthenticated;

      final bool isMatchedOnboarding = state.matchedLocation == '/onboarding';
      final bool isMatchedLock = state.matchedLocation == '/lock';
      final bool isMatchedSplash = state.matchedLocation == '/splash';

      // 2. Force Onboarding if not completed
      if (!isOnboardingCompleted) {
        return isMatchedOnboarding ? null : '/onboarding';
      }

      // 3. Force Lock Screen if fingerprint enabled and not authenticated
      if (isFingerprintEnabled && !isAuthenticated) {
        return isMatchedLock ? null : '/lock';
      }

      // 4. Redirect away from Onboarding, Lock, or Splash if they are no longer needed
      if (isMatchedOnboarding || isMatchedLock || isMatchedSplash) {
        return '/';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/lock', builder: (context, state) => const LockScreen()),

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
});
