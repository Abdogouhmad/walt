import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/features/onboarding/widgets/pages.dart';
import 'package:walt/features/onboarding/widgets/dots.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _controller;
  int _page = 0;

  final _pages = const [
    PageData(
      "Welcome to Walt",
      "Your simple, private, and beautiful personal finance tracker",
      Icons.account_balance_wallet_rounded,
      Colors.blue,
    ),
    PageData(
      "Track Every Penny",
      "Easily record income and expenses with categories and accounts",
      Icons.receipt_long_rounded,
      Colors.green,
    ),
    PageData(
      "Take Control",
      "Get clear insights with charts, budgets, and monthly reports",
      Icons.analytics_rounded,
      Colors.purple,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose(); // ✅ important
    super.dispose();
  }

  void _next() {
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
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => PageViewItem(data: _pages[i]),
              ),
            ),

            // Bottom UI
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Dots(current: _page, total: _pages.length),
                  const SizedBox(height: 40),
                  AppButton(
                    label: _page == _pages.length - 1 ? "Get Started" : "Next",
                    onPressed: _next,
                    type: ButtonType.primary,
                    isFullWidth: true,
                    size: ButtonSize.large,
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    onPressed: _finish,
                    type: ButtonType.secondary,
                    label: "Skip",
                    icon: Icons
                        .arrow_forward_rounded, // Now this will show up after "skip"
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
