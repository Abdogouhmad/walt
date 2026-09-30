import 'package:flutter_test/flutter_test.dart';
import 'package:walt/core/utils/money.dart';

void main() {
  group('MoneyFormat.digits', () {
    test('groups thousands', () {
      // The plain Dart formatter renders 1234567.5 as "1234567.50", which is
      // exactly why this indirection exists.
      expect(MoneyFormat.digits(1234567.5), '1,234,567.50');
      expect(MoneyFormat.digits(1000), '1,000.00');
      expect(MoneyFormat.digits(999.994, fractionDigits: 2), '999.99');
    });

    test('honours the requested decimal count', () {
      expect(MoneyFormat.digits(1234.6, fractionDigits: 0), '1,235');
      expect(MoneyFormat.digits(1234.4, fractionDigits: 0), '1,234');
      expect(MoneyFormat.digits(12, fractionDigits: 0), '12');
    });

    test('zero formats as zero, not an empty string', () {
      expect(MoneyFormat.digits(0), '0.00');
      expect(MoneyFormat.digits(0, fractionDigits: 0), '0');
    });

    test('is always finite', () {
      expect(MoneyFormat.digits(double.infinity).contains('∞'), isFalse);
    });
  });

  group('MoneyFormat.withCode', () {
    test('appends a trailing currency code', () {
      expect(MoneyFormat.withCode(150, currency: 'MAD'), '150.00 MAD');
    });

    test('omits the code when none is configured', () {
      expect(MoneyFormat.withCode(150, currency: ''), '150.00');
      expect(MoneyFormat.withCode(150, currency: '  '), '150.00');
    });

    test('puts the sign in front and the absolute value in the body', () {
      expect(
        MoneyFormat.withCode(-42, currency: 'MAD', signed: true),
        '-42.00 MAD',
      );
      expect(
        MoneyFormat.withCode(42, currency: 'MAD', signed: true),
        '+42.00 MAD',
      );
      // Unsigned balances never grow a '+'.
      expect(MoneyFormat.withCode(-42, currency: 'MAD'), '42.00 MAD');
    });

    test('trims a padded code', () {
      expect(MoneyFormat.withCode(1, currency: ' MAD '), '1.00 MAD');
    });
  });
}
