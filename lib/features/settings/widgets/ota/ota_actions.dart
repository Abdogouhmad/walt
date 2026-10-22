import 'package:flutter/material.dart';
import 'package:walt_ui/walt_ui.dart';

/// Primary action buttons: a dominant "Update now" when a release is pending,
/// or an outlined re-check button.
class OtaActions extends StatelessWidget {
  final bool canUpdate;
  final bool failed;
  final VoidCallback onCheck;
  final VoidCallback onDownload;

  const OtaActions({
    super.key,
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
