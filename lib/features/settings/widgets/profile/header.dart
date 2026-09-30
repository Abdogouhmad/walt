import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/data/services/image_store.dart';
import 'package:walt/providers/settings_provider.dart';

/// Avatar + name block at the top of Settings. Tapping the avatar picks a new
/// profile picture, which is copied into the app's documents directory and
/// never leaves the device.
class ProfileApp extends ConsumerWidget {
  const ProfileApp({super.key});

  Future<void> _updatePic(WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final stored = await ImageStore.importImage(image.path);
    if (stored == null) return;
    await ref.read(settingsProvider.notifier).updateProfilePic(stored);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final profilePic = ref.watch(
      settingsProvider.select((s) => s.profilePicPath),
    );
    final userName = ref.watch(settingsProvider.select((s) => s.userName));

    final ImageProvider? image = ImageStore.exists(profilePic)
        ? FileImage(File(profilePic!)) as ImageProvider
        : null;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: 'Change profile picture',
            child: InkWell(
              onTap: () => _updatePic(ref),
              customBorder: const CircleBorder(),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: scheme.primaryContainer,
                    foregroundImage: image,
                    child: image != null
                        ? null
                        : Text(
                            userName.trim().isEmpty
                                ? ''
                                : userName
                                      .trim()
                                      .characters
                                      .first
                                      .toUpperCase(),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 2),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            userName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
