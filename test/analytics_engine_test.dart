import 'package:finora/core/utils/analytics_engine.dart';
import 'package:finora/domain/entities/budget.dart';
import 'package:finora/domain/entities/category.dart';
import 'package:finora/domain/entities/enums.dart';
import 'package:finora/domain/entities/transaction_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final month = DateTime(2026, 8);
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
      id: 'salary',
      type: TransactionType.income,
      name: '工资',
      iconKey: 'salary',
      colorValue: 0xFF34D399,
      isSystem: true,
    ),
  ];

  final transactions = <TransactionRecord>[
    TransactionRecord(
      id: '1',
      userId: 'u1',
      type: TransactionType.expense,
      amount: 100,
      categoryId: 'food',
      accountId: 'a1',
      happenedAt: DateTime(2026, 8, 10, 12),
    ),
    TransactionRecord(
      id: '2',
      userId: 'u1',
      type: TransactionType.expense,
      amount: 50,
      categoryId: 'food',
      accountId: 'a1',
      happenedAt: DateTime(2026, 8, 20, 19),
    ),
    TransactionRecord(
      id: '3',
      userId: 'u1',
      type: TransactionType.income,
      amount: 8000,
      categoryId: 'salary',
      accountId: 'a2',
      happenedAt: DateTime(2026, 8, 1, 9),
    ),
    TransactionRecord(
      id: '4',
      userId: 'u1',
      type: TransactionType.expense,
      amount: 30,
      categoryId: 'food',
      accountId: 'a1',
      happenedAt: DateTime(2026, 7, 15, 12),
    ),
  ];

  test('monthly summary computes income expense and savings', () {
    final summary = AnalyticsEngine.monthly(transactions, month);
    expect(summary.income, 8000);
    expect(summary.expense, 150);
    expect(summary.savings, 7850);
    expect(summary.count, 3);
  });

  test('category breakdown uses category names and colors', () {
    final slices = AnalyticsEngine.categoryBreakdown(
      transactions,
      month,
      TransactionType.expense,
      categories,
    );
    expect(slices, hasLength(1));
    expect(slices.first.label, '餐饮');
    expect(slices.first.amount, 150);
    expect(slices.first.percent, closeTo(100, 0.01));
  });

  test('daily series returns one point per day', () {
    final series = AnalyticsEngine.dailySeries(transactions, month);
    expect(series, hasLength(31));
    expect(series[9].expense, 100);
    expect(series[19].expense, 50);
  });

  test('budget progress flags over budget', () {
    final budget = Budget(
      id: 'b1',
      userId: 'u1',
      scope: 'category',
      amount: 100,
      period: '2026-08',
      categoryId: 'food',
    );
    final progress = AnalyticsEngine.budgetProgress(transactions, budget);
    expect(progress.spent, 150);
    expect(progress.isOver, isTrue);
    expect(progress.percent, closeTo(150, 0.01));
  });
}
