import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');
  static final NumberFormat _weightFormat = NumberFormat('#,##0.##', 'vi_VN');

  static String formatVnd(num amount) {
    return '${_currencyFormat.format(amount.round())} đ';
  }

  static String formatVndFull(num amount) {
    return '${_currencyFormat.format(amount.round())} VNĐ';
  }

  static String formatWeight(num weight, {String unit = 'kg'}) {
    return '${_weightFormat.format(weight)} $unit';
  }

  static String formatNumber(num number) {
    return _weightFormat.format(number);
  }

  static double parseDouble(String? text, {double defaultValue = 0.0}) {
    if (text == null || text.trim().isEmpty) return defaultValue;
    final sanitized = text.trim().replaceAll(',', '.').replaceAll(' ', '');
    return double.tryParse(sanitized) ?? defaultValue;
  }
}
