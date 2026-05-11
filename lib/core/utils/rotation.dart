import 'package:flutter/material.dart';

// --- THE REUSABLE COMPONENT ---

/// A widget that switches between two distinct layouts based on the device's orientation.
///
/// This widget uses [OrientationBuilder] to detect the current orientation
/// and renders either the [portrait] widget or the [landscape] widget accordingly.
///
/// Example usage:
/// ```dart
/// RotationHandler(
///   portrait: Column(children: [ ... ]),
///   landscape: Row(children: [ ... ]),
/// )
/// ```
class RotationHandler extends StatelessWidget {
  /// The widget to display when the device is in portrait mode.
  final Widget portrait;

  /// The widget to display when the device is in landscape mode.
  final Widget landscape;

  /// Creates a [RotationHandler] widget.
  ///
  /// Both [portrait] and [landscape] arguments are required.
  const RotationHandler({
    super.key,
    required this.portrait,
    required this.landscape,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return portrait;
        } else {
          return landscape;
        }
      },
    );
  }
}
