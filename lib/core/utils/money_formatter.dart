import 'package:intl/intl.dart';

class MoneyFormat {
  MoneyFormat._();

  static String format(num value, {String symbol = '¥'}) {
    final formatted = NumberFormat('#,##0.00').format(value);
    return value < 0 ? '-$symbol${formatted.substring(1)}' : '$symbol$formatted';
  }

  static String compact(num value, {String symbol = '¥'}) {
    final abs = value.abs();
    if (abs >= 10000) {
      return '${value < 0 ? '-' : ''}$symbol${(abs / 10000).toStringAsFixed(1)}万';
    }
    return format(value, symbol: symbol);
  }

  static String signed(num value, {String symbol = '¥'}) {
    return value >= 0 ? '+${format(value, symbol: symbol)}' : format(value, symbol: symbol);
  }

  static String percent(double value, {int digits = 1}) {
    return '${value.toStringAsFixed(digits)}%';
  }
}
