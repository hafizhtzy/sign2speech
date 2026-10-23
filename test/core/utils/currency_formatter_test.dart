import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/core/utils/currency_formatter.dart';

void main() {
  group('AppCurrencyFormatter', () {
    test('formats thousands and tens of thousands correctly', () {
      expect(formatRupiah(10000), equals('Rp 10.000'));
      expect(formatRupiah(41000), equals('Rp 41.000'));
      expect(formatRupiah(4100), equals('Rp 4.100'));
      expect(formatRupiah(45100), equals('Rp 45.100'));
      expect(formatRupiah(33000), equals('Rp 33.000'));
      expect(formatRupiah(17000), equals('Rp 17.000'));
    });

    test('formats zero and small numbers without separator', () {
      expect(formatRupiah(0), equals('Rp 0'));
      expect(formatRupiah(50), equals('Rp 50'));
      expect(formatRupiah(500), equals('Rp 500'));
    });

    test('formats millions and larger numbers with multiple separators', () {
      expect(formatRupiah(1000000), equals('Rp 1.000.000'));
      expect(formatRupiah(12500000), equals('Rp 12.500.000'));
    });

    test('formats without symbol when withSymbol is false', () {
      expect(formatRupiah(10000, withSymbol: false), equals('10.000'));
      expect(formatRupiah(45100, withSymbol: false), equals('45.100'));
      expect(formatRupiah(0, withSymbol: false), equals('0'));
    });

    test('handles negative amounts correctly', () {
      expect(formatRupiah(-10000), equals('-Rp 10.000'));
      expect(formatRupiah(-10000, withSymbol: false), equals('-10.000'));
    });

    test('handles decimal/num rounding gracefully', () {
      expect(formatRupiah(10000.4), equals('Rp 10.000'));
      expect(formatRupiah(10000.6), equals('Rp 10.001'));
    });
  });
}
