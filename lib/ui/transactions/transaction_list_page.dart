import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/transaction_record.dart';
import '../../state/finance_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_edit_page.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  final TextEditingController _searchController = TextEditingController();
  TransactionType? _type;
  bool _selectionMode = false;
  final Set<String> _selectedIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSelection(String id) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (!_selectedIds.add(id)) {
        _selectedIds.remove(id);
      }
      if (_selectedIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelectAll(List<TransactionRecord> records) {
    setState(() {
      if (_selectedIds.length == records.length) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds.addAll(records.map((t) => t.id));
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除 $count 笔账单？'),
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
    if (confirmed != true || !mounted) return;
    final finance = context.read<FinanceController>();
    for (final id in List<String>.of(_selectedIds)) {
      await finance.deleteTransaction(id);
    }
    if (mounted) {
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();
    final records = finance.filteredTransactions(
      query: _searchController.text,
      type: _type,
    );

    return Scaffold(
      appBar: AppBar(
        leading: _selectionMode
            ? IconButton(
                onPressed: _cancelSelection,
                tooltip: '取消多选',
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        title: Text(_selectionMode ? '已选 ${_selectedIds.length} 项' : '账单'),
        actions: _selectionMode
            ? <Widget>[
                IconButton(
                  onPressed: () => _toggleSelectAll(records),
                  tooltip: '全选',
                  icon: const Icon(Icons.select_all_rounded),
                ),
                IconButton(
                  onPressed: _deleteSelected,
                  tooltip: '删除',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.expense,
                  ),
                ),
              ]
            : <Widget>[
                IconButton(
                  onPressed: () => finance.refresh(),
                  tooltip: '刷新',
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
      ),
      body: Column(
        children: <Widget>[
          if (!_selectionMode) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '搜索备注',
                  prefixIcon: Icon(Icons.search_rounded),
                  suffixIcon: Icon(Icons.tune_rounded, size: 20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: <Widget>[
                  _FilterChip(
                    label: '全部',
                    selected: _type == null,
                    onTap: () => setState(() => _type = null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '支出',
                    selected: _type == TransactionType.expense,
                    onTap: () =>
                        setState(() => _type = TransactionType.expense),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '收入',
                    selected: _type == TransactionType.income,
                    onTap: () =>
                        setState(() => _type = TransactionType.income),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: RefreshIndicator(
              onRefresh: finance.refresh,
              color: AppColors.primaryBlue,
              backgroundColor: AppColors.card,
              child: records.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const <Widget>[
                        EmptyState(
                          title: '没有找到账单',
                          subtitle: '换个关键词或筛选条件试试',
                          icon: Icons.search_off_rounded,
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                      itemCount: records.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 60),
                      itemBuilder: (context, index) {
                        final transaction = records[index];
                        return TransactionTile(
                          transaction: transaction,
                          categoryName:
                              finance.categoryName(transaction.categoryId),
                          categoryIconKey: finance
                                  .categoryById(transaction.categoryId)
                                  ?.iconKey ??
                              'more',
                          categoryColor:
                              finance.categoryById(transaction.categoryId)
                                      ?.colorValue ??
                                  0xFF94A3B8,
                          accountName: finance
                                  .accountById(transaction.accountId)
                                  ?.name ??
                              '账户',
                          onTap: _selectionMode
                              ? () => _toggleSelection(transaction.id)
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => TransactionEditPage(
                                        transaction: transaction,
                                      ),
                                    ),
                                  );
                                },
                          onLongPress: () => _startSelection(transaction.id),
                          isSelected: _selectedIds.contains(transaction.id),
                          showSelection: _selectionMode,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectionMode
          ? _SelectionBar(
              count: _selectedIds.length,
              allSelected: records.isNotEmpty &&
                  _selectedIds.length == records.length,
              onSelectAll: () => _toggleSelectAll(records),
              onDelete: _deleteSelected,
            )
          : null,
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.allSelected,
    required this.onSelectAll,
    required this.onDelete,
  });

  final int count;
  final bool allSelected;
  final VoidCallback onSelectAll;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: <Widget>[
              TextButton.icon(
                onPressed: onSelectAll,
                icon: Icon(
                  allSelected
                      ? Icons.select_all_rounded
                      : Icons.select_all_rounded,
                  size: 20,
                ),
                label: Text(allSelected ? '取消全选' : '全选'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: count == 0 ? null : onDelete,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.expense,
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text('删除($count)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Theme.of(context).colorScheme.onPrimary
                : AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
