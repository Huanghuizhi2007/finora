import '../../domain/entities/enums.dart';

class PastedBillResult {
  const PastedBillResult({
    required this.amount,
    required this.type,
    required this.happenedAt,
    required this.note,
    required this.merchant,
    required this.source,
  });

  final double amount;
  final TransactionType type;
  final DateTime happenedAt;
  final String note;
  final String merchant;
  final ImportSource source;
}

class PastedBillParser {
  PastedBillParser._();

  static PastedBillResult? parse(String raw) {
    final text = raw.replaceAll('\r\n', '\n').trim();
    if (text.isEmpty) return null;

    final type = _detectType(text);
    final amount = _detectAmount(text);
    final happenedAt = _detectTime(text);
    if (amount == null || happenedAt == null) return null;

    final merchant = _detectField(
      text,
      <String>['收款方', '收款人', '商户名称', '交易对方', '付款给', '商家'],
    );
    final note = _detectField(
      text,
      <String>['商品说明', '商品', '交易分类', '用途'],
    );
    final source = text.contains('支付宝')
        ? ImportSource.alipay
        : text.contains('微信')
            ? ImportSource.wechat
            : ImportSource.csv;

    return PastedBillResult(
      amount: amount,
      type: type,
      happenedAt: happenedAt,
      note: note.isEmpty ? merchant : note,
      merchant: merchant,
      source: source,
    );
  }

  static TransactionType _detectType(String text) {
    if (text.contains('收入') ||
        text.contains('收到') ||
        text.contains('转入') ||
        text.contains('收钱')) {
      return TransactionType.income;
    }
    return TransactionType.expense;
  }

  static double? _detectAmount(String text) {
    final moneyRegex = RegExp(
      r'[¥￥]\s*([0-9]+(?:\.[0-9]{1,2})?)',
    );
    final matches = moneyRegex.allMatches(text).toList();
    if (matches.isNotEmpty) {
      final value = double.tryParse(matches.last.group(1)!);
      if (value != null) return value;
    }
    final yuanRegex = RegExp(
      r'([0-9]+(?:\.[0-9]{1,2})?)\s*元',
    );
    final yuanMatches = yuanRegex.allMatches(text).toList();
    if (yuanMatches.isNotEmpty) {
      return double.tryParse(yuanMatches.last.group(1)!);
    }
    return null;
  }

  static DateTime? _detectTime(String text) {
    final timeRegex = RegExp(
      r'(\d{4})[-/年](\d{1,2})[-/月](\d{1,2})日?\s+(\d{1,2}):(\d{2})',
    );
    final match = timeRegex.firstMatch(text);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
    );
  }

  static String _detectField(String text, List<String> keywords) {
    for (final keyword in keywords) {
      final regex = RegExp(
        '$keyword[:：]?\\s*([^\\n\\r]+)',
      );
      final match = regex.firstMatch(text);
      if (match != null) {
        final value = match.group(1)?.trim() ?? '';
        if (value.isNotEmpty && !value.contains('¥') && !value.contains('￥')) {
          return value;
        }
      }
    }
    return '';
  }
}
