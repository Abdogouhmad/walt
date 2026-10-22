/// Walt's shared design system — tokens, theme and reusable components.
///
/// Import this barrel only; never reach into `src/` from the app or a feature.
/// Everything here is app-agnostic: a screen composes these pieces, it never
/// redefines them.
library;

// Components
export 'src/components/amount_label.dart';
export 'src/components/amount_text.dart';
export 'src/components/app_button.dart';
export 'src/components/app_button_fab.dart';
export 'src/components/app_button_filled.dart';
export 'src/components/app_button_quiet.dart';
export 'src/components/app_button_spec.dart';
export 'src/components/app_card.dart';
export 'src/components/app_card_data.dart';
export 'src/components/blur_surface.dart';
export 'src/components/button_type.dart';
export 'src/components/category_avatar.dart';
export 'src/components/empty_state.dart';
export 'src/components/fab_action.dart';
export 'src/components/fab_action_button.dart';
export 'src/components/fab_menu.dart';
export 'src/components/fab_menu_button.dart';
export 'src/components/fab_scrim.dart';
export 'src/components/fab_surface.dart';
export 'src/components/grouped_list.dart';
export 'src/components/input_field.dart';
export 'src/components/period_navigator.dart';
export 'src/components/pill_option.dart';
export 'src/components/pill_switcher.dart';
export 'src/components/scalloped_container.dart';
export 'src/components/section_header.dart';
export 'src/components/sheet_signal.dart';
export 'src/components/staggered_entry.dart';
export 'src/components/stat_pill.dart';
export 'src/components/state_views.dart';
export 'src/components/status_badge.dart';
export 'src/components/surface_shadow.dart';
export 'src/components/thick_progress.dart';
export 'src/components/tonal_card.dart';
export 'src/components/transparency.dart';
export 'src/components/ui_text.dart';
export 'src/components/walt_destination.dart';
export 'src/components/walt_nav_bar.dart';
export 'src/components/walt_nav_icon.dart';
export 'src/components/walt_nav_item.dart';
export 'src/components/walt_sheet.dart';
export 'src/components/wavy_painter.dart';
export 'src/components/wavy_progress.dart';

// Format
export 'src/format/money_format.dart';

// Layout
export 'src/layout/walt_chrome.dart';

// Theme
export 'src/theme/app_button_theme.dart';
export 'src/theme/app_theme.dart';
export 'src/theme/chart_series.dart';
export 'src/theme/chart_series_builder.dart';
export 'src/theme/color_lab.dart';
export 'src/theme/color_math.dart';
export 'src/theme/color_schemes.dart';
export 'src/theme/feedback_theme.dart';
export 'src/theme/input_theme.dart';
export 'src/theme/navigation_theme.dart';
export 'src/theme/semantic_accents.dart';
export 'src/theme/surface_theme.dart';
export 'src/theme/text_emphasis.dart';
export 'src/theme/text_scale.dart';
export 'src/theme/text_theme.dart';
export 'src/theme/theme_settings.dart';
export 'src/theme/walt_chart_colors.dart';
export 'src/theme/walt_colors.dart';
export 'src/theme/walt_palette.dart';

// Tokens
export 'src/tokens/motion.dart';
export 'src/tokens/radius.dart';
export 'src/tokens/spacing.dart';

// Utils
export 'src/utils/bounded_memo.dart';
export 'src/utils/category_icons.dart';
export 'src/utils/context.dart';
export 'src/utils/haptics.dart';
