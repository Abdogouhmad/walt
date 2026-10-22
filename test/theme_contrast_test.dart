import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:walt_ui/walt_ui.dart';

import 'support/contrast.dart';

void main() {
  group('every palette × brightness — text', () {
    for (final palette in WaltPalette.values) {
      for (final brightness in Brightness.values) {
        final label = '${palette.name}/${brightness.name}';
        final scheme = AppColorSchemes.forPalette(
          palette,
          brightness: brightness,
        );

        test('$label keeps body text readable on every surface role', () {
          // The four text-on-surface pairs a screen actually uses. If any of
          // these fail, a palette is not shippable regardless of how good the
          // swatch looks.
          expectContrast(
            label,
            scheme.onSurface,
            scheme.surface,
            aaText,
            'onSurface/surface',
          );
          expectContrast(
            label,
            scheme.onSurface,
            scheme.surfaceContainerLow,
            aaText,
            'onSurface/surfaceContainerLow',
          );
          expectContrast(
            label,
            scheme.onSurface,
            scheme.surfaceContainerHigh,
            aaText,
            'onSurface/surfaceContainerHigh',
          );
          expectContrast(
            label,
            scheme.onSurfaceVariant,
            scheme.surfaceContainerHigh,
            aaText,
            'onSurfaceVariant/surfaceContainerHigh',
          );
        });

        test('$label keeps filled and container roles at AA', () {
          // Filled buttons, chips, the nav indicator, the snackbar.
          expectContrast(
            label,
            scheme.onPrimary,
            scheme.primary,
            aaText,
            'onPrimary/primary',
          );
          expectContrast(
            label,
            scheme.onPrimaryContainer,
            scheme.primaryContainer,
            aaText,
            'onPrimaryContainer/primaryContainer',
          );
          expectContrast(
            label,
            scheme.onSecondaryContainer,
            scheme.secondaryContainer,
            aaText,
            'onSecondaryContainer/secondaryContainer',
          );
          expectContrast(
            label,
            scheme.onTertiaryContainer,
            scheme.tertiaryContainer,
            aaText,
            'onTertiaryContainer/tertiaryContainer',
          );
          expectContrast(
            label,
            scheme.onError,
            scheme.error,
            aaText,
            'onError/error',
          );
          expectContrast(
            label,
            scheme.onInverseSurface,
            scheme.inverseSurface,
            aaText,
            'onInverseSurface/inverseSurface',
          );
        });
      }
    }
  });
}
