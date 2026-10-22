import 'package:flutter/material.dart';
import 'package:walt_ui/walt_ui.dart';

/// The two-axis saturation/value pad.
///
/// Saturation runs left to right and value top to bottom, the arrangement every
/// colour picker on every platform uses, so it needs no explanation.
class SaturationValuePad extends StatelessWidget {
  const SaturationValuePad({
    super.key,
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  final double hue;
  final double saturation;
  final double value;
  final void Function(double saturation, double value) onChanged;

  static const double height = 148;
  static const double _thumbRadius = 10;

  @override
  Widget build(BuildContext context) {
    final pure = HSLColor.fromAHSL(1, hue, 1, value).toColor();

    return Semantics(
      label: 'Saturation and brightness',
      slider: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              void report(Offset local) {
                onChanged(
                  (local.dx / constraints.maxWidth).clamp(0.0, 1.0),
                  (local.dy / height).clamp(0.0, 1.0),
                );
              }

              return GestureDetector(
                onTapDown: (details) => report(details.localPosition),
                onPanDown: (details) => report(details.localPosition),
                onPanUpdate: (details) => report(details.localPosition),
                child: Stack(
                  children: [
                    // White → the pure hue across, then transparent → black
                    // down. These two are the *definition* of the pad: they are
                    // absolute, not themed — a themed pad could not show a
                    // colour the theme does not contain yet.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, pure],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: SizedBox.expand(),
                    ),
                    Positioned(
                      left: saturation * constraints.maxWidth - _thumbRadius,
                      top: value * height - _thumbRadius,
                      child: ColorThumb(color: pure),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The round handle that marks the current position on a colour pad.
class ColorThumb extends StatelessWidget {
  const ColorThumb({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
      ),
    );
  }
}
