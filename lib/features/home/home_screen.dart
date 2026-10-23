import 'package:flutter/material.dart';

import 'package:walt/features/home/widgets/home_summary_card.dart';
import 'package:walt/features/home/widgets/pinned_budgets_section.dart';
import 'package:walt/features/home/widgets/recent_activity.dart';
import 'package:walt/shared/profile_app_bar_action.dart';
import 'package:walt_ui/walt_ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      // The shell already sets `extendBody` so content scrolls under the
      // docked nav; repeating it here keeps Home correct in isolation.
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
                    const HomeSummaryCard(),
                    const SizedBox(height: AppSpacing.lg),
                    const PinnedBudgetsSection(),
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
