import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/features/home/widgets/ai_insight.dart';
import 'package:walt/features/home/widgets/recent_activity.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/features/home/widgets/summary_card.dart';
import 'package:walt/features/home/widgets/bottom_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: const Column(
        children: [
          AiInsight(),
          Padding(padding: EdgeInsets.all(16), child: SummaryCard()),
          Expanded(child: RecentActivity()),
        ],
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
