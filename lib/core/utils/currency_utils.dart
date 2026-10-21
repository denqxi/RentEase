/// Helpers for formatting monetary values.
abstract final class CurrencyUtils {
  /// Formats [amount] as a whole-peso string with thousands separators,
  /// e.g. `4500` -> `"₱4,500"`. (Name kept for existing callers; RentEase
  /// prices are in Philippine pesos, not dollars.)
  static String formatDollars(num amount) {
    final negative = amount < 0;
    final digits = amount.abs().round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '${negative ? '-' : ''}₱$buffer';
  }
}
