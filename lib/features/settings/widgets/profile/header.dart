import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/text_ui.dart';

// 1. Changed to ConsumerWidget for simplicity
class ProfileApp extends ConsumerWidget {
  const ProfileApp({super.key});

  Future<void> _updatePic(WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await ref.read(settingsProvider.notifier).updateProfilePic(image.path);
    }
  }

  @override
  // 2. Added 'ref' to the build parameters
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Centers vertically in the middle
        children: [
          GestureDetector(
            onTap: () => _updatePic(ref),
            child: Stack(
              children: [
                _pfp(context, ref),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10), // Added 'height' parameter
          _accountName(context, ref),
        ],
      ),
    );
  }

  // 3. Implemented the helper methods
  Widget _pfp(BuildContext context, WidgetRef ref) {
    final profilePic = ref.watch(
      settingsProvider.select((s) => s.profilePicPath),
    );

    return CircleAvatar(
      radius: 42,
      backgroundColor: context.appBarIcon,
      child: CircleAvatar(
        radius: 40,
        backgroundImage: profilePic != null
            ? FileImage(File(profilePic)) as ImageProvider
            : const AssetImage('assets/profile/meme.jpg'),
      ),
    );
  }

  Widget _accountName(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(settingsProvider.select((s) => s.userName));

    return UiText(
      text: userName,
      type: UiTextType.headlineMedium,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
