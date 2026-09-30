/// Canonical motion tokens for the entire app.
///
/// Two families live here:
///
///  * [AppMotion] — the classic M3 easing/duration scale (short, medium, long
///    + `easeOutCubic` / `easeInCubic` / `easeOutExpo`). Kept for the many
///    places that animate *appearance* rather than *geometry*.
///  * [AppSpring] — the Material 3 **Expressive** spring language. Anything
///    that moves in space (the nav pill, the FAB, press states, list entry)
///    uses a spring so it carries a little weight instead of easing linearly.
///
/// Use these tokens instead of raw `Duration`/`Curve` literals so every
/// animation in the app shares the same rhythm.
library;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Motion token set: M3 durations and easing curves.
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

/// Material 3 Expressive spring tokens.
///
/// The app never invents a spring: pick [AppSpring.spatial] for things that
/// move in space and [AppSpring.effects] for things that only change colour
/// or opacity (where overshoot reads as a glitch, not as delight).
abstract final class AppSpring {
  const AppSpring._();

  /// Slightly bouncy — nav pill, FAB, press states, list entry.
  static final SpringDescription spatial =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 500),
        bounce: 0.35,
      );

  /// No bounce — colour and opacity transitions.
  static final SpringDescription effects =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 350),
        bounce: 0,
      );

  /// Upper bound on a spring's settle window, in seconds. The spec caps every
  /// animation at 500 ms; a spring's asymptotic tail beyond that is
  /// imperceptible, so it is trimmed rather than rendered.
  static const double _maxSeconds = 0.5;

  /// A [Curve] that replays [description] from 0 to 1.
  ///
  /// This is what lets spring physics drive *implicit* animations
  /// (`AnimatedContainer`, `AnimatedSize`, `AnimatedPositioned`, …) — pass it
  /// wherever a `Curve` is expected and the interpolation becomes springy.
  static Curve curve(SpringDescription description) =>
      _SpringCurve(description);

  /// Drives an explicit [AnimationController] with the spring simulation.
  static TickerFuture animate(
    AnimationController controller, {
    SpringDescription? description,
    bool spatial = true,
  }) {
    final spring =
        description ?? (spatial ? AppSpring.spatial : AppSpring.effects);
    return controller.animateWith(
      SpringSimulation(spring, controller.value, 1, 0),
    );
  }

  /// Whether the user has asked the platform to suppress animations.
  ///
  /// Honouring this is a hard accessibility requirement: every spring and
  /// timed animation in the app should collapse to an instant state change
  /// when it returns `false`.
  static bool isDisabled(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// A duration that collapses to zero when animations are disabled.
  static Duration durationOf(
    BuildContext context, {
    Duration fallback = AppMotion.medium,
  }) => isDisabled(context) ? Duration.zero : fallback;
}

/// A [Curve] backed by a real [SpringSimulation], normalised to the 0→1 range
/// over the spring's settle window.
class _SpringCurve extends Curve {
  _SpringCurve(SpringDescription description)
    : simulation = SpringSimulation(description, 0, 1, 0);

  final SpringSimulation simulation;

  double get _settleSeconds {
    // Sample until the simulation reports done, capped so no spring in the app
    // can drag on past the 500 ms ceiling.
    for (var t = 0.02; t <= AppSpring._maxSeconds; t += 0.02) {
      if (simulation.isDone(t)) return t;
    }
    return AppSpring._maxSeconds;
  }

  @override
  double transformInternal(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    return simulation.x(t * _settleSeconds);
  }
}
