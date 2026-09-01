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
      id: 'utility',
      type: TransactionType.expense,
      name: '水电',
      iconKey: 'bolt',
      colorValue: 0xFFFBBF24,
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

  test('maps network and laundry to utility', () {
    final network = CsvImportService.matchCategory(
      TransactionType.expense,
      '网费充值',
      categories,
    );
    final laundry = CsvImportService.matchCategory(
      TransactionType.expense,
      '洗衣房消费',
      categories,
    );
    expect(network.name, '水电');
    expect(laundry.name, '水电');
  });

  test('maps vending machines to food and merchant orders to shopping', () {
    final vending = CsvImportService.matchCategory(
      TransactionType.expense,
      '无人售货柜_饮料 商户单号',
      categories,
    );
    final smart = CsvImportService.matchCategory(
      TransactionType.expense,
      '智能货柜消费 商户单号',
      categories,
    );
    final merchant = CsvImportService.matchCategory(
      TransactionType.expense,
      '某商品 商户单号',
      categories,
    );
    expect(vending.name, '餐饮');
    expect(smart.name, '餐饮');
    expect(merchant.name, '购物');
  });
}
