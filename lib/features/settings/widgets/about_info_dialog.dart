import 'package:flutter/material.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/features/settings/widgets/socialmedia.dart';

/// The About information, presented as a dialog.
///
/// About is informational only — there is nothing here to navigate to or edit,
/// so a full screen was a dead end the user had to back out of. Kept separate
/// from [AboutScreen] because that route still has to exist: update
/// notifications deep-link to it, and a notification cannot open a dialog
/// without a screen behind it.
class AboutInfoDialog extends StatelessWidget {
  const AboutInfoDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => const AboutInfoDialog(),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      icon: Image.asset(
        'assets/icon/walt_icon.png',
        width: 64,
        height: 64,
        filterQuality: FilterQuality.medium,
      ),
      title: Text(
        Appinfo.appname,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Version ${Appinfo.version}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(color: colors.outlineVariant, height: AppSpacing.lg),
          const SizedBox(height: AppSpacing.sm),

          Text(
            'Made by Abdogouhmad',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SocialBubble(
                icon: Icons.code,
                url: 'https://github.com/Abdogouhmad',
              ),
              SizedBox(width: AppSpacing.sm),
              SocialBubble(
                icon: Icons.message,
                url: 'mailto:gouhmad@hotmail.com',
              ),
              SizedBox(width: AppSpacing.sm),
              SocialBubble(
                icon: Icons.web_asset_rounded,
                url: 'https://agouhmad.vercel.app/',
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
