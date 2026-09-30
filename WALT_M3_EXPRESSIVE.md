# Walt — Material 3 + M3 Expressive Upgrade

You are working on **Walt**, a privacy-first Android expense tracker built with Flutter.
Goal: make the UI follow **Material 3 conventions**, with **M3 Expressive used as an accent (~40%) on specific components**. Simple, minimal, modern. Do not change business logic, data layer, or providers unless a task below requires it.

## Ground Rules

1. Read the project first: `pubspec.yaml`, `lib/` structure, theme files, router, existing widgets. Match existing architecture (Riverpod, SQLite/Hive, fl_chart). Do not introduce a new state manager.
2. Work in small steps. After each phase run `flutter analyze` and `dart format .`, and fix all warnings. Build once per phase: `flutter build apk --debug`.
3. Use `Theme.of(context)` tokens only. **No hardcoded colors, text styles, radii, or spacing** inside screens.
4. Prefer built-in Flutter Material widgets. Add a package only if it is actively maintained, null-safe, and compatible with the project's Flutter SDK. Verify on pub.dev before adding. Prefer writing a small custom widget over adding a fragile dependency.
5. Keep screens light: fewer cards, more whitespace, clear hierarchy. No nested cards, no decorative gradients, no mint-on-mint monotone surfaces.
6. Android only. Support light + dark + dynamic color.
7. Keep all existing features working (biometric auth, exports, notification capture, AI insights).

## Phase 1 — Theme Foundation

Create/refactor `lib/core/theme/`:

- `app_theme.dart` — `ThemeData(useMaterial3: true, colorScheme: ..., textTheme: ..., ...)` for light and dark.
- **Color**: `ColorScheme.fromSeed(seedColor: <brand seed>, dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot)`. Use `dynamic_color` (`DynamicColorBuilder`) for Material You wallpaper colors, falling back to the seed scheme. Use surface container roles (`surfaceContainerLow`, `surfaceContainer`, `surfaceContainerHigh`) for layering instead of custom greys.
- **Semantic colors** for income/expense: define a `ThemeExtension<WaltColors>` (income, expense, warning) harmonized to the scheme with `Color.harmonizeWith(colorScheme.primary)`.
- **Typography**: M3 type scale. Use an expressive, variable-weight face (e.g. Google Fonts `Roboto Flex` or `Google Sans Flex` if available) for `display*` and `headline*` roles with heavier weights (w600–w700); keep body/label roles quiet. Big balance amounts use `displayMedium/displaySmall` with tabular figures (`FontFeature.tabularFigures()`).
- **Shape**: define a shape scale — small 8, medium 12, large 20, extra-large 28. Set `cardTheme`, `dialogTheme`, `bottomSheetTheme`, `chipTheme`, `inputDecorationTheme`, `filledButtonTheme`, `segmentedButtonTheme`, `floatingActionButtonTheme` explicitly.
- **Motion**: create `lib/core/theme/motion.dart` with spring-based specs (use `SpringDescription` + `SpringSimulation` or `AnimationController.animateWith`). Expose:
  - `spatialSpring` (slightly bouncy: for position/size/shape)
  - `effectsSpring` (no bounce: for color/opacity)
  Use these for nav indicator, FAB, press states, list item entry. Respect `MediaQuery.disableAnimations`.
- Set `pageTransitionsTheme` to `PredictiveBackPageTransitionsBuilder` (Android predictive back) and enable `android:enableOnBackInvokedCallback="true"` in `AndroidManifest.xml`.
- Edge-to-edge: `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` with transparent system bars; handle insets with `SafeArea`/`MediaQuery.padding`.

## Phase 2 — Floating Bottom Navigation (signature component)

Replace the current bottom bar with a **floating pill navigation bar**.

