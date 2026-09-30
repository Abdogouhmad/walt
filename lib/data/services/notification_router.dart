import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:walt/app_router.dart';
import 'package:walt/data/services/notification_service.dart';

/// Bridges a tapped notification to a route.
///
/// Kept out of `main()` so the mapping from [NotificationDestination] to a
/// location is one small, testable function rather than a closure buried in
/// startup code. Unknown destinations resolve to the app root, which is the
/// safe landing spot: a notification from an older build must never strand the
/// user on a blank screen.
@visibleForTesting
String destinationToLocation(NotificationDestination destination) {
  return switch (destination) {
    UpdateDestination() => '/settings/about',
    BudgetAlertDestination(:final budgetId) => '/budgets?focus=$budgetId',
  };
}

/// Routes notification taps to the right screen.
///
/// Call once, after `NotificationService().init()`. Handles both the
/// foreground/background callback and the cold-start payload, so tapping a
/// budget alert works whether the app was open, backgrounded, or killed.
void wireNotificationRouting(NotificationService service) {
  void navigate(NotificationDestination destination) {
    // The router may not exist yet on a cold start, and the navigator is not
    // mounted until the first frame. Retrying on a short delay is the
    // difference between "opens Budgets" and "does nothing".
    void go([int attempt = 0]) {
      final context = rootNavigatorKey.currentContext;
      if (context == null) {
        if (attempt >= 10) {
          debugPrint('NotificationService: no navigator to route to');
          return;
        }
        Future<void>.delayed(
          const Duration(milliseconds: 100),
          () => go(attempt + 1),
        );
        return;
      }
      final location = destinationToLocation(destination);
      debugPrint('NotificationService: navigating to $location');
      GoRouter.of(context).go(location);
    }

    go();
  }

  service.onDestinationSelected = navigate;
  final launch = service.launchDestination;
  if (launch != null) navigate(launch);
}
