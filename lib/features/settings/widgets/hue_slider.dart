import 'package:flutter/material.dart';
import 'package:walt_ui/walt_ui.dart';

/// The full-spectrum hue track.
class HueSlider extends StatelessWidget {
  const HueSlider({super.key, required this.hue, required this.onChanged});

  final double hue;
  final ValueChanged<double> onChanged;

  static const double height = 28;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hue',
      slider: true,
      value: '${hue.round()} degrees',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              void report(Offset local) => onChanged(
                (local.dx / constraints.maxWidth * 360).clamp(0.0, 360.0),
              );

              return GestureDetector(
                onTapDown: (details) => report(details.localPosition),
                onPanDown: (details) => report(details.localPosition),
                onPanUpdate: (details) => report(details.localPosition),
                child: Stack(
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFF0000),
                            Color(0xFFFFFF00),
                            Color(0xFF00FF00),
                            Color(0xFF00FFFF),
                            Color(0xFF0000FF),
                            Color(0xFFFF00FF),
                            Color(0xFFFF0000),
                          ],
                        ),
                      ),
                      child: SizedBox.expand(),
                    ),
                    Positioned(
                      left: hue / 360 * constraints.maxWidth - 12,
                      child: Container(
                        width: 24,
                        height: height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.shadow.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
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
