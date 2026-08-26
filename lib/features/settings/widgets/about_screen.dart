import 'package:flutter/material.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/features/settings/widgets/socialmedia.dart';
import 'package:walt/shared/text_ui.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          UiText(
            text: 'About',
            type: UiTextType.headlineLarge,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          UiText(
            text: Appinfo.appname,
            type: UiTextType.bodyMedium,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          /// App info card
          _Card(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28, // outer bubble size
                  backgroundColor: colors.primaryContainer,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/wallet.png',
                      width: 35,
                      height: 35,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UiText(
                        text: Appinfo.appname,
                        type: UiTextType.titleLarge,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      UiText(
                        text: 'v${Appinfo.version}',
                        type: UiTextType.labelMedium,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// Developer card
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28, // outer bubble size
                      backgroundColor: colors.primaryContainer,
                      backgroundImage: const AssetImage('assets/cat.jpeg'),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UiText(
                          text: 'Abdogouhmad',
                          type: UiTextType.titleLarge,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        UiText(
                          text: 'Developer',
                          type: UiTextType.bodySmall,
                          style: TextStyle(fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: const [
                            SocialBubble(
                              icon: Icons.code,
                              url: "https://github.com/Abdogouhmad",
                            ),
                            SizedBox(width: 8),
                            SocialBubble(
                              icon: Icons.message,
                              url: "mailto:gouhmad@hotmail.com",
                            ),
                            SizedBox(width: 8),
                            SocialBubble(
                              icon: Icons.web_asset_rounded,
                              url: "https://agouhmad.vercel.app/",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.colorAppScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}
