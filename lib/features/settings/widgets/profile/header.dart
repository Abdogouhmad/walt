import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/shared/text_ui.dart';

// 1. Changed to ConsumerWidget for simplicity
class ProfileApp extends ConsumerWidget {
  const ProfileApp({super.key});

  @override
  // 2. Added 'ref' to the build parameters
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Centers vertically in the middle
        children: [
          _pfp(context, ref),
          const SizedBox(height: 10), // Added 'height' parameter
          _accountName(context, ref),
        ],
      ),
    );
  }

  // 3. Implemented the helper methods
  Widget _pfp(BuildContext context, WidgetRef ref) {
    return CircleAvatar(
      radius: 42,
      backgroundColor: context.appBarIcon,
      child: const CircleAvatar(
        radius: 40,
        backgroundImage: AssetImage('assets/profile/meme.jpg'),
      ),
    );
  }

  Widget _accountName(BuildContext context, WidgetRef ref) {
    return const UiText(
      text: 'Abderrahman Gouhmad',
      type: UiTextType.headlineMedium,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
