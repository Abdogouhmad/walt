import 'package:flutter_test/flutter_test.dart';
import 'package:walt/data/services/notification_router.dart';
import 'package:walt/data/services/notification_service.dart';

void main() {
  group('parseNotificationPayload', () {
    test('returns null for missing or empty payloads', () {
      expect(parseNotificationPayload(null), isNull);
      expect(parseNotificationPayload(''), isNull);
    });

    test('maps the update payload to UpdateDestination', () {
      expect(
        parseNotificationPayload(kUpdatePayload),
        isA<UpdateDestination>(),
      );
    });

    test('maps a well-formed budget payload to its budget id', () {
      final destination = parseNotificationPayload('${kBudgetPayloadPrefix}7');
      expect(destination, isA<BudgetAlertDestination>());
      expect((destination! as BudgetAlertDestination).budgetId, 7);
    });

    test('rejects a budget payload with a non-numeric id', () {
      expect(parseNotificationPayload('${kBudgetPayloadPrefix}abc'), isNull);
    });

    test(
      'rejects unknown payloads so a stale notification cannot navigate',
      () {
        expect(parseNotificationPayload('something-else'), isNull);
      },
    );
  });

  group('destinationToLocation', () {
    test('update destination opens About', () {
      expect(
        destinationToLocation(const UpdateDestination()),
        '/settings/about',
      );
    });

    test('budget destination opens Budgets focused on the id', () {
      expect(
        destinationToLocation(const BudgetAlertDestination(3)),
        '/budgets?focus=3',
      );
    });
  });
}
