import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/analytics_engine.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/money_formatter.dart';
import '../../state/finance_controller.dart';
import '../../state/session_controller.dart';
import '../ai/ai_assistant_page.dart';
import '../import/import_page.dart';
import '../transactions/transaction_edit_page.dart';
import '../transactions/transaction_list_page.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/section_header.dart';
import '../widgets/transaction_tile.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();
    final session = context.watch<SessionController>();
    final now = DateTime.now();
    final user = session.user;
    final summary = AnalyticsEngine.monthly(finance.transactions, now);
    final previous = AnalyticsEngine.monthly(
      finance.transactions,
      DateTime(now.year, now.month - 1, 1),
    );
    final change = AnalyticsEngine.changePercent(summary, previous);

    return RefreshIndicator(
      onRefresh: finance.refresh,
      color: AppColors.primaryBlue,
      backgroundColor: AppColors.card,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _Header(user?.nickname ?? '用户'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: _BalanceCard(
                totalBalance: finance.totalBalance,
                change: change,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: _QuickStats(summary: summary),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: _QuickActions(),
            ),
          ),
          if (finance.isLoading && finance.transactions.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: LoadingView(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeader(
                      title: '最近交易',
                      trailing: '查看全部',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const TransactionListPage(),
                          ),
                        );
                      },
                    ),
                    if (finance.transactions.isEmpty)
                      const EmptyState(
                        title: '还没有账单',
                        subtitle: '点击右下角按钮记下第一笔',
                      )
                    else
                      _RecentTransactions(finance: finance),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.nickname);

  final String nickname;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.bluePurpleGradient,
            ),
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.primaryPurple.withOpacity(0.35),
                blurRadius: 16,
              ),
            ],
          ),
          child: Center(
            child: Text(
              nickname.isEmpty ? 'F' : nickname.substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${AppDateUtils.greeting(now)}，$nickname',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${AppDateUtils.fullDate(now)} · ${AppDateUtils.weekdayLabel(now.weekday)}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          tooltip: '通知',
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.totalBalance,
    required this.change,
  });

  final double totalBalance;
  final double change;

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    return GlassCard(
      padding: const EdgeInsets.all(22),
      gradient: const <Color>[
        Color(0xFF1D4ED8),
        Color(0xFF4C1D95),
      ],
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white70,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                '总资产',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            MoneyFormat.format(totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  isPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 16,
                  color: isPositive
                      ? const Color(0xFF6EE7B7)
                      : const Color(0xFFFCA5A5),
                ),
                const SizedBox(width: 4),
                Text(
                  '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}% 较上月',
                  style: TextStyle(
                    color: isPositive
                        ? const Color(0xFF6EE7B7)
                        : const Color(0xFFFCA5A5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.summary});

  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatCard(
            label: '收入',
            value: MoneyFormat.compact(summary.income),
            color: AppColors.income,
            icon: Icons.south_west_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: '支出',
            value: MoneyFormat.compact(summary.expense),
            color: AppColors.expense,
            icon: Icons.north_east_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: '结余',
            value: MoneyFormat.compact(summary.savings),
            color: AppColors.cyan,
            icon: Icons.savings_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String, VoidCallback)>[
      (
        Icons.edit_note_rounded,
        '记一笔',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TransactionEditPage()),
        ),
      ),
      (
        Icons.receipt_long_rounded,
        '账单',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TransactionListPage()),
        ),
      ),
      (
        Icons.file_upload_outlined,
        '导入',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ImportPage()),
        ),
      ),
      (
        Icons.auto_awesome_rounded,
        'AI',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AiAssistantPage()),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: actions.map((action) {
          return Expanded(
            child: _ActionButton(
              icon: action.$1,
              label: action.$2,
              onTap: action.$3,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    AppColors.primaryBlue.withOpacity(0.24),
                    AppColors.primaryPurple.withOpacity(0.18),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.finance});

  final FinanceController finance;

  @override
  Widget build(BuildContext context) {
    final recent = finance.transactions.take(7).toList();
    return Column(
      children: <Widget>[
        for (final transaction in recent)
          TransactionTile(
            transaction: transaction,
            categoryName: finance.categoryName(transaction.categoryId),
            categoryIconKey:
                finance.categoryById(transaction.categoryId)?.iconKey ?? 'more',
            categoryColor:
                finance.categoryById(transaction.categoryId)?.colorValue ??
                    0xFF94A3B8,
            accountName:
                finance.accountById(transaction.accountId)?.name ?? '账户',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TransactionEditPage(transaction: transaction),
                ),
              );
            },
          ),
      ],
    );
  }
}
