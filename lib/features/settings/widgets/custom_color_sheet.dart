import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/features/settings/widgets/hue_slider.dart';
import 'package:walt/features/settings/widgets/saturation_value_pad.dart';
import 'package:walt/features/settings/widgets/theme_preview_card.dart';
import 'package:walt/providers/theme_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// Opens the custom-colour picker.
///
/// The last swatch in the Appearance grid hands off here. Nothing is applied
/// until the user confirms, so backing out of the sheet leaves the app exactly
/// as it was.
///
/// Routed through [showWaltModal] so the sheet hides the floating nav pill and
/// the FAB while it is open, exactly like every other sheet in the app.
Future<void> showCustomColorSheet(BuildContext context) {
  return showWaltModal<void>(
    context,
    content: const CustomColorSheet(),
    heightFactor: 0.8,
  );
}

/// The custom-colour picker body: a live preview of the pending colour, the
/// saturation/value pad, the hue track and the commit button.
class CustomColorSheet extends ConsumerStatefulWidget {
  const CustomColorSheet({super.key});

  @override
  ConsumerState<CustomColorSheet> createState() => _CustomColorSheetState();
}

class _CustomColorSheetState extends ConsumerState<CustomColorSheet> {
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

    return SingleChildScrollView(
      child: Padding(
        padding: waltModalPadding(context),
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

            // The preview is the *pending* colour, not the applied one, so the
            // user can see the consequence of a drag before committing.
            ThemePreviewCard(
              settings: settings.copyWith(
                customSeed: AppColorSchemes.clampForContrast(
                  _pending,
                  brightness,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            SaturationValuePad(
              hue: _hue,
              saturation: _saturation,
              value: _value,
              onChanged: (saturation, value) => setState(() {
                _saturation = saturation;
                _value = value;
              }),
            ),
            const SizedBox(height: AppSpacing.lg),

            HueSlider(
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
    );
  }
}
