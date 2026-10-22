import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/providers/update_provider.dart';

import 'ota_info_card.dart';

/// Current vs latest version card.
class OtaVersionCard extends ConsumerWidget {
  final UpdateState state;

  const OtaVersionCard({super.key, required this.state});

  static String formatChecked(DateTime? last) {
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

  static String resultLabel(UpdateCheckResult? result) {
    return switch (result) {
      UpdateCheckResult.upToDate => 'Up to date',
      UpdateCheckResult.updateAvailable => 'Update available',
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

    return OtaInfoCard(
      title: 'Version details',
      icon: Icons.smartphone_rounded,
      children: [
        OtaInfoRow(
          icon: Icons.layers_rounded,
          label: 'Current version',
          value: 'v$current',
        ),
        otaDivider(context),
        OtaInfoRow(
          icon: Icons.new_releases_outlined,
          label: 'Latest version',
          value: latest == null ? 'Unknown' : 'v$latest',
          highlight: state.hasUpdate,
        ),
        otaDivider(context),
        const OtaInfoRow(
          icon: Icons.insert_drive_file_outlined,
          label: 'Install type',
          value: 'Universal APK',
        ),
        otaDivider(context),
        OtaInfoRow(
          icon: Icons.schedule_rounded,
          label: 'Last checked',
          value: formatChecked(lastChecked),
        ),
        otaDivider(context),
        OtaInfoRow(
          icon: Icons.rule_rounded,
          label: 'Last result',
          value: resultLabel(lastResult),
          highlight: lastResult == UpdateCheckResult.checkFailed,
        ),
      ],
    );
  }
}
