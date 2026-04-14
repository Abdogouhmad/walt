import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added
import 'package:walt/features/home/widgets/recent_activity.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/shared/card_ui.dart';
import 'package:walt/features/home/widgets/bottom_sheet.dart';

class HomeScreen extends ConsumerWidget {
  // Changed to ConsumerWidget
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {


    return Scaffold(
      body: const Column(
        children: [
          Padding(padding: EdgeInsets.all(16), child: SummaryCard()),
          // We no longer pass transactions here; the widget watches the provider
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
