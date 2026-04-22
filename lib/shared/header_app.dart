import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/providers/ai_provider.dart';
import 'package:walt/shared/text_ui.dart';

class HeaderApp extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  const HeaderApp({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconColor = context.appBarIcon;

    // Logic for the greeting text
    String getGreeting() {
      final hour = DateTime.now().hour;
      if (hour < 12) return 'Good Morning';
      if (hour < 18) return 'Good Afternoon';
      return 'Good Evening';
    }

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => context.go('/settings'),
                borderRadius: BorderRadius.circular(22),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: iconColor,
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage('assets/profile/meme.jpg'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  UiText(
                    text: getGreeting(),
                    type: UiTextType.bodySmall,
                    style: TextStyle(color: context.appBarText.withAlpha(150)),
                  ),
                  UiText(
                    text: "Abdo",
                    type: UiTextType.titleMedium,
                    style: TextStyle(
                      color: context.appBarText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () => ref.read(aiInsightProvider.notifier).toggleVisibility(),
            icon: const Icon(Icons.auto_awesome),
            color: context.appBarIcon,
          ),
        ],
      ),
    );
  }
}
