import 'package:finora/data/repositories/demo/demo_finance_repository.dart';
import 'package:finora/domain/entities/enums.dart';
import 'package:finora/domain/entities/transaction_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo finance data is isolated per user', () async {
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
  });
}
