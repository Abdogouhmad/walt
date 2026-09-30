# Walt — Multiple Themes with User Color Choice

Companion to `WALT_M3_EXPRESSIVE.md` and `WALT_REDESIGN_FIXES.md`. Where they conflict, **this file wins** (no dynamic/Material You colors).

Rules: read the codebase first, keep the existing state management and storage, no new network calls, no hardcoded colors in screens, run `flutter analyze` + `dart format .` after each phase, commit per phase.

---

## Goal

- **Remove dynamic color entirely** (wallpaper/Material You). Delete the `dynamic_color` dependency, `DynamicColorBuilder`, and any related settings.
- Ship **several built-in color themes**. The user picks one in **Settings → Appearance**. The choice applies instantly and persists across launches.
- Independent **mode** control: System / Light / Dark. Optional **Pure black (AMOLED)** switch for dark mode.

---

## Phase 1 — Theme model

Create `lib/core/theme/`:

`walt_palette.dart`
```dart
enum WaltPalette {
  emerald('Emerald', Color(0xFF1B9E77)),
  ocean('Ocean', Color(0xFF1E88E5)),
  indigo('Indigo', Color(0xFF5C6BC0)),
  violet('Violet', Color(0xFF8E5CD9)),
  rose('Rose', Color(0xFFE25577)),
  amber('Amber', Color(0xFFF0A020)),
  terracotta('Terracotta', Color(0xFFC8664A)),
  teal('Teal', Color(0xFF00897B)),
  graphite('Graphite', Color(0xFF607D8B));

  const WaltPalette(this.label, this.seed);
  final String label;
  final Color seed;
}
```
- Default palette: `emerald` (matches the app icon).
- Adding a palette later = adding one enum entry. No other code changes.

`theme_settings.dart` (immutable model, `copyWith`, equality):
- `WaltPalette palette`
- `ThemeMode mode` (default `system`)
- `bool amoled` (default `false`)
- `Color? customSeed` (optional, see Phase 5; when non-null it overrides `palette`)

`app_theme.dart`:
```dart
ThemeData buildTheme(ThemeSettings s, Brightness b) {
  var scheme = ColorScheme.fromSeed(
    seedColor: s.customSeed ?? s.palette.seed,
    brightness: b,
    dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
  );
  if (b == Brightness.dark && s.amoled) {
    scheme = scheme.copyWith(
      surface: Colors.black,
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: const Color(0xFF0A0A0A),
      surfaceContainer: const Color(0xFF111111),
      surfaceContainerHigh: const Color(0xFF181818),
      surfaceContainerHighest: const Color(0xFF202020),
    );
  }
  return _base(scheme); // existing M3 component themes, text theme, shapes, motion
}
```
- Keep the existing component themes (cards, nav, sheets, chips, buttons, inputs), the bundled font, and the type scale. They must read only from `ColorScheme`/`ThemeExtension`, so every palette works automatically.
- `WaltColors` ThemeExtension (income, expense, warning): derive with `harmonizeWith(scheme.primary)` **per scheme**, and guarantee income stays green-ish and expense red-ish and distinguishable in every palette (do not let harmonization turn them into the primary hue; use a low harmonization amount or fixed hue with tone adjusted for contrast).
- Chart palette: derive category/series colors from the scheme (`primary`, `secondary`, `tertiary`, and their containers, plus tone-shifted variants) — never hardcoded.

---

## Phase 2 — State & persistence

