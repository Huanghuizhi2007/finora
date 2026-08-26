import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/budget.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/finance_account.dart';
import '../../../domain/entities/transaction_record.dart';
import '../contracts/finance_repository.dart';

class DemoFinanceRepository implements FinanceRepository {
  DemoFinanceRepository();

  final Map<String, _UserFinanceData> _dataByUser = <String, _UserFinanceData>{};

  Future<_UserFinanceData> _dataFor(String userId) async {
    final existing = _dataByUser[userId];
    if (existing != null) return existing;
    final saved = await _loadFromPrefs(userId);
    final data = saved ??
        _UserFinanceData(
          accounts: _seedAccounts(userId),
          categories: _seedCategories(userId),
        );
    _dataByUser[userId] = data;
    return data;
  }

  Future<_UserFinanceData?> _loadFromPrefs(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey(userId));
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _UserFinanceData(
        accounts: (map['accounts'] as List<dynamic>)
            .map((e) => FinanceAccount.fromMap(e as Map<String, dynamic>))
            .toList(),
        categories: (map['categories'] as List<dynamic>)
            .map((e) => Category.fromMap(e as Map<String, dynamic>))
            .toList(),
        transactions: (map['transactions'] as List<dynamic>)
            .map((e) => TransactionRecord.fromMap(e as Map<String, dynamic>))
            .toList(),
        budgets: (map['budgets'] as List<dynamic>)
            .map((e) => Budget.fromMap(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist(String userId) async {
    final data = _dataByUser[userId];
    if (data == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey(userId),
        jsonEncode(<String, dynamic>{
          'accounts': data.accounts.map((e) => e.toMap()).toList(),
          'categories': data.categories.map((e) => e.toMap()).toList(),
          'transactions': data.transactions.map((e) => e.toMap()).toList(),
          'budgets': data.budgets.map((e) => e.toMap()).toList(),
        }),
      );
    } catch (_) {
      // 本地存储不可用时仅保留内存数据。
    }
  }

  String _prefsKey(String userId) => 'finora_demo_data_$userId';

  List<FinanceAccount> _seedAccounts(String userId) {
    final now = DateTime.now();
    return <FinanceAccount>[
      FinanceAccount(
        id: 'acc-wechat',
        userId: userId,
        name: '微信支付',
        type: AccountType.wechat,
        balance: 0,
        iconKey: 'wechat',
        colorValue: 0xFF2563EB,
        sortOrder: 0,
        createdAt: now,
      ),
      FinanceAccount(
        id: 'acc-alipay',
        userId: userId,
        name: '支付宝',
        type: AccountType.alipay,
        balance: 0,
        iconKey: 'alipay',
        colorValue: 0xFF7C3AED,
        sortOrder: 1,
        createdAt: now,
      ),
      FinanceAccount(
        id: 'acc-cash',
        userId: userId,
        name: '现金',
        type: AccountType.cash,
        balance: 0,
        iconKey: 'cash',
        colorValue: 0xFF059669,
        sortOrder: 2,
        createdAt: now,
      ),
      FinanceAccount(
        id: 'acc-bank',
        userId: userId,
        name: '银行卡',
        type: AccountType.bankCard,
        balance: 0,
        iconKey: 'bank',
        colorValue: 0xFF0891B2,
        sortOrder: 3,
        createdAt: now,
      ),
    ];
  }

  List<Category> _seedCategories(String userId) {
    final now = DateTime.now();
    final categories = <Category>[];
    var order = 0;
    for (final style in defaultExpenseCategories) {
      categories.add(
        Category(
          id: 'cat-exp-${style.label}',
          userId: userId,
          type: TransactionType.expense,
          name: style.label,
          iconKey: style.iconKey,
          colorValue: style.color.value,
          isSystem: true,
          sortOrder: order++,
          createdAt: now,
        ),
      );
    }
    for (final style in defaultIncomeCategories) {
      categories.add(
        Category(
          id: 'cat-inc-${style.label}',
          userId: userId,
          type: TransactionType.income,
          name: style.label,
          iconKey: style.iconKey,
          colorValue: style.color.value,
          isSystem: true,
          sortOrder: order++,
          createdAt: now,
        ),
      );
    }
    return categories;
  }

  @override
  Future<List<FinanceAccount>> fetchAccounts(String userId) async {
    final data = await _dataFor(userId);
    return List<FinanceAccount>.of(data.accounts);
  }

  @override
  Future<List<Category>> fetchCategories(String userId) async {
    final data = await _dataFor(userId);
    return List<Category>.of(data.categories);
  }

  @override
  Future<List<TransactionRecord>> fetchTransactions(
    String userId, {
    DateTime? from,
    DateTime? to,
    String? query,
    TransactionType? type,
    String? categoryId,
    String? accountId,
  }) async {
    final data = await _dataFor(userId);
    Iterable<TransactionRecord> result = data.transactions;
    if (from != null) result = result.where((t) => !t.happenedAt.isBefore(from));
    if (to != null) result = result.where((t) => !t.happenedAt.isAfter(to));
    if (query != null && query.trim().isNotEmpty) {
      final keyword = query.trim().toLowerCase();
      result = result.where((t) => t.note.toLowerCase().contains(keyword));
    }
    if (type != null) result = result.where((t) => t.type == type);
    if (categoryId != null) result = result.where((t) => t.categoryId == categoryId);
    if (accountId != null) result = result.where((t) => t.accountId == accountId);
    final list = result.toList()
      ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    return list;
  }

  @override
  Future<List<Budget>> fetchBudgets(String userId) async {
    final data = await _dataFor(userId);
    return List<Budget>.of(data.budgets);
  }

  @override
  Future<void> saveAccount(FinanceAccount account) async {
    final data = await _dataFor(account.userId);
    final existingIndex = data.accounts.indexWhere((a) => a.id == account.id);
    if (existingIndex >= 0) {
      data.accounts[existingIndex] = account;
    } else {
      data.accounts.add(account);
    }
    await _persist(account.userId);
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    final ownerId = _ownerForAccount(accountId);
    if (ownerId == null) return;
    final data = _dataByUser[ownerId]!;
    data.accounts.removeWhere((a) => a.id == accountId);
    await _persist(ownerId);
  }

  String? _ownerForAccount(String accountId) {
    for (final entry in _dataByUser.entries) {
      if (entry.value.accounts.any((a) => a.id == accountId)) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  Future<void> saveCategory(Category category) async {
    final ownerId = category.userId ?? _ownerForCategory(category.id);
    if (ownerId == null) return;
    final data = await _dataFor(ownerId);
    final existingIndex = data.categories.indexWhere((c) => c.id == category.id);
    if (existingIndex >= 0) {
      data.categories[existingIndex] = category;
    } else {
      data.categories.add(category);
    }
    await _persist(ownerId);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    final ownerId = _ownerForCategory(categoryId);
    if (ownerId == null) return;
    final data = _dataByUser[ownerId]!;
    data.categories.removeWhere((c) => c.id == categoryId);
    await _persist(ownerId);
  }

  @override
  Future<void> saveTransaction(TransactionRecord transaction) async {
    final data = await _dataFor(transaction.userId);
    final existingIndex =
        data.transactions.indexWhere((t) => t.id == transaction.id);
    if (existingIndex >= 0) {
      data.transactions[existingIndex] = transaction;
    } else {
      data.transactions.add(transaction);
    }
    data.transactions.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    await _persist(transaction.userId);
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    final ownerId = _ownerForTransaction(transactionId);
    if (ownerId == null) return;
    final data = _dataByUser[ownerId]!;
    data.transactions.removeWhere((t) => t.id == transactionId);
    await _persist(ownerId);
  }

  String? _ownerForTransaction(String transactionId) {
    for (final entry in _dataByUser.entries) {
      if (entry.value.transactions.any((t) => t.id == transactionId)) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  Future<void> saveBudget(Budget budget) async {
    final data = await _dataFor(budget.userId);
    final existingIndex = data.budgets.indexWhere((b) => b.id == budget.id);
    if (existingIndex >= 0) {
      data.budgets[existingIndex] = budget;
    } else {
      data.budgets.add(budget);
    }
    await _persist(budget.userId);
  }

  @override
  Future<void> deleteBudget(String budgetId) async {
    final ownerId = _ownerForBudget(budgetId);
    if (ownerId == null) return;
    final data = _dataByUser[ownerId]!;
    data.budgets.removeWhere((b) => b.id == budgetId);
    await _persist(ownerId);
  }

  String? _ownerForBudget(String budgetId) {
    for (final entry in _dataByUser.entries) {
      if (entry.value.budgets.any((b) => b.id == budgetId)) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  Future<int> importTransactions(
    String userId,
    List<TransactionRecord> records,
  ) async {
    final data = await _dataFor(userId);
    var imported = 0;
    for (final record in records) {
      final exists = data.transactions.any(
        (t) =>
            t.externalId != null &&
            t.externalId == record.externalId &&
            t.amount == record.amount,
      );
      if (exists) continue;
      data.transactions.add(record);
      imported++;
    }
    data.transactions.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    await _persist(userId);
    return imported;
  }

  String? _ownerForCategory(String categoryId) {
    for (final entry in _dataByUser.entries) {
      if (entry.value.categories.any((c) => c.id == categoryId)) {
        return entry.key;
      }
    }
    return null;
  }
}

class _UserFinanceData {
  _UserFinanceData({
    required this.accounts,
    required this.categories,
    List<TransactionRecord>? transactions,
    List<Budget>? budgets,
  })  : transactions = transactions ?? <TransactionRecord>[],
        budgets = budgets ?? <Budget>[];

  final List<FinanceAccount> accounts;
  final List<Category> categories;
  final List<TransactionRecord> transactions;
  final List<Budget> budgets;
}
