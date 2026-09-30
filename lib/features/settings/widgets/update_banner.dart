import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/providers/update_provider.dart';

/// A quiet, dismissible card telling the user a newer build exists.
///
/// Deliberately *not* a dialog, bottom sheet or takeover screen: an update
/// suggestion must never take the app away from the user mid-task. It is
/// inline, it explains itself, and it can be dismissed for this session. If
/// the user dismisses it, the Settings → Update tile still works, and the next
/// app start will offer it again.
class UpdateBanner extends ConsumerStatefulWidget {
  const UpdateBanner({super.key, this.onOpen, this.onInstall});

  /// Called when the user taps the banner or "Update now".
  final VoidCallback? onOpen;

  /// Optional inline "Update now" action. When null only the open action shows.
  final VoidCallback? onInstall;

  @override
  ConsumerState<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends ConsumerState<UpdateBanner> {
  /// Set once the user dismisses. Deliberately not persisted: a dismissal is a
  /// statement about *this* moment, and pinning it forever would hide real
  /// security-relevant updates.
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateProvider);
    if (_dismissed || !state.hasUpdate) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final latest = state.manifest?.latestVersionName;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.system_update_rounded,
                size: 20,
                color: scheme.onSecondaryContainer,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latest == null
                          ? 'Update available'
                          : 'Version $latest is available',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      "You're on v${Appinfo.version}. "
                      'Updates are always optional — the app keeps working '
                      'either way.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        if (widget.onOpen != null)
                          TextButton(
                            onPressed: widget.onOpen,
                            style: TextButton.styleFrom(
                              foregroundColor: scheme.onSecondaryContainer,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('See what’s new'),
                          ),
                        if (widget.onInstall != null)
                          TextButton(
                            onPressed: widget.onInstall,
                            style: TextButton.styleFrom(
                              foregroundColor: scheme.onSecondaryContainer,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Update now'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Dismiss',
                onPressed: () => setState(() => _dismissed = true),
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
