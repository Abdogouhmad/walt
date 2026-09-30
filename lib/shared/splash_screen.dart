import 'package:flutter/material.dart';

/// The first frame, while settings and the database settle.
///
/// A washed primary rather than a flat surface: it is the one screen with no
/// content to look at, and a near-solid background hides the fact that the app
/// is still starting rather than showing that it is.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.primary.withValues(alpha: 0.1),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
