import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/providers/update_provider.dart';
import 'package:walt/shared/status_badge.dart';
import 'package:walt/shared/text_ui.dart';

/// Full-screen, non-dismissible takeover shown when a **mandatory** update is
/// available (spec §3.2). Blocks usage of the entire app (no back button, no
/// navigation) until the update is installed — the only way forward is to
/// download. Ported from Brewline's `UpdateRequiredScreen`.
class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final updater = ref.watch(updateProvider);
    final notes = updater.manifest?.releaseNotes ?? '';

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      updater.status == UpdateStatus.error
                          ? Icons.error_outline_rounded
                          : Icons.system_security_update_warning_rounded,
                      size: 64,
                      color: updater.status == UpdateStatus.error
                          ? colorScheme.error
                          : colorScheme.tertiary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    UiText(text:
                      'Update required',
                      type: UiTextType.headlineMedium,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    UiText(text:
                      'Version ${updater.manifest?.latestVersionName ?? ''} is a '
                      'mandatory update. Walt must be updated to keep running.',
                      type: UiTextType.bodyMedium,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    if (notes.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _WhatsNew(notes: notes),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    _statusBody(context, updater),
                    const SizedBox(height: AppSpacing.xl),
                    _downloadButton(context, ref, updater),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBody(BuildContext context, UpdateState updater) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (updater.status) {
      case UpdateStatus.checking:
        return const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 3),
        );

      case UpdateStatus.downloading:
        final progress = ((updater.progress ?? 0) * 100).toStringAsFixed(0);
        return Column(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: updater.progress ?? 0,
                    strokeWidth: 8,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: colorScheme.primary,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: UiText(text:
                      '$progress%',
                      type: UiTextType.titleSmall,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            UiText(text:
              'Downloading update… your data is verified before install.',
              type: UiTextType.bodySmall,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case UpdateStatus.readyToInstall:
        return Icon(
          Icons.check_circle_outline_rounded,
          color: colorScheme.primary,
          size: 64,
        );

      case UpdateStatus.error:
        final message = switch (updater.error) {
          UpdateErrorCode.integrity =>
            'The update failed its checksum check — please retry.',
          UpdateErrorCode.install =>
            'Android blocked the install. Enable "install unknown apps" for Walt.'
                '${updater.errorDetail != null ? '\n${updater.errorDetail}' : ''}',
          _ => 'Download failed. Check your connection and retry.',
        };
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          child: UiText(text:
            message,
            type: UiTextType.bodyMedium,
            style: TextStyle(color: colorScheme.onErrorContainer),
            textAlign: TextAlign.center,
          ),
        );

      case UpdateStatus.available:
      case UpdateStatus.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _downloadButton(
    BuildContext context,
    WidgetRef ref,
    UpdateState updater,
  ) {
    final busy =
        updater.status == UpdateStatus.downloading ||
        updater.status == UpdateStatus.checking ||
        updater.status == UpdateStatus.readyToInstall;
    final failed = updater.status == UpdateStatus.error;

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
      ),
      onPressed: busy
          ? null
          : () => ref.read(updateProvider.notifier).downloadAndInstall(),
      icon: failed ? const Icon(Icons.refresh_rounded) : const Icon(Icons.download_rounded),
      label: UiText(text:
        updater.status == UpdateStatus.readyToInstall
            ? 'Install now'
            : failed
            ? 'Retry'
            : 'Download & install',
        type: UiTextType.titleSmall,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _WhatsNew extends StatelessWidget {
  final String notes;

  const _WhatsNew({required this.notes});

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
        const StatusBadge(
          label: 'What\'s new',
          variant: StatusBadgeVariant.accent,
          icon: Icons.new_releases_outlined,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs + 2),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: UiText(text:
                    _stripBullet(line),
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

  static String _stripBullet(String line) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('- ') || trimmed.startsWith('• ')) {
      return trimmed.substring(2);
    }
    if (trimmed.startsWith('## ') || trimmed.startsWith('# ')) {
      return trimmed.substring(3);
    }
    if (trimmed.startsWith('### ')) return trimmed.substring(4);
    return line;
  }
}