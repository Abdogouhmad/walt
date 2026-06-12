import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/providers/update_provider.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/shared/m3e_card.dart';
import 'package:walt/shared/text_ui.dart';
import 'package:walt/core/utils/context.dart';

class OtaUpdateScreen extends ConsumerStatefulWidget {
  const OtaUpdateScreen({super.key});

  @override
  ConsumerState<OtaUpdateScreen> createState() => _OtaUpdateScreenState();
}

class _OtaUpdateScreenState extends ConsumerState<OtaUpdateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final updateState = ref.read(updateProvider);
      if (updateState.latestVersion == null) {
        ref.read(updateProvider.notifier).checkForUpdates();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateProvider);
    final notifier = ref.read(updateProvider.notifier);
    // final theme = Theme.of(context);
    // final colorScheme = theme.colorScheme;

    final bool canUpdate = state.isUpdateAvailable && state.downloadUrl != null;
    final String sizeInMB = state.apkSize != null
        ? '${(state.apkSize! / (1024 * 1024)).toStringAsFixed(2)} MB'
        : 'Unknown size';

    return Scaffold(
      appBar: AppBar(
        title: const Text("App Update"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: state.isChecking
            ? _buildCheckingState(context)
            : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(20),
                    vertical: context.h(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      _buildHeaderIllustration(context, state),
                      const SizedBox(height: 32),
                      if (state.errorMessage != null) ...[
                        _buildErrorCard(context, state.errorMessage!),
                        const SizedBox(height: 24),
                      ],
                      _buildInfoCard(context, state, sizeInMB),
                      const SizedBox(height: 20),
                      if (canUpdate || state.changelog != null) ...[
                        _buildChangelogCard(context, state),
                        const SizedBox(height: 28),
                      ],
                      if (state.isUpdating) ...[
                        _buildDownloadingProgress(context, state),
                      ] else ...[
                        _buildActions(context, notifier, canUpdate),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCheckingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: context.w(64),
            height: context.w(64),
            child: CircularProgressIndicator(
              strokeWidth: 5,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.colorAppScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          UiText(
            text: "Checking for updates...",
            type: UiTextType.titleMedium,
            style: TextStyle(
              color: context.colorAppScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          UiText(
            text: "Connecting to GitHub releases",
            type: UiTextType.bodySmall,
            style: TextStyle(
              color: context.colorAppScheme.onSurfaceVariant.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIllustration(BuildContext context, UpdateState state) {
    final colorScheme = context.colorAppScheme;
    final isNewAvailable = state.isUpdateAvailable;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: context.w(110),
              height: context.w(110),
              decoration: BoxDecoration(
                color: isNewAvailable
                    ? colorScheme.primaryContainer.withAlpha(150)
                    : colorScheme.secondaryContainer.withAlpha(150),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: context.w(86),
              height: context.w(86),
              decoration: BoxDecoration(
                color: isNewAvailable
                    ? colorScheme.primaryContainer
                    : colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNewAvailable
                    ? Icons.system_update_alt_rounded
                    : Icons.check_circle_outline_rounded,
                size: context.w(42),
                color: isNewAvailable
                    ? colorScheme.primary
                    : colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(16),
            vertical: context.h(6),
          ),
          decoration: BoxDecoration(
            color: isNewAvailable
                ? colorScheme.primary.withAlpha(20)
                : Colors.green.withAlpha(20),
            borderRadius: BorderRadius.circular(context.r(20)),
            border: Border.all(
              color: isNewAvailable
                  ? colorScheme.primary.withAlpha(80)
                  : Colors.green.withAlpha(80),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isNewAvailable ? colorScheme.primary : Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              UiText(
                text: isNewAvailable
                    ? "New Update Available"
                    : "You are up to date",
                type: UiTextType.labelLarge,
                style: TextStyle(
                  color: isNewAvailable ? colorScheme.primary : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return M3Ecard(
      variant: M3ECardVariant.outlined,
      data: AppCardData(
        // reduce card radius
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: context.colorAppScheme.outline,
            width: 1,
          ),
        ),
        colorCard: context.colorAppScheme.errorContainer.withAlpha(40),
        leading: Icon(
          Icons.error_outline_rounded,
          color: context.colorAppScheme.error,
        ),
        title: "Update Error",
        body: error,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, UpdateState state, String size) {
    return M3Ecard(
      variant: M3ECardVariant.outlined,
      data: AppCardData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: context.colorAppScheme.outline,
            width: 1,
          ),
        ),
        title: "Version Details",
        child: Column(
          children: [
            _buildInfoRow(
              context,
              "Current Version",
              "v${Appinfo.version}",
              icon: Icons.smartphone_rounded,
            ),
            const Divider(height: 24, thickness: 0.5),
            _buildInfoRow(
              context,
              "Latest Version",
              state.latestVersion != null ? "v${state.latestVersion}" : "Unknown",
              icon: Icons.new_releases_outlined,
              valueColor: state.isUpdateAvailable
                  ? context.colorAppScheme.primary
                  : null,
            ),
            if (state.isUpdateAvailable && state.apkSize != null) ...[
              const Divider(height: 24, thickness: 0.5),
              _buildInfoRow(
                context,
                "Download Size",
                size,
                icon: Icons.insert_drive_file_outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChangelogCard(BuildContext context, UpdateState state) {
    return M3Ecard(
      variant: M3ECardVariant.outlined,
      data: AppCardData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: context.colorAppScheme.outline,
            width: 1,
          ),
        ),
        title: "What's New",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.changelog != null && state.changelog!.trim().isNotEmpty) ...[
              Container(
                constraints: BoxConstraints(maxHeight: context.h(180)),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: UiText(
                    text: state.changelog!,
                    type: UiTextType.bodyMedium,
                    style: TextStyle(
                      color: context.colorAppScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ] else ...[
              UiText(
                text: "No release notes available for this release.",
                type: UiTextType.bodyMedium,
                style: TextStyle(
                  color: context.colorAppScheme.onSurfaceVariant.withAlpha(150),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadingProgress(BuildContext context, UpdateState state) {
    return M3Ecard(
      variant: M3ECardVariant.filled,
      data: AppCardData(
        colorCard: context.colorAppScheme.primaryContainer.withAlpha(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                UiText(
                  text: "Downloading update...",
                  type: UiTextType.titleSmall,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                UiText(
                  text: "${state.downloadProgress.toStringAsFixed(0)}%",
                  type: UiTextType.titleSmall,
                  style: TextStyle(
                    color: context.colorAppScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: state.downloadProgress / 100,
              backgroundColor: context.colorAppScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.colorAppScheme.primary,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            UiText(
              text: "Please do not close the app. The installer will launch automatically once completed.",
              type: UiTextType.bodySmall,
              style: TextStyle(
                color: context.colorAppScheme.onSurfaceVariant.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    UpdateNotifier notifier,
    bool canUpdate,
  ) {
    if (canUpdate) {
      return AppButton(
        label: "Update Now",
        icon: Icons.download_rounded,
        type: ButtonType.textIcon,
        isFullWidth: true,
        size: ButtonSize.large,
        onPressed: () => notifier.executeUpdate(),
      );
    } else {
      return AppButton(
        label: "Check for Updates",
        icon: Icons.refresh_rounded,
        type: ButtonType.textIcon,
        isFullWidth: false,
        foregroundColor: context.colorAppScheme.primary,
        backgroundColor: context.colorAppScheme.surfaceBright,
        size: ButtonSize.large,
        onPressed: () => notifier.checkForUpdates(),
      );
    }
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    required IconData icon,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: context.w(20),
          color: context.colorAppScheme.onSurfaceVariant.withAlpha(180),
        ),
        const SizedBox(width: 12),
        UiText(
          text: label,
          type: UiTextType.bodyMedium,
          style: TextStyle(
            color: context.colorAppScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        UiText(
          text: value,
          type: UiTextType.bodyMedium,
          style: TextStyle(
            color: valueColor ?? context.colorAppScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
