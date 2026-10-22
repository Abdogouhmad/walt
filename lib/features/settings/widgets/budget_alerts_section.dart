import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/services/notification_preferences.dart';
import 'package:walt/features/settings/widgets/settings_leading.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// The notifications section: the budget-alert switch.
class BudgetAlertsSection extends ConsumerWidget {
  const BudgetAlertsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Notifications'),
        GroupedList(
          children: [
            GroupedListTile(
              leading: const SettingsLeading(
                icon: Icons.account_balance_wallet_rounded,
              ),
              title: const Text('Budget alerts'),
              subtitle: const Text('Notify when you reach 80% or pass a limit'),
              trailing: Switch(
                value: settings.budgetAlertsEnabled,
                onChanged: (value) async {
                  // Ask in context: the OS prompt is far more likely to be
                  // granted when it follows a deliberate tap than when it
                  // appears unprompted at startup.
                  if (value) await requestNotificationPermission();
                  await notifier.setBudgetAlertsEnabled(value);
                  await evaluateBudgetAlertsNow(ref);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
