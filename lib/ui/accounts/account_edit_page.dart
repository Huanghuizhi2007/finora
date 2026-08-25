import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/finance_account.dart';
import '../../state/finance_controller.dart';
import '../widgets/gradient_button.dart';

class AccountEditPage extends StatefulWidget {
  const AccountEditPage({super.key, this.account});

  final FinanceAccount? account;

  @override
  State<AccountEditPage> createState() => _AccountEditPageState();
}

class _AccountEditPageState extends State<AccountEditPage> {
  static const List<int> _palette = <int>[
    0xFF2563EB,
    0xFF7C3AED,
    0xFF0891B2,
    0xFF059669,
    0xFFD97706,
    0xFFDC2626,
    0xFFDB2777,
    0xFF475569,
  ];

  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late AccountType _type;
  late int _color;

  @override
  void initState() {
    super.initState();
    final existing = widget.account;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _balanceController = TextEditingController(
      text: existing == null ? '' : existing.balance.toStringAsFixed(2),
    );
    _type = existing?.type ?? AccountType.wallet;
    _color = existing?.colorValue ?? _palette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final finance = context.read<FinanceController>();
    final userId = finance.userId;
    if (userId == null) return;
    if (_nameController.text.trim().isEmpty) {
      _showMessage('请输入账户名称');
      return;
    }
    final balance = double.tryParse(_balanceController.text.trim()) ?? 0;
    final existing = widget.account;
    await finance.saveAccount(
      FinanceAccount(
        id: existing?.id ?? '',
        userId: userId,
        name: _nameController.text.trim(),
        type: _type,
        balance: balance,
        iconKey: _type.iconKey,
        colorValue: _color,
        sortOrder: existing?.sortOrder ?? 99,
        createdAt: existing?.createdAt,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.account;
    if (existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这个账户？'),
        content: const Text('账户删除后，关联账单仍会保留。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<FinanceController>().deleteAccount(existing.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account == null ? '添加账户' : '编辑账户'),
        actions: <Widget>[
          if (widget.account != null)
            IconButton(
              onPressed: _delete,
              tooltip: '删除',
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.expense,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: <Widget>[
          Text('账户类型', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AccountType.values.map((type) {
              final selected = type == _type;
              return ChoiceChip(
                selected: selected,
                onSelected: (_) => setState(() => _type = type),
                avatar: Icon(
                  AppIcons.forKey(type.iconKey),
                  size: 16,
                  color: selected ? Colors.white : AppColors.textMuted,
                ),
                label: Text(
                  type.label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                selectedColor: Color(_color),
                backgroundColor: AppColors.surfaceAlt,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '账户名称',
              hintText: '例如：招商银行卡',
              prefixIcon: Icon(Icons.edit_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: '当前余额',
              prefixText: '¥ ',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            ),
          ),
          const SizedBox(height: 24),
          Text('卡片颜色', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: _palette.map((value) {
              final selected = _color == value;
              return InkWell(
                onTap: () => setState(() => _color = value),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(value),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          GradientButton(
            label: '保存账户',
            icon: Icons.check_rounded,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
