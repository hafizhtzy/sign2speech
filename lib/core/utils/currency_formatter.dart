/// Centralized Indonesian Rupiah currency formatter utility.
///
/// Follows standard Indonesian format (e.g. `Rp 10.000` or `10.000`).
class AppCurrencyFormatter {
  const AppCurrencyFormatter._();

  /// Formats any [amount] into standard Indonesian Rupiah format.
  ///
  /// Examples:
  /// - `10000` -> `'Rp 10.000'`
  /// - `41000` -> `'Rp 41.000'`
  /// - `4100`  -> `'Rp 4.100'`
  /// - `45100` -> `'Rp 45.100'`
  /// - `0`     -> `'Rp 0'`
  ///
  /// If [withSymbol] is `false`, it omits the `'Rp '` prefix (e.g. `'10.000'`).
  static String format(num amount, {bool withSymbol = true}) {
    final intVal = amount.round();
    final isNegative = intVal < 0;
    final absAmount = intVal.abs();
    final str = absAmount.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }

    final formattedNumber = buffer.toString();
    if (!withSymbol) {
      return isNegative ? '-$formattedNumber' : formattedNumber;
    }
    return isNegative ? '-Rp $formattedNumber' : 'Rp $formattedNumber';
  }
}

/// Convenience top-level function for [AppCurrencyFormatter.format].
String formatRupiah(num amount, {bool withSymbol = true}) =>
    AppCurrencyFormatter.format(amount, withSymbol: withSymbol);
