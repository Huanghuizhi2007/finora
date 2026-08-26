import 'package:finora/data/services/csv_import_service.dart';
import 'package:finora/domain/entities/category.dart';
import 'package:finora/domain/entities/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
      id: 'shopping',
      type: TransactionType.expense,
      name: '购物',
      iconKey: 'cart',
      colorValue: 0xFFF59E0B,
      isSystem: true,
    ),
    const Category(
      id: 'study',
      type: TransactionType.expense,
      name: '学习',
      iconKey: 'school',
      colorValue: 0xFF60A5FA,
      isSystem: true,
    ),
    const Category(
      id: 'living',
      type: TransactionType.income,
      name: '生活费',
      iconKey: 'wallet',
      colorValue: 0xFF2563EB,
      isSystem: true,
    ),
  ];

  test('maps AI recharge to study', () {
    final category = CsvImportService.matchCategory(
      TransactionType.expense,
      'DeepSeek-API服务(191******80)',
      categories,
    );
    expect(category.name, '学习');
  });

  test('maps vending machine and campus card to food', () {
    final vending = CsvImportService.matchCategory(
      TransactionType.expense,
      '盛马售货柜_怡宝纯净水555ml',
      categories,
    );
    final card = CsvImportService.matchCategory(
      TransactionType.expense,
      '一卡通充值',
      categories,
    );
    expect(vending.name, '餐饮');
    expect(card.name, '餐饮');
  });

  test('maps product names to shopping', () {
    final category = CsvImportService.matchCategory(
      TransactionType.expense,
      '美的小夜灯可充电大学生宿舍床头学习阅读护眼台灯',
      categories,
    );
    expect(category.name, '购物');
  });

  test('maps living allowance to income category', () {
    final category = CsvImportService.matchCategory(
      TransactionType.income,
      '生活费转账',
      categories,
    );
    expect(category.name, '生活费');
  });
}
