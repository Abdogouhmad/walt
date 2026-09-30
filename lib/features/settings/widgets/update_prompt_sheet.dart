import 'package:flutter/material.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/data/models/changelog.dart';
import 'package:walt/features/settings/widgets/markdown_notes.dart';
import 'package:walt/providers/update_provider.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/shared/status_badge.dart';
import 'package:walt/shared/ui_modal.dart';

/// Non-modal "an update exists" surface. The user is never blocked: the sheet
/// always offers "Later" and dismissing it is a normal, expected outcome.
Future<void> showUpdatePromptSheet(
  BuildContext context, {
  required UpdateState state,
  required VoidCallback onDownload,
}) {
  final manifest = state.manifest;
  if (manifest == null) return Future.value();

  final notes = manifest.releaseNotes.trim();
  final summary = firstChangelogLine(notes);
  final published = formatReleaseDate(manifest.publishedAt);
  final theme = Theme.of(context);

  return showWaltModal<void>(
    context,
    heightFactor: 0.72,
    content: Padding(
      padding: waltModalPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.system_update_alt_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Walt ${manifest.latestVersionName} is available',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const StatusBadge(
                label: 'Update',
                variant: StatusBadgeVariant.accent,
                icon: Icons.new_releases_outlined,
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (published.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              published,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text("What's new", style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: MarkdownNotes(notes: notes),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Update now',
            icon: Icons.download_rounded,
            type: ButtonType.textIcon,
            isFullWidth: true,
            size: ButtonSize.large,
            onPressed: onDownload,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
        ],
      ),
    ),
  );
}
