import 'package:flutter/material.dart';
import 'package:walt/providers/update_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// Hero banner: concentric circles with a status icon + pill.
class OtaStatusHeader extends StatelessWidget {
  final UpdateState state;

  const OtaStatusHeader({super.key, required this.state});

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
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
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
