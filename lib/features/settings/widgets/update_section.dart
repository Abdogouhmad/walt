import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/data/services/update_service.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/features/settings/widgets/ota_update_screen.dart';
import 'package:walt/features/settings/widgets/update_prompt_sheet.dart';
import 'package:walt/providers/update_provider.dart';
import 'package:walt/shared/list_ui.dart';
import 'package:walt/shared/status_badge.dart';

/// Settings entry point for the whole OTA surface (spec §3.5): the tile shows
/// the current version, the outcome of the last check and, when an update is
/// available, a compact [StatusBadge]. Tapping it opens the full
/// [OtaUpdateScreen]. Attaches a listener that surfaces discovery of a new
/// release through the app's bottom-sheet prompt while the user is on settings.
class UpdateSection extends ConsumerStatefulWidget {
  const UpdateSection({super.key});

  @override
  ConsumerState<UpdateSection> createState() => _UpdateSectionState();
}

class _UpdateSectionState extends ConsumerState<UpdateSection> {
  String? _promptedVersion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _watchForUpdate());
  }

  void _watchForUpdate() {
    // Kick off a check only if this device has never checked before, so the
    // settings tile has something truthful to render straight away.
    final current = ref.read(updateProvider);
    final notifier = ref.read(updateProvider.notifier);
    if (current.checkResult == null && current.status == UpdateStatus.idle) {
      notifier.checkForUpdates();
    }
  }

  Future<void> _onTap() async {
    // An explicit tap these days is a deliberate visit: skip the sheet and
    // land on the full screen so the changelog/progress UI is visible.
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OtaUpdateScreen()),
    );
  }

  void _maybePrompt(UpdateState state) {
    if (!state.hasUpdate) return;
    if (_promptedVersion == state.manifest?.latestVersionName) return;

    _promptedVersion = state.manifest?.latestVersionName;
    if (!mounted) return;

    showUpdatePromptSheet(
      context,
      state: state,
      onDownload: () {
        Navigator.of(context, rootNavigator: true).pop();
        ref.read(updateProvider.notifier).downloadAndInstall();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UpdateState>(updateProvider, (_, next) {
      if (next.status == UpdateStatus.available ||
          next.status == UpdateStatus.error) {
        _maybePrompt(next);
      }
    });

    final state = ref.watch(updateProvider);
    final cs = Theme.of(context).colorScheme;
    return AppListGroup(
      useCard: false,
      children: [
        AppListTile(
          style: ListStyle.outlined,
          title: 'Update',
          subtitle: _subtitle(state),
          leading: AppListAvatar(
            icon: Icons.system_update_alt_rounded,
            size: AppSpacing.x2l,
            backgroundColor: cs.primaryContainer,
            iconColor: cs.onPrimaryContainer,
          ),
          trailing: _trailing(state),
          onTap: _onTap,
        ),
      ],
    );
  }

  String _subtitle(UpdateState state) {
    final current = Appinfo.version;
    final latest = state.manifest?.latestVersionName;
    if (state.hasUpdate && latest != null) {
      return 'v$current  ·  v$latest available';
    }
    return state.status == UpdateStatus.checking
        ? 'Checking…'
        : state.checkResult == UpdateCheckResult.checkFailed
        ? 'v$current  ·  check failed'
        : 'v$current  ·  you are up to date';
  }

  Widget? _trailing(UpdateState state) {
    if (state.status == UpdateStatus.checking) return null;
    final Widget badge;
    if (state.checkResult == UpdateCheckResult.updateMandatory ||
        state.checkResult == UpdateCheckResult.updateAvailable) {
      badge = const StatusBadge(
        label: 'Update',
        variant: StatusBadgeVariant.accent,
        icon: Icons.system_update_alt_rounded,
      );
    } else if (state.checkResult == UpdateCheckResult.checkFailed) {
      badge = const StatusBadge(
        label: 'Offline',
        variant: StatusBadgeVariant.error,
        icon: Icons.cloud_off_outlined,
      );
    } else if (state.checkResult == UpdateCheckResult.upToDate) {
      badge = const StatusBadge(
        label: 'Up to date',
        variant: StatusBadgeVariant.success,
        icon: Icons.check_rounded,
      );
    } else {
      badge = const StatusBadge(label: '—', variant: StatusBadgeVariant.info);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: badge,
    );
  }
}