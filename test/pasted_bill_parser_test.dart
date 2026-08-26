import 'package:finora/data/services/pasted_bill_parser.dart';
import 'package:finora/domain/entities/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses WeChat pasted bill text', () {
    const text = '''
微信支付
交易单号：4200000000000000001
付款金额：¥86.00
收款方：某餐饮店
交易时间：2026-08-25 12:30:45
''';

    final result = PastedBillParser.parse(text);
    expect(result, isNotNull);
    expect(result!.amount, 86);
    expect(result.type, TransactionType.expense);
    expect(result.merchant, '某餐饮店');
    expect(result.happenedAt, DateTime(2026, 8, 25, 12, 30));
    expect(result.source, ImportSource.wechat);
  });

  test('parses Alipay income text', () {
    const text = '''
支付宝
订单号：2026082422001000000000000001
收入金额：￥200.00
收款方：张三
交易时间：2026-08-24 09:00:00
''';

    final result = PastedBillParser.parse(text);
    expect(result, isNotNull);
    expect(result!.amount, 200);
    expect(result.type, TransactionType.income);
    expect(result.source, ImportSource.alipay);
  });
}
