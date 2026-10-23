import 'package:flutter/material.dart';

import 'package:walt/data/models/walt_category.dart';
import 'package:walt/shared/widgets/category_artwork.dart';
import 'package:walt_ui/walt_ui.dart';

/// The sheet's title block: who the transaction was for, and its category.
class TransactionDetailHeader extends StatelessWidget {
  const TransactionDetailHeader({
    super.key,
    required this.merchant,
    required this.category,
  });

  /// The trimmed merchant name, or `null` when there is none.
  final String? merchant;

  /// The transaction's category, when it could be resolved.
  final WaltCategory? category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final resolved =
        category ??
        const WaltCategory(
          id: 0,
          name: 'Uncategorised',
          icon: 'category',
          // No accent: the artwork falls back to the theme palette.
          color: '',
          type: 'expense',
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CategoryArtwork(category: resolved, size: 48),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                merchant == null || merchant!.isEmpty
                    ? 'Unknown Merchant'
                    : merchant!,
                style: theme.textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                category?.name ?? 'Uncategorised',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