Spec:
- Detached from screen edges: horizontal margin 16–20, bottom margin `16 + viewPadding.bottom`.
- Container: `surfaceContainer` (or `secondaryContainer` tinted), fully rounded (`StadiumBorder`/radius 32), elevation level 2 with soft shadow, height ~64–72.
- 4–5 destinations: **Home, Activity, Reports, Budget, Settings**.
- Selected item: filled icon inside an animated **pill indicator** (`secondaryContainer`) that **expands to show the label**; unselected items show outlined icon only (or icon + small label if width allows). Animate indicator width/position with `spatialSpring`.
- Haptic feedback on tap (`HapticFeedback.selectionClick`).
- Semantics labels, min touch target 48×48, badge support.
- Build as `lib/core/widgets/floating_nav_bar.dart`, driven by the existing router/`StatefulShellRoute` or `IndexedStack`. Screens must add bottom padding equal to nav height + margin so content is never hidden. Use `Scaffold(extendBody: true)`.
- Hide/shrink on scroll down, reveal on scroll up (optional; use a `NotificationListener<UserScrollNotification>`).
- Provide a `NavigationBar`-based fallback only if the custom widget fails accessibility checks.

Add-transaction FAB:
- Use a **`FloatingActionButton.large` or extended FAB** placed above the floating nav (right aligned), rounded-square shape (radius 28) with `primaryContainer`.
- Tap opens an **expressive FAB menu**: animated expanding list of actions (Add expense, Add income, Scan/Import) with staggered spring entry. Scrim behind it. Close on back/tap outside.

## Phase 3 — Core Components (M3 conventions + light expressive touches)

Apply everywhere, replacing custom/legacy widgets:

| Area | Convention |
|---|---|
| Top bars | `SliverAppBar.large` (collapsing) on Home/Reports/Budget/Settings; `SliverAppBar.medium` elsewhere. Use `scrolledUnderElevation` surface tint. |
| Buttons | `FilledButton` primary, `FilledButton.tonal` secondary, `OutlinedButton`/`TextButton` tertiary. Full-round shape for main CTAs. Press state morphs corner radius (e.g. 20 → 12) via spring. |
| Button groups | Use `SegmentedButton` for Expense/Income, and for period filter (Day / Week / Month / Year). |
| Chips | `FilterChip` for category and date filters, `InputChip` for tags. |
| Lists | `ListTile` inside grouped containers: first/last item large radius, middle items small radius (M3E grouped list look) with 2px gaps. Swipe actions via `Dismissible` with rounded backgrounds. |
| Text fields | Filled or outlined, radius 16, clear labels, supporting text, error states. Amount field: large numeric, custom numeric keypad optional. |
| Dialogs / sheets | `showModalBottomSheet` with `showDragHandle: true`, `useSafeArea: true`, extra-large top radius. Use `DraggableScrollableSheet` for category pickers. `AlertDialog` radius 28. |
| Date/time | `showDatePicker` / `showDateRangePicker` with M3 theme. |
| Menus | `MenuAnchor` / `PopupMenuButton` with rounded surface. |
| Snackbars | Floating behavior, rounded, action label, positioned above the floating nav (`margin` bottom = nav height + spacing). |
| Switches/Checks | `Switch` with icon thumb (`thumbIcon`), `Slider` with M3 style. |
| Search | `SearchAnchor` + `SearchBar` on Activity screen. |
| Progress | `LinearProgressIndicator` / `CircularProgressIndicator` with rounded caps (`strokeCap: StrokeCap.round`). Budget bars: thick (12–16), rounded, animated. Implement a **wavy progress indicator** as a custom painter for loading states only (small accent, not everywhere). |
| Empty states | Icon in a large morphing-shape container (e.g. scalloped/cookie shape via `CustomPainter`/`ClipPath`), short title, one action button. |
| Icons | Material Symbols Rounded (`material_symbols_icons`), filled variant when selected. Category icons inside tonal circles or soft shapes. |

## Phase 4 — Screens

Keep each screen simple. One primary focal element, then grouped lists.

