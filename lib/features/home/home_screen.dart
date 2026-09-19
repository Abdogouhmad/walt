import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/features/home/widgets/recent_activity.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/features/home/widgets/summary_card.dart';
import 'package:walt/features/home/widgets/bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: const [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: SummaryCard(),
              ),
              RecentActivity(),
            ],
          ),
        ),
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButton: AppButton(
        type: ButtonType.fab,
        icon: Icons.add,
        onPressed: () => showAddTransactionSheet(context),
      ),
    );
  }
}