- `ThemeController` (use the project's existing state solution, e.g. Riverpod `Notifier<ThemeSettings>`).
- Persist locally with the storage already in the project (`shared_preferences` or the existing DB/settings store). Keys: `theme_palette` (enum name), `theme_mode`, `theme_amoled`, `theme_custom_seed` (int ARGB, nullable). Unknown/invalid stored values fall back to defaults.
- **Load settings before `runApp`** (await in `main()`) and pass as the provider's initial value so there is no theme flash on startup.
- `MaterialApp`:
```dart
MaterialApp(
  theme: buildTheme(s, Brightness.light),
  darkTheme: buildTheme(s, Brightness.dark),
  themeMode: s.mode,
  themeAnimationDuration: const Duration(milliseconds: 300),
  themeAnimationCurve: Curves.easeOutCubic,
)
```
- Update system UI overlay (status/nav bar icon brightness, transparent bars) whenever the effective brightness changes. Use `AnnotatedRegion<SystemUiOverlayStyle>` at the root, driven by the current `ColorScheme`.
- Migration: if a previous "dynamic color" setting exists, delete it and fall back to `emerald`.

---

## Phase 3 — Settings → Appearance UI

Add an **Appearance** section (Settings is opened from the profile avatar). Keep it simple and scannable:

1. **Mode**: `SegmentedButton<ThemeMode>` with System / Light / Dark (icons: `brightness_auto`, `light_mode`, `dark_mode`).
2. **Pure black** (`SwitchListTile`, only enabled when effective brightness is dark or mode is Dark): "Pure black (AMOLED)".
3. **Color**: a horizontally wrapping grid of **swatch chips** (48dp circles, 12dp spacing):
   - Each swatch shows the palette's `primary` with a small `tertiary`/`secondaryContainer` half-circle accent (generated from that palette's scheme in the current brightness).
   - Selected swatch: check icon on top, 3dp `primary` ring, animated with a spring scale.
   - Label under each (palette name, `labelMedium`); `Semantics(selected: ..., label: 'Emerald theme')`.
   - Tap applies immediately with haptic `selectionClick`.
4. **Live preview card** above the grid: a mini mock (balance card, two pills, a progress bar, a chip, a filled button) rendered inside a nested `Theme(data: previewTheme)` for the currently highlighted palette, so the user sees the result before/while choosing. Applying is instant, so the preview simply reflects the active scheme.
5. **Reduce transparency** switch (from the blur nav work) stays in this section.

Use the shared widget kit (`SectionHeader`, `GroupedList`, `AppCard`). No hardcoded colors; swatches take colors from generated `ColorScheme`s.

---

## Phase 4 — Audit every screen

- Search the whole codebase for hardcoded colors: `Color(0x`, `Colors.` (except `Colors.transparent`, and `Colors.black` inside the AMOLED override), `.withOpacity(` on literals, and `const Color`. Replace with `Theme.of(context).colorScheme.*` or `WaltColors`.
- Verify **every screen** (Home, Activity, Budget, Reports, Settings, Add/Edit, dialogs, sheets, snackbars, blur nav bar, charts, notifications' accent color) in **all palettes × light/dark/AMOLED**.
- Contrast: text on `primary`, `primaryContainer`, `secondaryContainer` must meet AA. Amber/Rose in light mode need particular care; if a seed produces poor contrast, adjust that palette's seed, not the screens.
- Blur nav: tint derived from `surfaceContainer`; check legibility on each palette.
- Android: set `colorPrimary`-based accents that are static (launcher icon stays fixed; do **not** recolor the icon). Splash background should follow system light/dark only.

---

## Phase 5 — Optional custom color

Only if time allows and it stays clean:
- A last swatch **"Custom"** (color wheel icon) opens a bottom sheet with a hue slider + saturation/brightness (implement with a small custom HSV picker or a well-maintained package verified on pub.dev).
- Stores `customSeed`; selecting any built-in palette clears it.
- Reject seeds that produce a scheme failing minimum contrast between `onPrimary/primary`; clamp tone/chroma instead of showing an error.

---

## Phase 6 — Tests

- Unit: `ThemeSettings` serialization round-trip, invalid values fallback, migration from removed dynamic setting.
- Unit: for every `WaltPalette` × brightness, `onPrimary` vs `primary` and `onSurface` vs `surface` contrast ≥ 4.5:1; income/expense colors pass ≥ 3:1 against `surfaceContainer`.
- Widget: selecting a swatch updates `Theme.of(context).colorScheme.primary` and persists; mode switch works; AMOLED toggles surface to black.
- Golden (if a golden setup exists): Home screen for 3 palettes in light and dark.

---

## Definition of Done
- [ ] `dynamic_color` removed; no Material You code remains
- [ ] 9 built-in palettes + System/Light/Dark + AMOLED, all persisted
- [ ] No theme flash at startup; smooth animated transition on change
- [ ] Appearance settings with swatch grid and live preview
- [ ] No hardcoded colors left in screens; charts and income/expense colors follow the theme
- [ ] Contrast tests pass for all palettes
- [ ] `flutter analyze` clean, debug APK builds, tests pass, CHANGELOG updated
