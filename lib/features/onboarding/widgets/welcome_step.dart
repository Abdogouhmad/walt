import 'package:flutter/material.dart';

import 'package:walt/core/widgets/walt_logo.dart';
import 'package:walt_ui/walt_ui.dart';

/// The first onboarding page: the Walt wordmark and the one-line promise.
class WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WaltLogo(size: 100, semanticLabel: null),
              SizedBox(width: 12),
              Text(
                'Walt',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          UiText(
            text:
                'Your simple, secured, private and beautiful personal finance tracker',
            type: UiTextType.bodyMedium,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: scheme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: AppButton(
                onPressed: onNext,
                size: ButtonSize.large,
                type: ButtonType.iconOnly,
                icon: Icons.navigate_next_rounded,
                iconColor: scheme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
