/// A currency Walt can be set to.
class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.name,
    required this.symbol,
  });

  /// ISO code, e.g. `MAD`.
  final String code;

  /// Display name, e.g. `Moroccan Dirham`.
  final String name;

  /// The currency's symbol, e.g. `DH`.
  final String symbol;
}

/// The currencies offered in the picker.
const List<CurrencyOption> supportedCurrencies = [
  CurrencyOption(code: 'USD', name: 'US Dollar', symbol: r'$'),
  CurrencyOption(code: 'EUR', name: 'Euro', symbol: '€'),
  CurrencyOption(code: 'MAD', name: 'Moroccan Dirham', symbol: 'DH'),
  CurrencyOption(code: 'GBP', name: 'British Pound', symbol: '£'),
  CurrencyOption(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
];
