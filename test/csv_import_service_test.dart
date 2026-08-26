import 'package:finora/data/services/csv_import_service.dart';
import 'package:finora/domain/entities/category.dart';
import 'package:finora/domain/entities/enums.dart';
import 'package:finora/domain/entities/finance_account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const content = '''
微信支付账单明细
交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注
2026-08-24 12:30:45,商户消费,某餐饮店,早餐,支出,15.00,微信支付,支付成功,4200000001,1000000001,
2026-08-22 09:00:00,转账,张三,红包,收入,88.00,零钱,支付成功,4200000002,1000000002,
''';

  final accounts = <FinanceAccount>[
    const FinanceAccount(
      id: 'a1',
      userId: 'u1',
      name: '微信支付',
      type: AccountType.wechat,
      balance: 0,
      iconKey: 'wechat',
      colorValue: 0xFF2563EB,
    ),
  ];
  final categories = <Category>[
    const Category(
      id: 'food',
      type: TransactionType.expense,
      name: '餐饮',
      iconKey: 'restaurant',
      colorValue: 0xFFFB7185,
      isSystem: true,
    ),
    const Category(
      id: 'redpacket',
      type: TransactionType.income,
      name: '红包',
      iconKey: 'redpacket',
      colorValue: 0xFFFB7185,
      isSystem: true,
    ),
  ];

  test('parses WeChat CSV into transactions', () {
    final result = CsvImportService.parse(
      content: content,
      userId: 'u1',
      accounts: accounts,
      categories: categories,
    );
    expect(result.source, ImportSource.wechat);
    expect(result.records, hasLength(2));
    expect(result.records.first.amount, 15);
    expect(result.records.first.note, '早餐');
    expect(result.records.first.categoryId, 'food');
    expect(result.records.first.accountId, 'a1');
    expect(result.records.last.type, TransactionType.income);
  });

  test('Alipay CSV defaults to Alipay account', () {
    const alipayContent = '''
支付宝交易记录明细查询
交易时间,交易分类,交易对方,对方账号,商品说明,收/支,金额,收/付款方式,交易状态,交易订单号,商家订单号,备注,
2026-08-25 12:00:00,商业服务,某公司,/,API服务,支出,9.92,账户余额,交易成功,20260825001,10001,
''';
    final bothAccounts = <FinanceAccount>[
      const FinanceAccount(
        id: 'wechat',
        userId: 'u1',
        name: '微信支付',
        type: AccountType.wechat,
        balance: 0,
        iconKey: 'wechat',
        colorValue: 0xFF2563EB,
      ),
      const FinanceAccount(
        id: 'alipay',
        userId: 'u1',
        name: '支付宝',
        type: AccountType.alipay,
        balance: 0,
        iconKey: 'alipay',
        colorValue: 0xFF7C3AED,
      ),
    ];

    final result = CsvImportService.parse(
      content: alipayContent,
      userId: 'u1',
      accounts: bothAccounts,
      categories: categories,
    );
    expect(result.source, ImportSource.alipay);
    expect(result.records.first.accountId, 'alipay');
  });
}
