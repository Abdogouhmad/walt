import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialBubble extends StatelessWidget {
  final dynamic icon;
  final String url;

  const SocialBubble({super.key, required this.icon, required this.url});

  Future<void> _openLink() async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not open $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Widget resolvedIcon = icon is IconData
        ? Icon(icon, size: 18, color: colors.onPrimaryContainer)
        : FaIcon(icon, size: 18, color: colors.onPrimaryContainer);

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _openLink,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: resolvedIcon,
        ),
      ),
    );
  }
}
