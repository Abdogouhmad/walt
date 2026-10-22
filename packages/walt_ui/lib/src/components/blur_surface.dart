import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tokens/radius.dart';
import './surface_shadow.dart';
import './transparency.dart';

/// Android-native frosted surface: calm and tonal, deliberately *not* iOS
/// liquid glass. There are no specular highlights, no refraction and no
/// rainbow edges — just a blurred, lightly tinted slab with a single hairline
/// border and at most one soft shadow.
///
/// Applies to a small, deliberate set of surfaces (the floating nav, the About
/// dialog, optional sheet handles and the FAB scrim). Cards stay flat:
/// blurring every surface is both expensive and visually noisy.
class BlurSurface extends ConsumerWidget {
  const BlurSurface({
    super.key,
    required this.child,
    this.radius = AppRadius.xl,
    this.sigma = defaultSigma,
    this.opacity,
    this.border = true,
    this.shadows = true,
    this.padding,
  });

  /// 24 is the sweet spot: readable through busy content, cheap enough not to
  /// drop frames. The spec caps sigma at 30.
  static const double defaultSigma = 24;
  static const double maxSigma = 30;

  /// Frost tint strength for a surface that has not asked for something
  /// specific. The spec's 0.6–0.8 range; nudged up in light mode where a
  /// lighter backdrop makes the same alpha read as too transparent.
  static const double defaultOpacity = 0.72;
  static const double lightOpacity = 0.82;

  final Widget child;
  final double radius;

  /// Blur strength. Clamped to [maxSigma].
  final double sigma;

  /// Alpha of the tonal fill painted on top of the blur.
  ///
  /// `null` takes the per-brightness default above. Supplying a value overrides
  /// both modes — a surface that needs a *lighter* frost to actually read as
  /// frosted cannot get there while light mode is pinned to [lightOpacity].
  final double? opacity;
  final bool border;
  final bool shadows;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    // Two independent ways to end up opaque: the user asked for it, or the
    // platform says animations are off (battery saver / reduced motion), in
    // which case a live blur is exactly the wrong thing to spend frames on.
    final reduceTransparency =
        ref.watch(reduceTransparencyProvider) ||
        MediaQuery.maybeDisableAnimationsOf(context) == true;

    final tintAlpha =
        opacity ??
        (brightness == Brightness.light ? lightOpacity : defaultOpacity);

    final tint = reduceTransparency
        ? scheme.surfaceContainer
        : scheme.surfaceContainer.withValues(alpha: tintAlpha);

    final shape = BorderRadius.circular(radius);

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: shape,
        border: border
            ? Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                width: 1,
              )
            : null,
      ),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );

    if (reduceTransparency) {
      // Opaque fallback: no BackdropFilter, so nothing to repaint per frame.
      return SurfaceShadow(
        enabled: shadows,
        radius: radius,
        child: ClipRRect(borderRadius: shape, child: surface),
      );
    }

    return SurfaceShadow(
      enabled: shadows,
      radius: radius,
      child: RepaintBoundary(
        // BackdropFilter is expensive; isolating it keeps the rest of the
        // chrome's repaints cheap.
        child: ClipRRect(
          borderRadius: shape,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: sigma.clamp(0, maxSigma),
              sigmaY: sigma.clamp(0, maxSigma),
            ),
            child: surface,
          ),
        ),
      ),
    );
  }
}
