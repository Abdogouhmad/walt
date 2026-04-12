import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/bottons.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ── DATA DEFINITIONS ──────────────────────────────────────────────────────
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Welcome to Walt",
      description:
          "Your simple, private, and beautiful personal finance tracker",
      icon: Icons.account_balance_wallet_rounded,
      color: Colors.blue.shade700,
    ),
    OnboardingPage(
      title: "Track Every Penny",
      description:
          "Easily record income and expenses with categories and accounts",
      icon: Icons.receipt_long_rounded,
      color: Colors.green.shade700,
    ),
    OnboardingPage(
      title: "Take Control",
      description:
          "Get clear insights with charts, budgets, and monthly reports",
      icon: Icons.analytics_rounded,
      color: Colors.purple.shade700,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    // 1. Wait for Hive to finish loading
    if (!settings.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. Immediate redirect if already completed
    if (settings.isOnboardingCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
      });
      return const Scaffold();
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text("Skip", style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) =>
                    OnboardingPageWidget(page: _pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                children: [
                  // Progress Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: _currentPage == index ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.blue.shade700
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  AppButton(
                    label: _currentPage == _pages.length - 1
                        ? "Get Started"
                        : "Next",
                    onPressed: _nextPage,
                    type: ButtonType.primary,
                    isFullWidth: true,
                    size: ButtonSize.large,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── MODELS & HELPER WIDGETS ────────────────────────────────────────────────

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const OnboardingPageWidget({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 110, color: page.color),
          const SizedBox(height: 60),
          Text(
            page.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: TextStyle(fontSize: 17, height: 1.5, color: secondaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
