import 'package:flutter/material.dart';

// Define an enum for common text types from the theme
enum UiTextType {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}

/// A reusable Text widget that leverages the application's theme.
/// It applies the theme's text styles by default and allows for custom overrides.
class UiText extends StatelessWidget {
  final String text;
  final TextStyle? style; // Optional style to override theme defaults
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool softWrap;
  final UiTextType type; // Parameter to select base theme text style

  const UiText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap = true,
    this.type = UiTextType.bodyMedium, // Default to bodyMedium if not specified
  });

  @override
  Widget build(BuildContext context) {
    // Access the current theme's text theme and color scheme
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Select the base style based on the 'type' parameter
    TextStyle? baseStyle;
    switch (type) {
      case UiTextType.displayLarge:
        baseStyle = textTheme.displayLarge;
        break;
      case UiTextType.displayMedium:
        baseStyle = textTheme.displayMedium;
        break;
      case UiTextType.displaySmall:
        baseStyle = textTheme.displaySmall;
        break;
      case UiTextType.headlineLarge:
        baseStyle = textTheme.headlineLarge;
        break;
      case UiTextType.headlineMedium:
        baseStyle = textTheme.headlineMedium;
        break;
      case UiTextType.headlineSmall:
        baseStyle = textTheme.headlineSmall;
        break;
      case UiTextType.titleLarge:
        baseStyle = textTheme.titleLarge;
        break;
      case UiTextType.titleMedium:
        baseStyle = textTheme.titleMedium;
        break;
      case UiTextType.titleSmall:
        baseStyle = textTheme.titleSmall;
        break;
      case UiTextType.bodyLarge:
        baseStyle = textTheme.bodyLarge;
        break;
      case UiTextType.bodyMedium:
        baseStyle = textTheme.bodyMedium;
        break;
      case UiTextType.bodySmall:
        baseStyle = textTheme.bodySmall;
        break;
      case UiTextType.labelLarge:
        baseStyle = textTheme.labelLarge;
        break;
      case UiTextType.labelMedium:
        baseStyle = textTheme.labelMedium;
        break;
      case UiTextType.labelSmall:
        baseStyle = textTheme.labelSmall;
        break;
    }

    // Ensure a base style is always available. If theme style is null, fallback to a default.
    // The `copyWith` here ensures the color from the current color scheme is applied
    // if the baseStyle doesn't already have a color or if it needs to adapt to `onSurface`.
    // Then the explicitly provided `style` will override this if it has its own color.
    TextStyle effectiveStyle = (baseStyle ?? const TextStyle()).copyWith(
      color: colorScheme.onSurface, // Default text color based on theme
    );

    // Merge with any provided custom style. Properties in `style` will take precedence.
    effectiveStyle = effectiveStyle.merge(style);

    return Text(
      text,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
      style: effectiveStyle,
    );
  }
}
