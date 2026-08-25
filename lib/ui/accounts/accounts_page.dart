import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/money_formatter.dart';
import '../../domain/entities/finance_account.dart';
import '../../state/finance_controller.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import 'account_edit_page.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();
    final accounts = finance.accounts;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: finance.refresh,
        color: AppColors.primaryBlue,
        backgroundColor: AppColors.card,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('我的账户', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Text(
                  '${accounts.length} 个账户',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              gradient: const <Color>[Color(0xFF0F172A), Color(0xFF1E293B)],
              glow: true,
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.account_balance_rounded,
                    color: AppColors.primaryBlue,
                    size: 30,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '总资产',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            letterSpacing: 0,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    MoneyFormat.format(finance.totalBalance),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (accounts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    '还没有账户，点击下方按钮添加',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              )
            else
              for (final account in accounts)
                _AccountCard(
                  account: account,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AccountEditPage(account: account),
                      ),
                    );
                  },
                ),
            const SizedBox(height: 20),
            GradientButton(
              label: '添加账户',
              icon: Icons.add_rounded,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AccountEditPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.onTap});

  final FinanceAccount account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final base = Color(account.colorValue);
    final darker = Color.lerp(base, Colors.black, 0.45)!;
    final isCredit = account.type.label == '信用卡';
    final displayBalance = isCredit
        ? MoneyFormat.format(account.balance.abs())
        : MoneyFormat.format(account.balance);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[base, darker],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: base.withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      AppIcons.forKey(account.iconKey),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          account.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          account.type.label,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 12,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        displayBalance,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCredit ? '待还款' : '余额',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
