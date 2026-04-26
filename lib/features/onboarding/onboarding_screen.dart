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
  late final PageController _controller;
  int _page = 0;

  final _pages = const [
    _PageData(
      "Welcome to Walt",
      "Your simple, private, and beautiful personal finance tracker",
      Icons.account_balance_wallet_rounded,
      Colors.blue,
    ),
    _PageData(
      "Track Every Penny",
      "Easily record income and expenses with categories and accounts",
      Icons.receipt_long_rounded,
      Colors.green,
    ),
    _PageData(
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
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: TextButton(onPressed: _finish, child: const Text("Skip")),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _PageViewItem(data: _pages[i]),
              ),
            ),

            // Bottom UI
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  _Dots(current: _page, total: _pages.length),
                  const SizedBox(height: 40),
                  AppButton(
                    label: _page == _pages.length - 1 ? "Get Started" : "Next",
                    onPressed: _next,
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

// ─────────────────────────────────────────────────────────────

class _PageData {
  final String title, desc;
  final IconData icon;
  final Color color;

  const _PageData(this.title, this.desc, this.icon, this.color);
}

// ─────────────────────────────────────────────────────────────

class _PageViewItem extends StatelessWidget {
  final _PageData data;
  const _PageViewItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, size: 110, color: data.color),
          const SizedBox(height: 50),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            data.desc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.5, color: secondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _Dots extends StatelessWidget {
  final int current, total;

  const _Dots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: current == i ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: current == i ? Colors.blue : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
