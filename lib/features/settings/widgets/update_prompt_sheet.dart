import 'package:flutter/material.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/providers/update_provider.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/shared/status_badge.dart';
import 'package:walt/shared/text_ui.dart';
import 'package:walt/shared/ui_modal.dart';

/// Renders an available update through the app's single bottom-sheet component
/// (spec §3.5 — the prompt is a sheet, never a dialog; there is no desktop
/// branch). Shown when an auto-check or a manual check finds a new version
/// while the user is not already on the update screen.
Future<void> showUpdatePromptSheet(
  BuildContext context, {
  required UpdateState state,
  required VoidCallback onDownload,
}) {
  final manifest = state.manifest;
  if (manifest == null) return Future.value();

  final notes = manifest.releaseNotes.trim();

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
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: UiText(text:
                  'Update available',
                  type: UiTextType.titleLarge,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const StatusBadge(
                label: 'Version',
                variant: StatusBadgeVariant.accent,
                icon: Icons.new_releases_outlined,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          UiText(text:
            'v${manifest.latestVersionName} is ready to install.',
            type: UiTextType.bodyMedium,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            UiText(text:
              'What\'s new',
              type: UiTextType.titleSmall,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _NotesBody(notes: notes),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: state.isMandatory ? 'Update now (required)' : 'Update now',
            icon: Icons.download_rounded,
            type: ButtonType.textIcon,
            isFullWidth: true,
            size: ButtonSize.large,
            onPressed: onDownload,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!state.isMandatory)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Later'),
            ),
        ],
      ),
    ),
  );
}

class _NotesBody extends StatelessWidget {
  final String notes;

  const _NotesBody({required this.notes});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lines = notes
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: UiText(text:
                    _clean(line),
                    type: UiTextType.bodyMedium,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _clean(String line) {
    final t = line.trimLeft();
    if (t.startsWith('- ') || t.startsWith('• ')) return t.substring(2);
    if (t.startsWith('####')) return t.substring(4).trim();
    if (t.startsWith('###')) return t.substring(3).trim();
    if (t.startsWith('##')) return t.substring(2).trim();
    if (t.startsWith('#')) return t.substring(1).trim();
    return line;
  }
}