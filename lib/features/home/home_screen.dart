import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added
import 'package:go_router/go_router.dart';
import 'package:walt/features/home/widgets/recent_activity.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/shared/card_ui.dart';
import 'package:walt/features/home/widgets/notificationpopup.dart';
import 'package:walt/features/home/widgets/bottom_sheet.dart';
import 'package:walt/core/utils/context.dart';

class HomeScreen extends ConsumerWidget {
  // Changed to ConsumerWidget
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorApp = context.colorAppScheme;

    const demoNotifications = [
      {"title": "Payment received", "time": "2 min ago"},
      {"title": "New expense added", "time": "10 min ago"},
      {"title": "Budget exceeded", "time": "1h ago"},
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () =>
                    context.go('/settings'), 
                borderRadius: BorderRadius.circular(
                  22,
                ), // Keeps ripple circular
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: colorApp.primary,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: colorApp.primaryContainer,
                    backgroundImage: const AssetImage(
                      'assets/profile/meme.jpg',
                    ),
                  ),
                ),
              ),
              NotificationDropdown(notifications: demoNotifications),
            ],
          ),
        ),
      ),
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
