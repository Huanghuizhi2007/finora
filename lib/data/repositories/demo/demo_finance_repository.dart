import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/budget.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/finance_account.dart';
import '../../../domain/entities/transaction_record.dart';
import '../contracts/finance_repository.dart';

class DemoFinanceRepository implements FinanceRepository {
  DemoFinanceRepository() {
    _seed();
  }

  static const String _userId = 'demo-user';
  final List<FinanceAccount> _accounts = <FinanceAccount>[];
  final List<Category> _categories = <Category>[];
  final List<TransactionRecord> _transactions = <TransactionRecord>[];
  final List<Budget> _budgets = <Budget>[];

  void _seed() {
    final now = DateTime.now();

    _accounts.addAll(<FinanceAccount>[
      FinanceAccount(
        id: 'acc-wechat',
        userId: _userId,
        name: '微信支付',
        type: AccountType.wechat,
        balance: 3200,
        iconKey: 'wechat',
        colorValue: 0xFF2563EB,
        sortOrder: 0,
        createdAt: now.subtract(const Duration(days: 180)),
      ),
      FinanceAccount(
        id: 'acc-alipay',
        userId: _userId,
        name: '支付宝',
        type: AccountType.alipay,
        balance: 2450,
        iconKey: 'alipay',
        colorValue: 0xFF7C3AED,
        sortOrder: 1,
        createdAt: now.subtract(const Duration(days: 180)),
      ),
      FinanceAccount(
        id: 'acc-cash',
        userId: _userId,
        name: '现金',
        type: AccountType.cash,
        balance: 980,
        iconKey: 'cash',
        colorValue: 0xFF059669,
        sortOrder: 2,
        createdAt: now.subtract(const Duration(days: 180)),
      ),
      FinanceAccount(
        id: 'acc-bank',
        userId: _userId,
        name: '招商银行卡',
        type: AccountType.bankCard,
        balance: 8350,
        iconKey: 'bank',
        colorValue: 0xFF0891B2,
        sortOrder: 3,
        createdAt: now.subtract(const Duration(days: 180)),
      ),
      FinanceAccount(
        id: 'acc-credit',
        userId: _userId,
        name: '信用卡',
        type: AccountType.creditCard,
        balance: -2400,
        iconKey: 'credit',
        colorValue: 0xFFDC2626,
        sortOrder: 4,
        createdAt: now.subtract(const Duration(days: 120)),
      ),
    ]);

    var order = 0;
    for (final style in defaultExpenseCategories) {
      _categories.add(
        Category(
          id: 'cat-exp-${style.label}',
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
      _categories.add(
        Category(
          id: 'cat-inc-${style.label}',
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

    _seedTransactions(now);
    _seedBudgets(now);
  }

  void _seedTransactions(DateTime now) {
    final random = Random(42);
    final expenseIds = _categories
        .where((c) => c.type == TransactionType.expense)
        .map((c) => c.id)
        .toList();
    final incomeIds = _categories
        .where((c) => c.type == TransactionType.income)
        .map((c) => c.id)
        .toList();
    final accountIds = <String>['acc-wechat', 'acc-alipay', 'acc-cash', 'acc-bank', 'acc-credit'];

    for (var offset = 5; offset >= 0; offset--) {
      final month = DateTime(now.year, now.month - offset, 1);
      final monthExpenseTotal = 2600 + random.nextInt(1400);
      var spent = 0;

      _transactions.add(
        TransactionRecord(
          id: const Uuid().v4(),
          userId: _userId,
          type: TransactionType.income,
          amount: 8000,
          categoryId: 'cat-inc-工资',
          accountId: 'acc-bank',
          happenedAt: DateTime(month.year, month.month, 1, 9, 30),
          note: '8 月工资',
          createdAt: DateTime(month.year, month.month, 1, 9, 30),
        ),
      );

      if (offset == 0) {
        _transactions.add(
          TransactionRecord(
            id: const Uuid().v4(),
            userId: _userId,
            type: TransactionType.income,
            amount: 1200,
            categoryId: 'cat-inc-兼职',
            accountId: 'acc-alipay',
            happenedAt: DateTime(now.year, now.month, 15, 12, 0),
            note: '设计兼职',
            createdAt: DateTime(now.year, now.month, 15, 12, 0),
          ),
        );
      }

      final maxDay = now.month == month.month ? now.day : 28;
      var attempts = 0;
      while (spent < monthExpenseTotal && attempts < 400) {
        attempts++;
        final day = 1 + random.nextInt(maxDay);
        var hour = 8 + random.nextInt(12);
        var minute = random.nextInt(60);
        if (offset == 0 && day == now.day) {
          hour = min(hour, now.hour);
          if (hour == now.hour) minute = min(minute, now.minute);
        }
        final happenedAt = DateTime(month.year, month.month, day, hour, minute);
        if (happenedAt.isAfter(now)) continue;

        final categoryId = expenseIds[random.nextInt(expenseIds.length)];
        final amount = (8 + random.nextInt(360)).toDouble();
        _transactions.add(
          TransactionRecord(
            id: const Uuid().v4(),
            userId: _userId,
            type: TransactionType.expense,
            amount: amount,
            categoryId: categoryId,
            accountId: accountIds[random.nextInt(accountIds.length)],
            happenedAt: happenedAt,
            note: _noteForCategory(categoryId),
            createdAt: happenedAt,
          ),
        );
        spent += amount.toInt();
      }

      if (offset > 0) {
        _transactions.add(
          TransactionRecord(
            id: const Uuid().v4(),
            userId: _userId,
            type: TransactionType.income,
            amount: (600 + random.nextInt(800)).toDouble(),
            categoryId: incomeIds[random.nextInt(incomeIds.length)],
            accountId: 'acc-bank',
            happenedAt: DateTime(month.year, month.month, 20, 10, 0),
            note: '投资收益',
            createdAt: DateTime(month.year, month.month, 20, 10, 0),
          ),
        );
      }
    }

    _transactions.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
  }

  String _noteForCategory(String categoryId) {
    const notes = <String, String>{
      'cat-exp-餐饮': '午餐',
      'cat-exp-交通': '地铁通勤',
      'cat-exp-购物': '生活用品',
      'cat-exp-娱乐': '电影',
      'cat-exp-住房': '房租',
      'cat-exp-水电': '电费',
      'cat-exp-学习': '课程',
      'cat-exp-医疗': '药品',
      'cat-exp-旅行': '车票',
    };
    return notes[categoryId] ?? '日常消费';
  }

  void _seedBudgets(DateTime now) {
    final period = AppDateUtils.monthKey(now);
    _budgets.addAll(<Budget>[
      Budget(
        id: 'bud-total',
        userId: _userId,
        scope: 'total',
        amount: 5000,
        period: period,
        createdAt: now,
      ),
      Budget(
        id: 'bud-food',
        userId: _userId,
        scope: 'category',
        amount: 1000,
        period: period,
        categoryId: 'cat-exp-餐饮',
        createdAt: now,
      ),
      Budget(
        id: 'bud-transit',
        userId: _userId,
        scope: 'category',
        amount: 500,
        period: period,
        categoryId: 'cat-exp-交通',
        createdAt: now,
      ),
      Budget(
        id: 'bud-cart',
        userId: _userId,
        scope: 'category',
        amount: 800,
        period: period,
        categoryId: 'cat-exp-购物',
        createdAt: now,
      ),
      Budget(
        id: 'bud-fun',
        userId: _userId,
        scope: 'category',
        amount: 600,
        period: period,
        categoryId: 'cat-exp-娱乐',
        createdAt: now,
      ),
    ]);
  }

  @override
  Future<List<FinanceAccount>> fetchAccounts(String userId) async {
    return List<FinanceAccount>.of(_accounts.where((a) => !a.isArchived));
  }

  @override
  Future<List<Category>> fetchCategories(String userId) async {
    return List<Category>.of(_categories);
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
    Iterable<TransactionRecord> result = _transactions.where(
      (t) => t.userId == userId,
    );
    if (from != null) result = result.where((t) => !t.happenedAt.isBefore(from));
    if (to != null) result = result.where((t) => !t.happenedAt.isAfter(to));
    if (query != null && query.trim().isNotEmpty) {
      final keyword = query.trim().toLowerCase();
      result = result.where(
        (t) => t.note.toLowerCase().contains(keyword),
      );
    }
    if (type != null) result = result.where((t) => t.type == type);
    if (categoryId != null) result = result.where((t) => t.categoryId == categoryId);
    if (accountId != null) result = result.where((t) => t.accountId == accountId);
    final list = result.toList()..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    return list;
  }

  @override
  Future<List<Budget>> fetchBudgets(String userId) async {
    return List<Budget>.of(_budgets);
  }

  @override
  Future<void> saveAccount(FinanceAccount account) async {
    final existingIndex = _accounts.indexWhere((a) => a.id == account.id);
    if (existingIndex >= 0) {
      _accounts[existingIndex] = account;
    } else {
      _accounts.add(account);
    }
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    _accounts.removeWhere((a) => a.id == accountId);
  }

  @override
  Future<void> saveCategory(Category category) async {
    final existingIndex = _categories.indexWhere((c) => c.id == category.id);
    if (existingIndex >= 0) {
      _categories[existingIndex] = category;
    } else {
      _categories.add(category);
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    _categories.removeWhere((c) => c.id == categoryId);
  }

  @override
  Future<void> saveTransaction(TransactionRecord transaction) async {
    final existingIndex = _transactions.indexWhere((t) => t.id == transaction.id);
    if (existingIndex >= 0) {
      _transactions[existingIndex] = transaction;
    } else {
      _transactions.add(transaction);
    }
    _transactions.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    _transactions.removeWhere((t) => t.id == transactionId);
  }

  @override
  Future<void> saveBudget(Budget budget) async {
    final existingIndex = _budgets.indexWhere((b) => b.id == budget.id);
    if (existingIndex >= 0) {
      _budgets[existingIndex] = budget;
    } else {
      _budgets.add(budget);
    }
  }

  @override
  Future<void> deleteBudget(String budgetId) async {
    _budgets.removeWhere((b) => b.id == budgetId);
  }

  @override
  Future<int> importTransactions(
    String userId,
    List<TransactionRecord> records,
  ) async {
    var imported = 0;
    for (final record in records) {
      final exists = _transactions.any(
        (t) =>
            t.externalId != null &&
            t.externalId == record.externalId &&
            t.amount == record.amount,
      );
      if (exists) continue;
      _transactions.add(record);
      imported++;
    }
    _transactions.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    return imported;
  }
}
