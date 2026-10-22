import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether haptics are enabled. The app overrides this from settings.
final hapticsEnabledProvider = Provider<bool>((ref) => true);

/// Lightweight haptics helper for consistent tactile feedback.
/// Respects platform capabilities, the app's haptics setting and is safe to
/// call frequently.
abstract final class Haptics {
  const Haptics._();

  /// Light tap feedback for small actions (toggles, icon buttons).
  static Future<void> light([WidgetRef? ref]) async {
    if (ref != null && !ref.read(hapticsEnabledProvider)) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {
      // Ignore haptics errors on unsupported platforms.
    }
  }

  /// Selection feedback for navigation/segmented controls.
  static Future<void> selection([WidgetRef? ref]) async {
    if (ref != null && !ref.read(hapticsEnabledProvider)) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // Ignore haptics errors on unsupported platforms.
    }
  }

  /// Medium impact for confirmations/actions.
  static Future<void> medium([WidgetRef? ref]) async {
    if (ref != null && !ref.read(hapticsEnabledProvider)) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Ignore haptics errors on unsupported platforms.
    }
  }

  /// Heavy impact for destructive/important actions.
  static Future<void> heavy([WidgetRef? ref]) async {
    if (ref != null && !ref.read(hapticsEnabledProvider)) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {
      // Ignore haptics errors on unsupported platforms.
    }
  }
}
