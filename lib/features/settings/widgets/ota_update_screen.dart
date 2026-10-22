import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/providers/update_provider.dart';
import 'package:walt_ui/walt_ui.dart';

import 'ota/ota_actions.dart';
import 'ota/ota_changelog_card.dart';
import 'ota/ota_error_message.dart';
import 'ota/ota_progress_cards.dart';
import 'ota/ota_status_header.dart';
import 'ota/ota_version_card.dart';

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
      if (snapshot.status == UpdateStatus.idle &&
          snapshot.checkResult == null) {
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
        title: const UiText(
          text: 'Software update',
          type: UiTextType.titleLarge,
        ),
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
              OtaStatusHeader(state: state),
              const SizedBox(height: AppSpacing.xl),
              if (state.status == UpdateStatus.checking) ...[
                const LoadingStateView(label: 'Looking for newer versions…'),
              ] else ...[
                if (state.status == UpdateStatus.error ||
                    state.checkResult == UpdateCheckResult.checkFailed) ...[
                  InlineErrorView(
                    message: otaErrorMessage(state),
                    onRetry: () => notifier.checkForUpdates(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                OtaVersionCard(state: state),
                if (state.hasUpdate &&
                    (state.manifest?.releaseNotes ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  OtaChangelogCard(notes: state.manifest?.releaseNotes ?? ''),
                ],
                const SizedBox(height: AppSpacing.xl),
                switch (state.status) {
                  UpdateStatus.downloading => OtaDownloadCard(
                    progress: state.progress ?? 0,
                  ),
                  UpdateStatus.readyToInstall => OtaReadyCard(
                    onChangePressed: () => notifier.downloadAndInstall(),
                  ),
                  _ => OtaActions(
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
}
