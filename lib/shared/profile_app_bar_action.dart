import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walt/data/services/image_store.dart';
import 'package:walt/providers/settings_provider.dart';

/// The profile avatar, present in the app bar of every top-level screen.
///
/// Tapping it *pushes* Settings as a normal route, so it gets a back arrow and
/// predictive back instead of replacing the tab. That is why Settings is not a
/// bottom-nav destination.
class ProfileAppBarAction extends ConsumerWidget {
  const ProfileAppBarAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(settingsProvider.select((s) => s.profilePicPath));
    final initial = ref.watch(settingsProvider.select((s) => s.userName));
    final scheme = Theme.of(context).colorScheme;

    // A cached picker path can go stale; fall back rather than render a hole.
    final ImageProvider? image = ImageStore.exists(path)
        ? FileImage(File(path!)) as ImageProvider
        : null;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        label: 'Open profile and settings',
        child: InkWell(
          onTap: () => context.push('/settings'),
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: scheme.primaryContainer,
              foregroundImage: image,
              child: image != null
                  ? null
                  : Text(
                      _initialFor(initial),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  static String _initialFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.characters.first.toUpperCase();
  }
}
