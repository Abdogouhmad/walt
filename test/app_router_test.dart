import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walt/app_router.dart';
import 'package:walt/providers/auth_provider.dart';
import 'package:walt/providers/settings_provider.dart';

/// These routes are only ever registered once the app boots, and the
/// registration itself is where a mis-parented `parentNavigatorKey` throws.
/// The static analyzer cannot see that assertion — it fires at construction
/// inside go_router — so it needs a test that builds the real router.
ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [
      settingsProvider.overrideWith(
        () => _StubSettings(
          SettingsState(isLoaded: true, isOnboardingCompleted: true),
        ),
      ),
      authProvider.overrideWith(
        () => _StubAuth(AuthState(isAuthenticated: true)),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

class _StubSettings extends SettingsNotifier {
  _StubSettings(this._state);
  final SettingsState _state;

  @override
  SettingsState build() => _state;
}

class _StubAuth extends AuthNotifier {
  _StubAuth(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

void main() {
  test('router builds without a parentNavigatorKey assertion', () {
    final router = _container().read(routerProvider);

    // Constructing the router is the assertion under test; reaching here means
    // the routing table was accepted.
    expect(router.routerDelegate, isNotNull);
  });

  test('settings and about sit on the root navigator, outside the shell', () {
    final router = _container().read(routerProvider);

    final routes = router.configuration.routes;
    final topLevel = <String>{
      for (final route in routes)
        if (route is GoRoute) route.path,
    };
    expect(topLevel, contains('/settings'));
    expect(topLevel, contains(kAboutRoute));

    // The four tab destinations live on the shell, not the root — a route that
    // has drifted up here would render a screen with no floating nav.
    final shell = routes.whereType<ShellRoute>().single;
    final shellPaths = <String>{
      for (final route in shell.routes)
        if (route is GoRoute) route.path,
    };
    expect(
      shellPaths,
      containsAll(<String>['/', '/transactions', '/budgets', '/reports']),
    );

    // Settings and About opt out of the shell, so the nav stays mounted under
    // them and the back arrow comes for free.
    for (final route in routes.whereType<GoRoute>()) {
      if (route.path == '/settings' || route.path == kAboutRoute) {
        expect(route.parentNavigatorKey, same(rootNavigatorKey));
      }
    }
  });
}
