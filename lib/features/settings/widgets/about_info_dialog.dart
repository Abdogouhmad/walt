import 'package:flutter/material.dart';

import 'package:walt/core/widgets/walt_logo.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/features/settings/widgets/socialmedia.dart';
import 'package:walt_ui/walt_ui.dart';

/// The About information, presented as a frosted dialog.
///
/// About is informational only — there is nothing here to navigate to or edit,
/// so a full screen was a dead end the user had to back out of. Kept separate
/// from [AboutScreen] because that route still has to exist: update
/// notifications deep-link to it, and a notification cannot open a dialog
/// without a screen behind it.
///
/// The slab is a [BlurSurface] — the same frost as the floating nav pill — so
/// the app's chrome reads consistently. Because [BlurSurface] consults the
/// theme itself, the dialog follows "Appearance → Reduce transparency"
/// automatically: turning blur off collapses it to the normal opaque surface.
class AboutInfoDialog extends StatelessWidget {
  const AboutInfoDialog({super.key});

  /// Caps the dialog on tablets/foldables so a few lines of text never stretch
  /// across the whole screen.
  static const double _maxWidth = 360;

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => const AboutInfoDialog(),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dialog(
      // The frost is drawn by the [BlurSurface]: a themed fill *and* elevation
      // here would sit behind it and hide the blur entirely.
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: BlurSurface(
          // Same blur strength as the nav pill so the two frosted surfaces read
          // the same. The tint is left at its default per-brightness fill:
          // unlike the nav, a dialog is mostly text and needs the contrast.
          sigma: BlurSurface.maxSigma,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The app's own mark, not a generic glyph — this dialog is
              // *about* Walt. Decorative: the title already names the app.
              const Center(child: WaltLogo(size: 40, semanticLabel: null)),
              const SizedBox(height: AppSpacing.md),
              Text(
                Appinfo.appname,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Version ${Appinfo.version}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Divider(color: colors.outlineVariant, height: 1),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Made by Abdogouhmad',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
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
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
