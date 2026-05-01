import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/features/onboarding/widgets/pages.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _controller;
  late final List<Widget> _pages;

  int _page = 0;

  @override
  void initState() {
    super.initState();

    _controller = PageController();

    /// ✅ IMPORTANT: NO const here
    _pages = [
      WelcomeStep(onNext: _next),
      const SecurityStep(),
      const SignupStep(),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    print("NEXT CALLED -> page: $_page");

    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final isLoaded = ref.watch(settingsProvider.select((s) => s.isLoaded));

    if (!isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            /// --------------------
            /// PAGES
            /// --------------------
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) {
                  print("PAGE CHANGED -> $i");
                  setState(() => _page = i);
                },
                itemBuilder: (_, i) => _pages[i],
              ),
            ),

            /// --------------------
            /// BOTTOM BUTTONS
            /// --------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  /// ❌ FIRST PAGE → NO BUTTONS HERE
                  if (_page != 0) ...[
                    AppButton(
                      label: _page == _pages.length - 1
                          ? "Get Started"
                          : "Next",
                      onPressed: _next,
                      type: ButtonType.primary,
                      isFullWidth: true,
                      size: ButtonSize.large,
                    ),

                    const SizedBox(height: 10),

                    if (_page < _pages.length - 1)
                      AppButton(
                        onPressed: () {
                          _controller.animateToPage(
                            _pages.length - 1,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        type: ButtonType.secondary,
                        label: "Skip",
                        icon: Icons.arrow_forward_rounded,
                        isFullWidth: true,
                        size: ButtonSize.large,
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
