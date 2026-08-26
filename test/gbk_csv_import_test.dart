import 'dart:convert';

import 'package:fast_gbk/fast_gbk.dart';
import 'package:finora/data/services/csv_import_service.dart';
import 'package:finora/domain/entities/category.dart';
import 'package:finora/domain/entities/enums.dart';
import 'package:finora/domain/entities/finance_account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes GBK Alipay CSV and parses records', () {
    const content = '''
支付宝交易记录明细查询
交易时间,交易分类,交易对方,对方账号,商品说明,收/支,金额,收/付款方式,交易状态,交易订单号,商家订单号,备注,
2026-08-25 12:00:00,商业服务,某公司,/,API服务,支出,9.92,账户余额,交易成功,20260825001,10001,
''';
    final bytes = gbk.encode(content);
    expect(() => utf8.decode(bytes), throwsA(isA<FormatException>()));
    final decoded = gbk.decode(bytes);

    final accounts = <FinanceAccount>[
      const FinanceAccount(
        id: 'a1',
        userId: 'u1',
        name: '支付宝',
        type: AccountType.alipay,
        balance: 0,
        iconKey: 'alipay',
        colorValue: 0xFF2563EB,
      ),
    ];
    final categories = <Category>[
      const Category(
        id: 'other',
        type: TransactionType.expense,
        name: '其他',
        iconKey: 'more',
        colorValue: 0xFF94A3B8,
        isSystem: true,
      ),
    ];

    final result = CsvImportService.parse(
      content: decoded,
      userId: 'u1',
      accounts: accounts,
      categories: categories,
    );
    expect(result.source, ImportSource.alipay);
    expect(result.records, hasLength(1));
    expect(result.records.first.amount, 9.92);
  });
}
