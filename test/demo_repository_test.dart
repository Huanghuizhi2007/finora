import 'package:finora/data/repositories/demo/demo_finance_repository.dart';
import 'package:finora/domain/entities/enums.dart';
import 'package:finora/domain/entities/transaction_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('demo finance data is isolated per user', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = DemoFinanceRepository();

    final firstAccounts = await repository.fetchAccounts('demo-a@example.com');
    final secondAccounts = await repository.fetchAccounts('demo-b@example.com');
    expect(firstAccounts, hasLength(4));
    expect(secondAccounts, hasLength(4));

    await repository.saveTransaction(
      TransactionRecord(
        id: 't1',
        userId: 'demo-a@example.com',
        type: TransactionType.expense,
        amount: 15,
        categoryId: 'cat-exp-餐饮',
        accountId: 'acc-wechat',
        happenedAt: DateTime(2026, 8, 25, 12),
      ),
    );

    final firstTransactions =
        await repository.fetchTransactions('demo-a@example.com');
    final secondTransactions =
        await repository.fetchTransactions('demo-b@example.com');

    expect(firstTransactions, hasLength(1));
    expect(secondTransactions, isEmpty);

    final newRepository = DemoFinanceRepository();
    final restored =
        await newRepository.fetchTransactions('demo-a@example.com');
    expect(restored, hasLength(1));
  });

  test('laundry refund offsets previous laundry expense', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = DemoFinanceRepository();

    await repository.saveTransaction(
      TransactionRecord(
        id: 'laundry-exp',
        userId: 'demo-c@example.com',
        type: TransactionType.expense,
        amount: 20,
        categoryId: 'cat-exp-水电',
        accountId: 'acc-alipay',
        happenedAt: DateTime(2026, 8, 25, 10),
        note: '洗衣房消费',
      ),
    );
    await repository.saveTransaction(
      TransactionRecord(
        id: 'laundry-refund',
        userId: 'demo-c@example.com',
        type: TransactionType.income,
        amount: 8,
        categoryId: 'cat-inc-其他',
        accountId: 'acc-alipay',
        happenedAt: DateTime(2026, 8, 26, 10),
        note: '洗衣房退款',
      ),
    );

    final restarted = DemoFinanceRepository();
    final transactions =
        await restarted.fetchTransactions('demo-c@example.com');
    expect(transactions, hasLength(1));
    expect(transactions.first.type, TransactionType.expense);
    expect(transactions.first.amount, 12);
  });
}
