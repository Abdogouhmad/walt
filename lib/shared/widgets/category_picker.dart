import 'package:flutter/material.dart';

import 'package:walt/data/models/walt_category.dart';
import 'package:walt/shared/widgets/category_artwork.dart';
import 'package:walt_ui/walt_ui.dart';

/// How a [CategoryPicker] treats taps.
enum CategorySelectionMode {
  /// Tapping a tile replaces the selected category.
  single,

  /// Tapping a tile toggles it; the selection can hold many categories.
  multiple,
}

/// The one category picker: image tiles, a check badge, a coloured selection
/// border and an optional "new category" tile.
///
/// Used by Add Transaction and by budget create/edit, so a category looks and
/// behaves the same in both places.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.categories,
    required this.selectedIds,
    required this.onToggle,
    this.mode = CategorySelectionMode.single,
    this.onCreate,
    this.onLongPress,
    this.emptyMessage = 'No categories yet',
  });

  final List<WaltCategory> categories;
  final Set<int> selectedIds;
  final ValueChanged<WaltCategory> onToggle;
  final CategorySelectionMode mode;
  final VoidCallback? onCreate;

  /// Long-press opens the edit/delete actions for [onLongPress].
  final ValueChanged<WaltCategory>? onLongPress;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty && onCreate == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.sm;
        final columns = constraints.maxWidth >= 420 ? 5 : 4;
        final tileWidth =
            ((constraints.maxWidth - spacing * (columns - 1)) / columns).clamp(
              58.0,
              92.0,
            );

        return Wrap(
          spacing: spacing,
          runSpacing: AppSpacing.md,
          children: [
            for (final category in categories)
              SizedBox(
                width: tileWidth,
                child: CategoryTile(
                  category: category,
                  selected: selectedIds.contains(category.id),
                  onTap: () => onToggle(category),
                  onLongPress: onLongPress == null
                      ? null
                      : () => onLongPress!(category),
                ),
              ),
            if (onCreate != null)
              SizedBox(
                width: tileWidth,
                child: _NewCategoryTile(onTap: onCreate!),
              ),
          ],
        );
      },
    );
  }
}

/// One image tile. Exposed so category management and previews can reuse the
/// exact same silhouette.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.trailing,
  });

  final WaltCategory category;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = categoryAccentColor(context, category);
    final scheme = theme.colorScheme;
    const artworkSize = 52.0;

    return Semantics(
      button: true,
      selected: selected,
      label: '${category.name}${selected ? ', selected' : ''}',
      onLongPressHint: onLongPress == null ? null : 'Edit or delete category',
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: AppMotion.short,
                    curve: AppMotion.standard,
                    width: artworkSize,
                    height: artworkSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      border: Border.all(
                        color: selected
                            ? accent
                            : scheme.outline.withValues(alpha: 0.16),
                        width: selected ? 2 : 1,
                      ),
                      color: selected
                          ? accent.withValues(alpha: 0.10)
                          : scheme.surface,
                    ),
                    alignment: Alignment.center,
                    child: CategoryArtwork(
                      category: category,
                      size: artworkSize - 8,
                      radius: AppRadius.sm,
                      filled: false,
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.surface, width: 2),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  if (trailing != null)
                    Positioned(top: -4, left: -4, child: trailing!),
                ],
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewCategoryTile extends StatelessWidget {
  const _NewCategoryTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const artworkSize = 52.0;

    return Semantics(
      button: true,
      label: 'Create a category',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: artworkSize,
                height: artworkSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  color: scheme.surfaceContainerHighest,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: scheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              Text(
                'New',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact "this is what you picked" row, used above the add-transaction
/// form so the selected category is visible without scrolling back to the
/// grid.
class SelectedCategoryPreview extends StatelessWidget {
  const SelectedCategoryPreview({super.key, required this.category});

  final WaltCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          CategoryArtwork(category: category, size: 40, radius: AppRadius.sm),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selected category',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: scheme.primary, size: 20),
        ],
      ),
    );
  }
}
