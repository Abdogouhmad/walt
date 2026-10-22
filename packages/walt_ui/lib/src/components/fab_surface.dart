import 'package:flutter/material.dart';

import '../tokens/radius.dart';

/// The round surface the floating action button is drawn on.
///
/// A tinted, raised disc with a single glyph that rotates into a close icon
/// while the menu is open.
class FabSurface extends StatelessWidget {
  final double size;
  final ColorScheme scheme;
  final bool open;
  final Animation<double>? turns;
  final String semanticsLabel;
  final VoidCallback onTap;

  const FabSurface({
    super.key,
    required this.size,
    required this.scheme,
    required this.open,
    required this.turns,
    required this.semanticsLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
    );

    return Semantics(
      button: true,
      toggled: open,
      label: semanticsLabel,
      child: Material(
        color: scheme.primaryContainer,
        elevation: 3,
        shadowColor: scheme.shadow,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: SizedBox(
            width: size,
            height: size,
            child: turns == null
                ? Icon(
                    open ? Icons.close_rounded : Icons.add_rounded,
                    size: 32,
                    color: scheme.onPrimaryContainer,
                  )
                : AnimatedBuilder(
                    animation: turns!,
                    builder: (context, _) => Transform.rotate(
                      angle: turns!.value * 3.14159265 / 4,
                      child: Icon(
                        turns!.value < 0.5
                            ? Icons.add_rounded
                            : Icons.close_rounded,
                        size: 32,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