1. **Home**
   - Large collapsing app bar with greeting-free minimal title.
   - Hero balance: big `displayMedium` amount, small label above, income/expense as two tonal pill chips below (not cards).
   - Compact weekly spending chart (fl_chart) on a single `surfaceContainerLow` rounded container.
   - "Recent" grouped list (max 5) + "See all" text button.
2. **Activity**
   - `SearchBar` at top, filter chips row, transactions **grouped by date** with sticky/section headers (`Today`, `Yesterday`, date).
   - Grouped-shape list items, amount right-aligned with income/expense semantic color.
   - Swipe left delete (with undo snackbar), swipe right edit.
3. **Reports**
   - `SegmentedButton` for period. One main chart at a time (bar or donut) with category breakdown list below using progress bars. Rounded chart bars, theme colors only.
   - Export (PDF/CSV) via an overflow menu or tonal button.
4. **Budget**
   - Per-category rows with thick rounded progress and remaining amount. Over-budget uses `error` container color.
   - Add budget via bottom sheet.
5. **Settings**
   - Grouped list sections with section headers (`labelLarge`, primary color). Toggles with icon thumbs. Sections: Security (biometric), Data (export/backup), Appearance (theme mode, dynamic color), AI insights, About.
6. **Add/Edit transaction** (bottom sheet or full-screen)
   - Expense/Income segmented toggle, giant amount input, category chips (scrollable grid), date chip, note field, primary full-width `FilledButton`.

## Phase 5 — Motion & Polish (subtle only)

- **Shared axis / container transform** (`animations` package) for list item → detail, FAB → add screen.
- Staggered fade + slide-in for list items on first load (short, ≤ 300 ms total).
- Number transitions on balance changes (`TweenAnimationBuilder<double>`).
- Press feedback: scale 0.97 with spring; ripple stays.
- Haptics: selection click on nav/toggle, light impact on save, heavy on delete.
- Skeleton/shimmer avoided; use the small wavy/circular indicator.
- No animation longer than 500 ms. Respect reduced-motion setting.

## Phase 6 — Accessibility & Quality

- Contrast AA minimum in light/dark and with dynamic colors.
- Touch targets ≥ 48dp. Add `Semantics` for nav items, FAB actions, charts (summary text).
- Text scaling to 200% must not overflow; use `Flexible`, `FittedBox` for big amounts, and scrollable layouts.
- Large-screen/foldable: constrain content width (max ~600) and center; optionally `NavigationRail` above 840dp width.
- RTL support (Arabic): use `EdgeInsetsDirectional`, `AlignmentDirectional`.
- Add widget tests for the floating nav (selection, semantics) and golden tests for Home in light/dark if a test setup exists.

## Suggested Structure

```
lib/
  core/
    theme/        app_theme.dart, color_schemes.dart, text_theme.dart, shapes.dart, motion.dart, walt_colors.dart
    widgets/      floating_nav_bar.dart, fab_menu.dart, grouped_list.dart, section_header.dart,
                  amount_text.dart, empty_state.dart, wavy_progress.dart, category_icon.dart
  features/       (existing feature folders — only touch UI layers)
```

## Do / Don't

**Do**: standard M3 structure, tonal surfaces, generous spacing (16/24), large rounded shapes, one expressive accent per screen (nav pill, FAB menu, or hero amount).
**Don't**: stack shadows, use pure black/white backgrounds, add heavy gradients, overuse bold/wavy/morphing effects, hardcode colors, or restructure providers/data code.

## Definition of Done

- [ ] Theme centralized; zero hardcoded colors/text styles in screens
- [ ] Dynamic color + light/dark working
- [ ] Floating bottom nav + FAB menu implemented and accessible
- [ ] All 5 screens + add/edit flow updated
- [ ] Predictive back + edge-to-edge enabled
- [ ] `flutter analyze` clean, debug APK builds, existing tests pass
- [ ] Short `CHANGELOG` entry describing UI changes

Work phase by phase and commit after each: `feat(ui): <phase summary>`.
