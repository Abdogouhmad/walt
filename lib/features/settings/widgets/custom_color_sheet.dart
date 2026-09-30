import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/theme/color_schemes.dart';
import 'package:walt/features/settings/widgets/theme_preview_card.dart';
import 'package:walt/providers/theme_provider.dart';

/// Opens the custom-colour picker.
///
/// The last swatch in the Appearance grid hands off here. Nothing is applied
/// until the user confirms, so backing out of the sheet leaves the app exactly
/// as it was.
Future<void> showCustomColorSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _CustomColorSheet(),
  );
}

class _CustomColorSheet extends ConsumerStatefulWidget {
  const _CustomColorSheet();

  @override
  ConsumerState<_CustomColorSheet> createState() => _CustomColorSheetState();
}

class _CustomColorSheetState extends ConsumerState<_CustomColorSheet> {
  late double _hue;
  late double _saturation;
  late double _value;

  @override
  void initState() {
    super.initState();
    final seed = ref.read(themeControllerProvider).customSeed;
    // Start from the colour currently in effect, so opening the sheet on a
    // custom palette and closing it again is a no-op rather than a reset.
    final hsl = HSLColor.fromColor(
      seed ?? ref.read(themeControllerProvider).palette.seed,
    );
    _hue = hsl.hue;
    _saturation = hsl.saturation;
    _value = hsl.lightness;
  }

  Color get _pending =>
      HSLColor.fromAHSL(1, _hue, _saturation, _value).toColor();

  void _apply() {
    final controller = ref.read(themeControllerProvider.notifier);
    final brightness = Theme.of(context).brightness;
    // Clamped, never rejected: see `AppColorSchemes.clampForContrast`.
    final seed = AppColorSchemes.clampForContrast(_pending, brightness);
    controller.setCustomSeed(seed);
    Navigator.of(context).pop();
  }

  void _clear() {
    ref.read(themeControllerProvider.notifier).setCustomSeed(null);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(themeControllerProvider);
    final brightness = theme.brightness;
    final isCustom = settings.isCustom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Custom colour',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (isCustom)
                    TextButton(
                      onPressed: _clear,
                      child: const Text('Use palette'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Pick a hue, then dial in the shade. Walt keeps the label on every '
                'colour readable.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // The preview is the *pending* colour, not the applied one, so
              // the user can see the consequence of a drag before committing.
              ThemePreviewCard(
                settings: settings.copyWith(
                  customSeed: AppColorSchemes.clampForContrast(
                    _pending,
                    brightness,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              _SaturationValuePad(
                hue: _hue,
                saturation: _saturation,
                value: _value,
                onChanged: (saturation, value) => setState(() {
                  _saturation = saturation;
                  _value = value;
                }),
              ),
              const SizedBox(height: AppSpacing.lg),

              _HueSlider(
                hue: _hue,
                onChanged: (hue) => setState(() => _hue = hue),
              ),
              const SizedBox(height: AppSpacing.lg),

              FilledButton(
                onPressed: _apply,
                child: Text(isCustom ? 'Update colour' : 'Use this colour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The two-axis saturation/value pad.
///
/// Saturation runs left to right and value top to bottom, the arrangement every
/// colour picker on every platform uses, so it needs no explanation.
class _SaturationValuePad extends StatelessWidget {
  const _SaturationValuePad({
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
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                    Positioned(
                      left: saturation * constraints.maxWidth - _thumbRadius,
                      top: value * height - _thumbRadius,
                      child: _Thumb(color: pure),
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

  static const double _thumbRadius = 10;
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.color});

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

/// The full-spectrum hue track.
class _HueSlider extends StatelessWidget {
  const _HueSlider({required this.hue, required this.onChanged});

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
