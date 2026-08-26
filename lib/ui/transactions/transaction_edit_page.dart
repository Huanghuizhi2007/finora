import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/transaction_record.dart';
import '../../state/finance_controller.dart';
import '../widgets/category_avatar.dart';
import '../widgets/gradient_button.dart';

class TransactionEditPage extends StatefulWidget {
  const TransactionEditPage({super.key, this.transaction});

  final TransactionRecord? transaction;

  @override
  State<TransactionEditPage> createState() => _TransactionEditPageState();
}

class _TransactionEditPageState extends State<TransactionEditPage> {
  late TransactionType _type;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _date;
  late String _categoryId;
  late String _accountId;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    final existing = widget.transaction;
    _type = existing?.type ?? TransactionType.expense;
    _amountController = TextEditingController(
      text: existing == null ? '' : existing.amount.toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _date = existing?.happenedAt ?? DateTime.now();
    _categoryId = existing?.categoryId ?? '';
    _accountId = existing?.accountId ?? '';
    _imagePath = existing?.imageUrl;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _imagePath = file.path);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
          _date.year,
          _date.month,
          _date.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    final finance = context.read<FinanceController>();
    final userId = finance.userId;
    if (userId == null) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showMessage('请输入有效金额');
      return;
    }
    if (_categoryId.isEmpty) {
      _showMessage('请选择分类');
      return;
    }
    if (_accountId.isEmpty) {
      _showMessage('请选择账户');
      return;
    }

    final existing = widget.transaction;
    final record = TransactionRecord(
      id: existing?.id ?? '',
      userId: userId,
      type: _type,
      amount: amount,
      categoryId: _categoryId,
      accountId: _accountId,
      happenedAt: _date,
      note: _noteController.text.trim(),
      imageUrl: _imagePath,
      importSource: existing?.importSource ?? ImportSource.manual,
      externalId: existing?.externalId,
      createdAt: existing?.createdAt,
    );
    await finance.saveTransaction(record);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.transaction;
    if (existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这笔账单？'),
        content: const Text('删除后无法恢复，账户余额也会同步调整。'),
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
      await context.read<FinanceController>().deleteTransaction(existing.id);
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
    final finance = context.watch<FinanceController>();
    final categories = finance.categories
        .where((c) => c.type == _type)
        .toList();
    final accounts = finance.accounts;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? '记一笔' : '编辑账单'),
        actions: <Widget>[
          if (widget.transaction != null)
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _TypeSelector(
              type: _type,
              onChanged: (value) => setState(() {
                _type = value;
                if (!categories.any((c) => c.id == _categoryId)) {
                  _categoryId = '';
                }
              }),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              decoration: const InputDecoration(
                labelText: '金额',
                prefixText: '¥ ',
                prefixStyle: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                hintText: '0.00',
              ),
            ),
            const SizedBox(height: 24),
            Text('分类', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final selected = category.id == _categoryId;
                return InkWell(
                  onTap: () => setState(() => _categoryId = category.id),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? Color(category.colorValue).withValues(alpha: 0.12)
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? Color(category.colorValue).withValues(alpha: 0.6)
                            : AppColors.divider,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CategoryAvatar(
                          iconKey: category.iconKey,
                          colorValue: category.colorValue,
                          size: 38,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text('账户', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: accounts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  final selected = account.id == _accountId;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) => setState(() => _accountId = account.id),
                    showCheckmark: false,
                    avatar: Icon(
                      AppIcons.forKey(account.iconKey),
                      size: 16,
                      color: selected
                          ? Colors.white
                          : AppColors.textMuted,
                    ),
                    label: Text(
                      account.name,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    selectedColor: Color(account.colorValue),
                    backgroundColor: AppColors.surfaceAlt,
                    side: BorderSide(
                      color: selected
                          ? Color(account.colorValue)
                          : Colors.white.withOpacity(0.08),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: Text(AppDateUtils.shortDate(_date)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text(AppDateUtils.timeOf(_date)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '备注',
                hintText: '记下这笔消费的细节',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                ),
                child: _imagePath == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.image_outlined,
                            color: AppColors.textMuted,
                            size: 28,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '添加账单截图',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _imagePath!.startsWith('http')
                            ? Image.network(
                                _imagePath!,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_imagePath!),
                                fit: BoxFit.cover,
                              ),
                      ),
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: '保存',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.type,
    required this.onChanged,
  });

  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _TypeButton(
              label: '支出',
              icon: Icons.north_east_rounded,
              color: AppColors.expense,
              selected: type == TransactionType.expense,
              onTap: () => onChanged(TransactionType.expense),
            ),
          ),
          Expanded(
            child: _TypeButton(
              label: '收入',
              icon: Icons.south_west_rounded,
              color: AppColors.income,
              selected: type == TransactionType.income,
              onTap: () => onChanged(TransactionType.income),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? color.withOpacity(0.22)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 18, color: selected ? color : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppColors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
