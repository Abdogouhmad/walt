import 'package:flutter/material.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/theme/text_theme.dart';
import 'package:walt/core/widgets/walt_chrome.dart';
import 'package:walt/features/home/widgets/balance_hero.dart';
import 'package:walt/features/home/widgets/recent_activity.dart';
import 'package:walt/features/home/widgets/weekly_spending_chart.dart';
import 'package:walt/shared/profile_app_bar_action.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      // The shell already sets `extendBody` so content scrolls under the
      // floating nav; repeating it here keeps Home correct in isolation.
      extendBody: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            // Type decisions live in the theme, not the screen.
            title: Text('WALT', style: AppTextTheme.wordmark(theme.textTheme)),
            actions: const [ProfileAppBarAction()],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: WaltChrome.constrain(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BalanceHero(),
                    const SizedBox(height: AppSpacing.lg),
                    const WeeklySpendingChart(),
                    const SizedBox(height: AppSpacing.sm),
                    const RecentActivity(),
                    SizedBox(
                      height:
                          WaltChrome.scrollBottomPadding(context) -
                          AppSpacing.lg,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
