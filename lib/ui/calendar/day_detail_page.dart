import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/money_formatter.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/transaction_record.dart';
import '../../state/finance_controller.dart';
import '../transactions/transaction_edit_page.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/transaction_tile.dart';

class DayDetailPage extends StatelessWidget {
  const DayDetailPage({
    super.key,
    required this.date,
    required this.transactions,
    required this.finance,
  });

  final DateTime date;
  final List<TransactionRecord> transactions;
  final FinanceController finance;

  @override
  Widget build(BuildContext context) {
    var income = 0.0;
    var expense = 0.0;
    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppDateUtils.fullDate(date))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: <Widget>[
          GlassCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _SummaryItem(
                    label: '收入',
                    value: MoneyFormat.format(income),
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryItem(
                    label: '支出',
                    value: MoneyFormat.format(expense),
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '交易明细',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (transactions.isEmpty)
            const EmptyState(
              title: '这一天还没有账单',
              icon: Icons.event_busy_rounded,
            )
          else
            for (final transaction in transactions)
              TransactionTile(
                transaction: transaction,
                categoryName: finance.categoryName(transaction.categoryId),
                categoryIconKey:
                    finance.categoryById(transaction.categoryId)?.iconKey ??
                        'more',
                categoryColor:
                    finance.categoryById(transaction.categoryId)?.colorValue ??
                        0xFF94A3B8,
                accountName:
                    finance.accountById(transaction.accountId)?.name ?? '账户',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          TransactionEditPage(transaction: transaction),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
