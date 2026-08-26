import 'dart:io';

import 'package:excel/excel.dart';
import 'package:finora/data/services/excel_import_service.dart';
import 'package:finora/domain/entities/category.dart';
import 'package:finora/domain/entities/enums.dart';
import 'package:finora/domain/entities/finance_account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses WeChat Excel bill', () async {
    final excel = Excel.createExcel();
    final sheet = excel['账单'];
    sheet.appendRow(<CellValue?>[
      TextCellValue('交易时间'),
      TextCellValue('交易类型'),
      TextCellValue('交易对方'),
      TextCellValue('商品'),
      TextCellValue('收/支'),
      TextCellValue('金额(元)'),
      TextCellValue('支付方式'),
      TextCellValue('交易单号'),
    ]);
    sheet.appendRow(<CellValue?>[
      TextCellValue('2026-08-25 12:30:45'),
      TextCellValue('商户消费'),
      TextCellValue('某餐饮店'),
      TextCellValue('早餐'),
      TextCellValue('支出'),
      TextCellValue('15.00'),
      TextCellValue('微信支付'),
      TextCellValue('4200000001'),
    ]);
    final bytes = excel.encode()!;
    final directory = await Directory.systemTemp.createTemp('finora_excel_test');
    final file = File('${directory.path}/wechat.xlsx')
      ..writeAsBytesSync(bytes);

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
    ];

    final result = await ExcelImportService.parse(
      filePath: file.path,
      userId: 'u1',
      accounts: accounts,
      categories: categories,
    );

    expect(result.source, ImportSource.wechat);
    expect(result.records, hasLength(1));
    expect(result.records.first.amount, 15);
    expect(result.records.first.note, '早餐');
  });
}
