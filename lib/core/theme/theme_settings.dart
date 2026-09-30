import 'package:flutter/material.dart';
import 'package:walt/core/theme/walt_palette.dart';

/// Everything the user can choose about how Walt looks, as one immutable value.
///
/// Grouped deliberately: palette, mode and AMOLED are a single user decision
/// ("how Walt looks"), they are read together on every frame to build the
/// `ThemeData`, and they are written together to storage. Splitting them across
/// three providers would mean three reads and three writes for one tap.
@immutable
class ThemeSettings {
  const ThemeSettings({
    this.palette = WaltPalette.emerald,
    this.mode = ThemeMode.system,
    this.amoled = false,
    this.customSeed,
  });

  /// Factory defaults — also the migration target for a removed Material You
  /// preference, and the value every test starts from.
  static const ThemeSettings defaults = ThemeSettings();

  /// The built-in palette in use. Ignored while [customSeed] is set, but kept
  /// so clearing the custom seed returns to where the user last was rather than
  /// to `emerald`.
  final WaltPalette palette;

  /// Light / dark / follow the system.
  final ThemeMode mode;

  /// True black surfaces in dark mode, for OLED panels.
  final bool amoled;

  /// A user-chosen seed that overrides [palette].
  final Color? customSeed;

  /// Whether the scheme is being driven by a user-picked colour.
  bool get isCustom => customSeed != null;

  /// The colour the `ColorScheme` is generated from.
  Color get seedColor => customSeed ?? palette.seed;

  /// What to call the current selection in the UI.
  String get label => isCustom ? 'Custom' : palette.label;

  /// Distinguishes "argument omitted" from "explicitly cleared" in [copyWith].
  static const Object _unset = Object();

  /// Copies this value, changing only what is passed.
  ///
  /// [customSeed] is the one field that needs the [Object] dance: `null` is a
  /// *meaningful* value for it — "stop using the custom colour" — so a plain
  /// `Color?` parameter with a `?? this.customSeed` body could never express a
  /// clear. Omitting the argument keeps the current seed; passing an explicit
  /// `null` drops it.
  ThemeSettings copyWith({
    WaltPalette? palette,
    ThemeMode? mode,
    bool? amoled,
    Object? customSeed = _unset,
  }) {
    return ThemeSettings(
      palette: palette ?? this.palette,
      mode: mode ?? this.mode,
      amoled: amoled ?? this.amoled,
      customSeed: identical(customSeed, _unset)
          ? this.customSeed
          : customSeed as Color?,
    );
  }

  /// The persisted representation.
  ///
  /// Colours flatten to a 32-bit ARGB int, which is the only form Hive can
  /// store without an adapter, and the only form that survives a round trip
  /// through a JSON backup.
  Map<String, dynamic> toMap() => <String, dynamic>{
    ThemeSettings.keyPalette: palette.name,
    ThemeSettings.keyMode: mode.name,
    ThemeSettings.keyAmoled: amoled,
    ThemeSettings.keyCustomSeed: customSeed?.toARGB32(),
  };

  /// Rebuilds settings from a [Map] of stored values.
  ///
  /// Every field is validated independently and falls back to its default, so a
  /// single corrupt or renamed key never discards the rest of the user's
  /// choices. `null` means "not stored", which for [keyPalette] is the normal
  /// state on a first launch.
  factory ThemeSettings.fromMap(Map<Object?, Object?> map) {
    return ThemeSettings(
      palette: WaltPalette.fromName(_asString(map[ThemeSettings.keyPalette])),
      mode: _asThemeMode(map[ThemeSettings.keyMode]),
      amoled: map[ThemeSettings.keyAmoled] == true,
      customSeed: _asColor(map[ThemeSettings.keyCustomSeed]),
    );
  }

  /// Storage keys. Shared with `HiveService` so the two cannot drift.
  static const String keyPalette = 'theme_palette';
  static const String keyMode = 'theme_mode';
  static const String keyAmoled = 'theme_amoled';
  static const String keyCustomSeed = 'theme_custom_seed';

  static String? _asString(Object? value) => value is String ? value : null;

  static ThemeMode _asThemeMode(Object? value) {
    if (value is! String) return ThemeMode.system;
    for (final mode in ThemeMode.values) {
      if (mode.name == value) return mode;
    }
    return ThemeMode.system;
  }

  static Color? _asColor(Object? value) {
    if (value is int) return Color(value);
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return Color(parsed);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeSettings &&
          other.palette == palette &&
          other.mode == mode &&
          other.amoled == amoled &&
          other.customSeed == customSeed;

  @override
  int get hashCode => Object.hash(palette, mode, amoled, customSeed);

  @override
  String toString() =>
      'ThemeSettings(${palette.name}, ${mode.name}, amoled: $amoled, '
      'custom: ${customSeed?.toARGB32()})';
}
