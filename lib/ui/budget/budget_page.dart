import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/analytics_engine.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/money_formatter.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/enums.dart';
import '../../state/finance_controller.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();
    final totalBudget = finance.budgets
        .where((b) => b.scope == 'total')
        .toList();
    final categoryBudgets = finance.budgets
        .where((b) => b.scope == 'category')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('预算管理'),
        actions: <Widget>[
          IconButton(
            onPressed: () => _showBudgetSheet(context, finance),
            tooltip: '新建预算',
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryBlue),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: <Widget>[
          if (totalBudget.isNotEmpty)
            _TotalBudgetCard(
              progress: AnalyticsEngine.budgetProgress(
                finance.transactions,
                totalBudget.first,
              ),
              finance: finance,
            )
          else
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '还没有设置总预算',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '设置后会在首页和通知中显示使用进度',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showBudgetSheet(context, finance),
                      child: const Text('设置总预算'),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Text('分类预算', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Text(
                '${categoryBudgets.length} 个',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (categoryBudgets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  '点击右上角新建分类预算',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            for (final budget in categoryBudgets)
              _CategoryBudgetTile(
                progress: AnalyticsEngine.budgetProgress(
                  finance.transactions,
                  budget,
                ),
                categoryName: finance.categoryName(budget.categoryId),
                iconKey: finance.categoryById(budget.categoryId)?.iconKey ??
                    'more',
                colorValue:
                    finance.categoryById(budget.categoryId)?.colorValue ??
                        0xFF94A3B8,
                onTap: () => _showBudgetSheet(context, finance, budget: budget),
              ),
        ],
      ),
    );
  }

  Future<void> _showBudgetSheet(
    BuildContext context,
    FinanceController finance, {
    Budget? budget,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BudgetSheet(finance: finance, budget: budget),
    );
  }
}

class _TotalBudgetCard extends StatelessWidget {
  const _TotalBudgetCard({
    required this.progress,
    required this.finance,
  });

  final BudgetProgress progress;
  final FinanceController finance;

  @override
  Widget build(BuildContext context) {
    final percent = progress.percent.clamp(0, 100).toDouble();
    final color = progress.isOver
        ? AppColors.expense
        : percent >= 80
            ? const Color(0xFFF59E0B)
            : AppColors.income;

    return GlassCard(
      gradient: const <Color>[Color(0xFF1E3A8A), Color(0xFF3B0764)],
      glow: true,
      onTap: () => BudgetPage()._showBudgetSheet(context, finance,
          budget: progress.budget),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.track_changes_rounded, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                '本月总预算',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                MoneyFormat.format(progress.spent),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ ${MoneyFormat.format(progress.budget.amount)}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Text(
                '${progress.percent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            progress.isOver
                ? '已超支 ${MoneyFormat.format(-progress.remaining)}'
                : '还可使用 ${MoneyFormat.format(progress.remaining)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBudgetTile extends StatelessWidget {
  const _CategoryBudgetTile({
    required this.progress,
    required this.categoryName,
    required this.iconKey,
    required this.colorValue,
    required this.onTap,
  });

  final BudgetProgress progress;
  final String categoryName;
  final String iconKey;
  final int colorValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = progress.percent.clamp(0, 100).toDouble();
    final color = progress.isOver
        ? AppColors.expense
        : percent >= 80
            ? const Color(0xFFF59E0B)
            : AppColors.income;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      radius: 18,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(colorValue).withOpacity(0.18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              AppIcons.forKey(iconKey),
              color: Color(colorValue),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      categoryName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${MoneyFormat.compact(progress.spent)} / ${MoneyFormat.compact(progress.budget.amount)}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceAlt,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
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

class _BudgetSheet extends StatefulWidget {
  const _BudgetSheet({required this.finance, this.budget});

  final FinanceController finance;
  final Budget? budget;

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  late bool _isTotal;
  late TextEditingController _amountController;
  late String _categoryId;
  late bool _notify80;
  late bool _notify100;

  @override
  void initState() {
    super.initState();
    final budget = widget.budget;
    _isTotal = budget?.scope == 'total';
    _amountController = TextEditingController(
      text: budget == null ? '' : budget.amount.toStringAsFixed(0),
    );
    _categoryId = budget?.categoryId ?? '';
    _notify80 = budget?.notifyAt80 ?? true;
    _notify100 = budget?.notifyAt100 ?? true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效预算金额')),
      );
      return;
    }
    if (!_isTotal && _categoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择分类')),
      );
      return;
    }
    final existing = widget.budget;
    final period = existing?.period ?? AppDateUtils.monthKey(DateTime.now());
    await widget.finance.saveBudget(
      Budget(
        id: existing?.id ?? '',
        userId: widget.finance.userId ?? '',
        scope: _isTotal ? 'total' : 'category',
        amount: amount,
        period: period,
        categoryId: _isTotal ? null : _categoryId,
        notifyAt80: _notify80,
        notifyAt100: _notify100,
        createdAt: existing?.createdAt,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.budget;
    if (existing == null) return;
    await widget.finance.deleteBudget(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final expenseCategories = widget.finance.categories
        .where((c) => c.type == TransactionType.expense)
        .toList();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.budget == null ? '新建预算' : '编辑预算',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: true,
                  icon: Icon(Icons.pie_chart_rounded),
                  label: Text('总预算'),
                ),
                ButtonSegment<bool>(
                  value: false,
                  icon: Icon(Icons.category_rounded),
                  label: Text('分类预算'),
                ),
              ],
              selected: <bool>{_isTotal},
              onSelectionChanged: (values) {
                setState(() => _isTotal = values.first);
              },
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '每月预算',
                prefixText: '¥ ',
              ),
            ),
            if (!_isTotal) ...<Widget>[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categoryId.isEmpty ? null : _categoryId,
                hint: const Text('选择分类'),
                items: expenseCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _categoryId = value ?? ''),
              ),
            ],
            const SizedBox(height: 18),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('使用 80% 时提醒'),
              value: _notify80,
              onChanged: (value) => setState(() => _notify80 = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('达到 100% 时提醒'),
              value: _notify100,
              onChanged: (value) => setState(() => _notify100 = value),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: '保存',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
            if (widget.budget != null) ...<Widget>[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _delete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.expense,
                  side: const BorderSide(color: AppColors.expense),
                ),
                child: const Text('删除预算'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
