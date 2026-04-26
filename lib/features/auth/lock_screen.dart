import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/providers/auth_provider.dart';
import 'package:walt/shared/bottons.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-trigger authentication on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).authenticate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_person_rounded,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Walt is Locked',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please authenticate to continue',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              if (authState.isAuthenticating)
                const CircularProgressIndicator()
              else ...[
                if (authState.error != null) ...[
                  Text(
                    authState.error!,
                    style: TextStyle(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                AppButton(
                  label: 'Unlock',
                  onPressed: () =>
                      ref.read(authProvider.notifier).authenticate(),
                  type: ButtonType.primary,
                  isFullWidth: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
