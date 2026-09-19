/// Canonical motion tokens for the entire app.
///
/// Centralises the Material 3 expressive motion language: fluid `easeOutCubic`
/// into state, slightly brisker `easeInCubic` back out, and durations that
/// match M3's reference curves (short = micro-interactions, medium = surfaces
/// entering/exiting, long = full-screen transitions). Ported from Brewline's
/// `core/design/motion.dart`.
///
/// Use these instead of raw `Duration`/`Curve` literals so every animation in
/// the app shares the same rhythm.
library;

import 'package:flutter/animation.dart';

/// Motion token set. See the library-level docs above.
abstract final class AppMotion {
  /// Durations (milliseconds) — M3 expressive reference scale.
  static const Duration shortest = Duration(milliseconds: 100);
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration long = Duration(milliseconds: 500);
  static const Duration longest = Duration(milliseconds: 700);

  /// Curves — M3 expressive standard easing.
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutExpo;
  static const Curve exit = Curves.easeInCubic;

  /// M3's emphasised "leaving" curve for surfaces that should feel heavy.
  static const Curve emphasizedExit = Curves.easeInExpo;
}