import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/data/services/update_service.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/providers/update_provider.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/shared/status_badge.dart';
import 'package:walt/shared/state_views.dart';
import 'package:walt/shared/text_ui.dart';

/// Full-page OTA update center, reachable from the settings "Update" entry.
///
/// Ported from Brewline's `UpdateScreen`: a status header, a current-vs-latest
/// version card, the "What's new" changelog (authored once in `CHANGELOG.md`
/// and surfaced verbatim here) and the download/install action with live
/// progress. Updates are always checked for automatically — there is no
/// opt-out toggle (spec §3.5).
class OtaUpdateScreen extends ConsumerStatefulWidget {
  const OtaUpdateScreen({super.key});

  @override
  ConsumerState<OtaUpdateScreen> createState() => _OtaUpdateScreenState();
}

class _OtaUpdateScreenState extends ConsumerState<OtaUpdateScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-check on entry only if no result has been computed yet, so opening
    // the screen never forces a redundant network round-trip right after an
    // auto-check already surfaced an update.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final snapshot = ref.read(updateProvider);
      if (snapshot.status == UpdateStatus.idle && snapshot.checkResult == null) {
        ref.read(updateProvider.notifier).checkForUpdates();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateProvider);
    final notifier = ref.read(updateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: UiText(text:'Software update', type: UiTextType.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusHeader(state: state),
              const SizedBox(height: AppSpacing.xl),
              if (state.status == UpdateStatus.checking) ...[
                const _CheckingCard(),
              ] else ...[
                if (state.status == UpdateStatus.error ||
                    state.checkResult == UpdateCheckResult.checkFailed) ...[
                  InlineErrorView(
                    message: _errorMessage(context, state),
                    onRetry: () => notifier.checkForUpdates(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _VersionCard(state: state),
                if (state.hasUpdate &&
                    (state.manifest?.releaseNotes ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ChangelogCard(notes: state.manifest?.releaseNotes ?? ''),
                ],
                const SizedBox(height: AppSpacing.xl),
                switch (state.status) {
                  UpdateStatus.downloading => _DownloadCard(
                    progress: state.progress ?? 0,
                  ),
                  UpdateStatus.readyToInstall => _ReadyCard(
                    onChangePressed: () => notifier.downloadAndInstall(),
                  ),
                  _ => _Actions(
                    canUpdate:
                        state.hasUpdate &&
                        state.status != UpdateStatus.downloading &&
                        state.status != UpdateStatus.readyToInstall,
                    failed: state.status == UpdateStatus.error,
                    onCheck: () => notifier.checkForUpdates(),
                    onDownload: () => notifier.downloadAndInstall(),
                  ),
                },
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _errorMessage(BuildContext context, UpdateState state) {
    final detail = state.errorDetail;
    return switch (state.error) {
      UpdateErrorCode.noBuild => 'This release has no APK to install.',
      UpdateErrorCode.downloadFailed =>
        'Could not download the update.${detail != null ? ' $detail' : ''}',
      UpdateErrorCode.integrity =>
        'Checksum mismatch — the update was refused for your safety.',
      UpdateErrorCode.install =>
        'Android would not install the update.${detail != null ? ' $detail' : ''}',
      null => switch (state.checkResult) {
        UpdateCheckResult.checkFailed => 'Could not reach the update server.',
        _ => 'Something went wrong.',
      },
    };
  }
}

/// Hero banner: concentric circles with a status icon + pill.
class _StatusHeader extends StatelessWidget {
  final UpdateState state;

  const _StatusHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final failed =
        state.status == UpdateStatus.error ||
        state.checkResult == UpdateCheckResult.checkFailed;
    final update =
        state.hasUpdate && state.status != UpdateStatus.error && !failed;
    final checking = state.status == UpdateStatus.checking;

    final accent = failed
        ? colorScheme.error
        : checking
        ? colorScheme.secondaryContainer
        : update
        ? colorScheme.primaryContainer
        : colorScheme.secondaryContainer;
    final accentFg = failed
        ? colorScheme.onError
        : checking
        ? colorScheme.onSecondaryContainer
        : update
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSecondaryContainer;

    final pill = checking
        ? const StatusBadge(
            label: 'Checking…',
            variant: StatusBadgeVariant.accent,
            icon: Icons.sync_rounded,
          )
        : failed
        ? const StatusBadge(
            label: 'Check failed',
            variant: StatusBadgeVariant.error,
            icon: Icons.error_outline_rounded,
          )
        : update
        ? const StatusBadge(
            label: 'New update available',
            variant: StatusBadgeVariant.accent,
            icon: Icons.system_update_alt_rounded,
          )
        : const StatusBadge(
            label: 'You are up to date',
            variant: StatusBadgeVariant.success,
            icon: Icons.check_circle_outline_rounded,
          );

    return Column(
      children: [
        SizedBox(
          width: 124,
          height: 124,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  child: Icon(
                    checking
                        ? Icons.sync_rounded
                        : failed
                        ? Icons.error_outline_rounded
                        : update
                        ? Icons.system_update_alt_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 42,
                    color: accentFg,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        pill,
      ],
    );
  }
}

/// Loading card shown while the initial check is in flight.
class _CheckingCard extends StatelessWidget {
  const _CheckingCard();

  @override
  Widget build(BuildContext context) {
    return const LoadingStateView(label: 'Looking for newer versions…');
  }
}

/// Current vs latest version card.
class _VersionCard extends ConsumerWidget {
  final UpdateState state;

  const _VersionCard({required this.state});

  static String _formatChecked(DateTime? last) {
    if (last == null) return 'Never';
    final now = DateTime.now();
    final diff = now.difference(last);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    final local = last.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  static String _resultLabel(UpdateCheckResult? result) {
    return switch (result) {
      UpdateCheckResult.upToDate => 'Up to date',
      UpdateCheckResult.updateAvailable => 'Update available',
      UpdateCheckResult.updateMandatory => 'Mandatory update',
      UpdateCheckResult.checkFailed => 'Check failed',
      null => 'Never checked',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = Appinfo.version;
    final latest = state.manifest?.latestVersionName;
    final lastChecked = ref.watch(lastUpdateCheckProvider);
    final lastResult = ref.watch(lastUpdateCheckResultProvider);

    return _Card(
      title: 'Version details',
      icon: Icons.smartphone_rounded,
      children: [
        _InfoRow(
          icon: Icons.layers_rounded,
          label: 'Current version',
          value: 'v$current',
        ),
        _divider(context),
        _InfoRow(
          icon: Icons.new_releases_outlined,
          label: 'Latest version',
          value: latest == null ? 'Unknown' : 'v$latest',
          highlight: state.hasUpdate,
        ),
        _divider(context),
        const _InfoRow(
          icon: Icons.insert_drive_file_outlined,
          label: 'Install type',
          value: 'Universal APK',
        ),
        _divider(context),
        _InfoRow(
          icon: Icons.schedule_rounded,
          label: 'Last checked',
          value: _formatChecked(lastChecked),
        ),
        _divider(context),
        _InfoRow(
          icon: Icons.rule_rounded,
          label: 'Last result',
          value: _resultLabel(
            ref.watch(lastUpdateCheckResultProvider),
          ),
          highlight:
              lastResult == UpdateCheckResult.checkFailed ||
              lastResult == UpdateCheckResult.updateMandatory,
        ),
      ],
    );
  }
}

Widget _divider(BuildContext context) => Divider(
  height: 1,
  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
);

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 24, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          UiText(text:
            label,
            type: UiTextType.bodyMedium,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const Spacer(),
          UiText(text:
            value,
            type: UiTextType.bodyMedium,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: highlight ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// "What's new" card rendering the CHANGELOG section shipped in the manifest
/// (spec §2 — single source, used verbatim).
class _ChangelogCard extends StatelessWidget {
  final String notes;

  const _ChangelogCard({required this.notes});

  static final RegExp _headingRe = RegExp(r'^#{1,3}\s+(.*)$');
  static final RegExp _bulletRe = RegExp(r'^[-•*]\s+(.*)$');
  static final RegExp _boldRe = RegExp(r'\*\*(.+?)\*\*');

  @override
  Widget build(BuildContext context) {
    final lines = notes
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return _Card(
      title: 'What\'s new',
      icon: Icons.new_releases_outlined,
      children: [
        if (lines.isEmpty)
          UiText(text:
            'No release notes available for this release.',
            type: UiTextType.bodyMedium,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          for (var i = 0; i < lines.length; i++) _row(context, lines[i], i),
      ],
    );
  }

  Widget _row(BuildContext context, String line, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    final heading = _headingRe.firstMatch(line);
    if (heading != null) {
      return Padding(
        padding: EdgeInsets.only(
          top: index == 0 ? 0 : AppSpacing.md,
          bottom: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: UiText(text:
                heading.group(1)!,
                type: UiTextType.titleSmall,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }

    final bullet = _bulletRe.firstMatch(line);
    if (bullet != null) {
      return Padding(
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
                  color: colorScheme.primary.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _RichText(
                text: bullet.group(1)!,
                color: colorScheme.onSurfaceVariant,
                boldColor: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: _RichText(
        text: line,
        color: colorScheme.onSurfaceVariant,
        boldColor: colorScheme.onSurface,
      ),
    );
  }
}

class _RichText extends StatelessWidget {
  final String text;
  final Color color;
  final Color boldColor;

  const _RichText({
    required this.text,
    required this.color,
    required this.boldColor,
  });

  @override
  Widget build(BuildContext context) {
    final base = (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: color);

    final spans = <TextSpan>[];
    int last = 0;
    for (final m in _ChangelogCard._boldRe.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(
        TextSpan(
          text: m.group(1),
          style: TextStyle(color: boldColor, fontWeight: FontWeight.w700),
        ),
      );
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    if (spans.isEmpty) spans.add(TextSpan(text: text));

    return Text.rich(TextSpan(style: base, children: spans));
  }
}

/// Download progress with a determinate linear bar + percentage.
class _DownloadCard extends StatelessWidget {
  final double progress;

  const _DownloadCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = ((progress * 100).clamp(0, 100)).toStringAsFixed(0);

    return _Card(
      title: 'Downloading update',
      icon: Icons.download_rounded,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            UiText(text:
              'Downloading…',
              type: UiTextType.bodyMedium,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            UiText(text:
              '$percent%',
              type: UiTextType.titleSmall,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 10,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

/// Ready-to-install success state with the handoff CTA.
class _ReadyCard extends StatelessWidget {
  final VoidCallback onChangePressed;

  const _ReadyCard({required this.onChangePressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 64),
        const SizedBox(height: AppSpacing.md),
        UiText(text:
          'The update is verified and ready to install.',
          type: UiTextType.bodyMedium,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Install now',
          icon: Icons.download_done_rounded,
          type: ButtonType.textIcon,
          isFullWidth: true,
          size: ButtonSize.large,
          onPressed: onChangePressed,
        ),
      ],
    );
  }
}

/// Primary action buttons: a dominant "Update now" when a release is pending,
/// or an outlined re-check button.
class _Actions extends StatelessWidget {
  final bool canUpdate;
  final bool failed;
  final VoidCallback onCheck;
  final VoidCallback onDownload;

  const _Actions({
    required this.canUpdate,
    required this.failed,
    required this.onCheck,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    if (canUpdate) {
      return AppButton(
        label: 'Update now',
        icon: Icons.download_rounded,
        type: ButtonType.textIcon,
        isFullWidth: true,
        size: ButtonSize.large,
        onPressed: onDownload,
      );
    }

    return Center(
      child: AppButton(
        label: failed ? 'Try again' : 'Check for updates',
        type: ButtonType.secondary,
        foregroundColor: Theme.of(context).colorScheme.primary,
        size: ButtonSize.medium,
        onPressed: onCheck,
      ),
    );
  }
}

/// Shared outlined card shell for the info/changelog sections.
class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Card({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.surface),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: Icon(icon, size: 24, color: colorScheme.onSecondaryContainer),
              ),
              const SizedBox(width: AppSpacing.md),
              UiText(text:
                title,
                type: UiTextType.titleMedium,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}