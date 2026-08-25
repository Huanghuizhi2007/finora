import 'package:flutter/foundation.dart' hide Category;
import 'package:uuid/uuid.dart';

import '../data/repositories/contracts/finance_repository.dart';
import '../domain/entities/budget.dart';
import '../domain/entities/category.dart';
import '../domain/entities/enums.dart';
import '../domain/entities/finance_account.dart';
import '../domain/entities/transaction_record.dart';

class FinanceController extends ChangeNotifier {
  FinanceController(this._repository);

  final FinanceRepository _repository;
  final Uuid _uuid = const Uuid();

  String? _userId;
  bool _isLoading = false;
  String? _errorMessage;
  List<FinanceAccount> _accounts = <FinanceAccount>[];
  List<Category> _categories = <Category>[];
  List<TransactionRecord> _transactions = <TransactionRecord>[];
  List<Budget> _budgets = <Budget>[];

  String? get userId => _userId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<FinanceAccount> get accounts => List.unmodifiable(_accounts);
  List<Category> get categories => List.unmodifiable(_categories);
  List<TransactionRecord> get transactions => List.unmodifiable(_transactions);
  List<Budget> get budgets => List.unmodifiable(_budgets);

  double get totalBalance =>
      _accounts.fold<double>(0, (sum, account) => sum + account.balance);

  FinanceAccount? accountById(String? id) {
    if (id == null) return null;
    for (final account in _accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  Category? categoryById(String? id) {
    if (id == null) return null;
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  String categoryName(String? id) => categoryById(id)?.name ?? '未分类';

  Future<void> load() async {
    if (_userId == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>(<Future<Object>>[
        _repository.fetchAccounts(_userId!),
        _repository.fetchCategories(_userId!),
        _repository.fetchTransactions(_userId!),
        _repository.fetchBudgets(_userId!),
      ]);
      _accounts = results[0] as List<FinanceAccount>;
      _categories = results[1] as List<Category>;
      _transactions = results[2] as List<TransactionRecord>;
      _budgets = results[3] as List<Budget>;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setUserId(String? userId) async {
    if (_userId == userId) return;
    _userId = userId;
    _accounts = <FinanceAccount>[];
    _categories = <Category>[];
    _transactions = <TransactionRecord>[];
    _budgets = <Budget>[];
    notifyListeners();
    await load();
  }

  Future<void> refresh() => load();

  Future<void> saveTransaction(TransactionRecord input) async {
    final transaction = input.id.isEmpty
        ? TransactionRecord(
            id: _uuid.v4(),
            userId: input.userId,
            type: input.type,
            amount: input.amount,
            categoryId: input.categoryId,
            accountId: input.accountId,
            happenedAt: input.happenedAt,
            note: input.note,
            imageUrl: input.imageUrl,
            importSource: input.importSource,
            externalId: input.externalId,
            createdAt: input.createdAt ?? DateTime.now(),
          )
        : input;

    final oldIndex = _transactions.indexWhere((t) => t.id == transaction.id);
    final old = oldIndex >= 0 ? _transactions[oldIndex] : null;
    if (old != null) {
      _applyBalanceChange(old, transaction);
      _transactions[oldIndex] = transaction;
    } else {
      _applyBalanceChange(null, transaction);
      _transactions.add(transaction);
    }
    _transactions.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    notifyListeners();
    await _repository.saveTransaction(transaction);
  }

  void _applyBalanceChange(TransactionRecord? old, TransactionRecord updated) {
    void apply(TransactionRecord record, int direction) {
      final index = _accounts.indexWhere((a) => a.id == record.accountId);
      if (index < 0) return;
      final delta =
          record.type == TransactionType.income ? record.amount : -record.amount;
      final current = _accounts[index];
      _accounts[index] = current.copyWith(
        balance: current.balance + delta * direction,
      );
    }

    if (old != null) apply(old, -1);
    apply(updated, 1);
  }

  Future<void> deleteTransaction(String transactionId) async {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index < 0) return;
    final removed = _transactions[index];
    _applyBalanceChange(removed, removed.copyWith(amount: 0));
    _transactions.removeAt(index);
    notifyListeners();
    await _repository.deleteTransaction(transactionId);
  }

  Future<void> saveAccount(FinanceAccount input) async {
    final account = input.id.isEmpty
        ? FinanceAccount(
            id: _uuid.v4(),
            userId: input.userId,
            name: input.name,
            type: input.type,
            balance: input.balance,
            iconKey: input.iconKey,
            colorValue: input.colorValue,
            sortOrder: input.sortOrder,
            createdAt: DateTime.now(),
          )
        : input;
    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (index >= 0) {
      _accounts[index] = account;
    } else {
      _accounts.add(account);
    }
    notifyListeners();
    await _repository.saveAccount(account);
  }

  Future<void> deleteAccount(String accountId) async {
    _accounts.removeWhere((a) => a.id == accountId);
    notifyListeners();
    await _repository.deleteAccount(accountId);
  }

  Future<void> saveCategory(Category input) async {
    final category = input.id.isEmpty
        ? Category(
            id: _uuid.v4(),
            userId: input.userId,
            type: input.type,
            name: input.name,
            iconKey: input.iconKey,
            colorValue: input.colorValue,
            isSystem: false,
            sortOrder: input.sortOrder,
            createdAt: DateTime.now(),
          )
        : input;
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index >= 0) {
      _categories[index] = category;
    } else {
      _categories.add(category);
    }
    notifyListeners();
    await _repository.saveCategory(category);
  }

  Future<void> deleteCategory(String categoryId) async {
    _categories.removeWhere((c) => c.id == categoryId);
    notifyListeners();
    await _repository.deleteCategory(categoryId);
  }

  Future<void> saveBudget(Budget input) async {
    final budget = input.id.isEmpty
        ? Budget(
            id: _uuid.v4(),
            userId: input.userId,
            scope: input.scope,
            amount: input.amount,
            period: input.period,
            categoryId: input.categoryId,
            notifyAt80: input.notifyAt80,
            notifyAt100: input.notifyAt100,
            createdAt: DateTime.now(),
          )
        : input;
    final index = _budgets.indexWhere((b) => b.id == budget.id);
    if (index >= 0) {
      _budgets[index] = budget;
    } else {
      _budgets.add(budget);
    }
    notifyListeners();
    await _repository.saveBudget(budget);
  }

  Future<void> deleteBudget(String budgetId) async {
    _budgets.removeWhere((b) => b.id == budgetId);
    notifyListeners();
    await _repository.deleteBudget(budgetId);
  }

  Future<int> importTransactions(List<TransactionRecord> records) async {
    if (_userId == null || records.isEmpty) return 0;
    final count = await _repository.importTransactions(_userId!, records);
    await load();
    return count;
  }

  List<TransactionRecord> filteredTransactions({
    DateTime? from,
    DateTime? to,
    String? query,
    TransactionType? type,
    String? categoryId,
    String? accountId,
  }) {
    Iterable<TransactionRecord> result = _transactions;
    if (from != null) result = result.where((t) => !t.happenedAt.isBefore(from));
    if (to != null) result = result.where((t) => !t.happenedAt.isAfter(to));
    if (query != null && query.trim().isNotEmpty) {
      final keyword = query.trim().toLowerCase();
      result = result.where((t) => t.note.toLowerCase().contains(keyword));
    }
    if (type != null) result = result.where((t) => t.type == type);
    if (categoryId != null) result = result.where((t) => t.categoryId == categoryId);
    if (accountId != null) result = result.where((t) => t.accountId == accountId);
    return result.toList();
  }
}
