import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:walt/providers/settings_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// The third onboarding page: avatar, name and the default currency.
class SignupStep extends ConsumerStatefulWidget {
  const SignupStep({super.key});

  @override
  ConsumerState<SignupStep> createState() => _SignupStepState();
}

class _SignupStepState extends ConsumerState<SignupStep> {
  final _nameController = TextEditingController();
  String _currency = 'MAD';
  String? _imagePath;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imagePath = image.path);
      unawaited(
        ref
            .read(settingsProvider.notifier)
            .setUserProfile(name: _nameController.text, profilePic: _imagePath),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                backgroundImage: _imagePath != null
                    ? FileImage(File(_imagePath!))
                    : null,
                child: _imagePath == null
                    ? Icon(
                        Icons.add_a_photo_rounded,
                        size: 40,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Setup Your Profile',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            InputUI(
              controller: _nameController,
              labelText: 'Full Name',
              hintText: 'John Doe',
              icon: Icons.person_outline_rounded,
              onchange: (v) => ref
                  .read(settingsProvider.notifier)
                  .setUserProfile(name: v, profilePic: _imagePath),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: const InputDecoration(
                labelText: 'Default Currency',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              items: [
                'MAD',
                'USD',
                'EUR',
                'GBP',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _currency = v);
                  ref.read(settingsProvider.notifier).setCurrency(v);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
