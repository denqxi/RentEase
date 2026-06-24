/// Helpers for formatting monetary values.
abstract final class CurrencyUtils {
  /// Formats [amount] as a whole-dollar string with thousands separators,
  /// e.g. `1500` → `"$1,500"`.
  static String formatDollars(num amount) {
    final digits = amount.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '\$$buffer';
  }
}
