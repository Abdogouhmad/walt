import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:walt/providers/settings_provider.dart';
import 'dart:io' as platform;

class AuthState {
  final bool isAuthenticated;
  final bool isAuthenticating;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.isAuthenticating = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isAuthenticating,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  AuthState build() {
    return AuthState();
  }

  Future<bool> authenticate({bool force = false}) async {
    final settings = ref.read(settingsProvider);

    if (!settings.isLoaded) return false;

    if (platform.Platform.isLinux) {
      state = state.copyWith(isAuthenticated: true);
      debugPrint("this is linux i cant auth i allowed you");
      return true;
    }

    // If not enabled and not forced, we consider it "authenticated" (no lock)
    if (!settings.isFingerprintEnabled && !force) {
      state = state.copyWith(isAuthenticated: true);
      return true;
    }

    state = state.copyWith(isAuthenticating: true, error: null);

    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || isDeviceSupported;

      debugPrint(
        'Biometric status: canCheck=$canAuthenticateWithBiometrics, supported=$isDeviceSupported',
      );

      if (!canAuthenticate) {
        state = state.copyWith(
          isAuthenticating: false,
          isAuthenticated: false,
          error: 'Biometric authentication not available on this device',
        );
        return false;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access Walt',
        biometricOnly: false, // Allows PIN/Pattern fallback
        persistAcrossBackgrounding: true, // Replaces stickyAuth in this version
      );

      if (ref.mounted) {
        state = state.copyWith(
          isAuthenticating: false,
          isAuthenticated: didAuthenticate,
          error: didAuthenticate ? null : 'Authentication failed',
        );
      }

      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Biometric PlatformException: ${e.code} - ${e.message}');
      if (ref.mounted) {
        state = state.copyWith(
          isAuthenticating: false,
          error: 'Security error: ${e.message ?? e.code}',
        );
      }
      return false;
    } catch (e) {
      debugPrint('Biometric Error: $e');
      if (ref.mounted) {
        state = state.copyWith(isAuthenticating: false, error: e.toString());
      }
      return false;
    }
  }

  void logout() {
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
