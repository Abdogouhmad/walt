import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/providers/settings_provider.dart';

/// The second onboarding page: the privacy promise and the biometric switch.
class SecurityStep extends ConsumerWidget {
  const SecurityStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 40),
          const Text(
            'Privacy First',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Protect your financial data with biometric authentication or a passcode.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 40),
          SwitchListTile(
            title: const Text('Enable Biometrics'),
            value: settings.isFingerprintEnabled,
            onChanged: (v) => notifier.toggleFingerprint(),
          ),
        ],
      ),
    );
  }
}
