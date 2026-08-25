import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/budget.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/finance_account.dart';
import '../../../domain/entities/transaction_record.dart';
import '../../supabase_service.dart';
import '../contracts/finance_repository.dart';

class SupabaseFinanceRepository implements FinanceRepository {
  SupabaseFinanceRepository();

  SupabaseClient get _client => SupabaseService.client;

  @override
  Future<List<FinanceAccount>> fetchAccounts(String userId) async {
    final rows = await _client
        .from('accounts')
        .select()
        .eq('user_id', userId)
        .eq('archived', false)
        .order('sort_order');
    return rows.map(FinanceAccount.fromMap).toList();
  }

  @override
  Future<List<Category>> fetchCategories(String userId) async {
    final rows = await _client
        .from('categories')
        .select()
        .order('sort_order');
    return rows
        .map(Category.fromMap)
        .where((c) => c.userId == null || c.userId == userId)
        .toList();
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
    var request = _client
        .from('transactions')
        .select()
        .eq('user_id', userId);
    if (from != null) request = request.gte('happened_at', from.toIso8601String());
    if (to != null) request = request.lte('happened_at', to.toIso8601String());
    if (query != null && query.trim().isNotEmpty) {
      request = request.ilike('note', '%${query.trim()}%');
    }
    if (type != null) request = request.eq('type', type.key);
    if (categoryId != null) request = request.eq('category_id', categoryId);
    if (accountId != null) request = request.eq('account_id', accountId);
    final rows = await request.order('happened_at', ascending: false);
    return rows.map(TransactionRecord.fromMap).toList();
  }

  @override
  Future<List<Budget>> fetchBudgets(String userId) async {
    final rows = await _client
        .from('budgets')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    return rows.map(Budget.fromMap).toList();
  }

  @override
  Future<void> saveAccount(FinanceAccount account) async {
    await _client.from('accounts').upsert(account.toMap(), onConflict: 'id');
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    await _client.from('accounts').delete().eq('id', accountId);
  }

  @override
  Future<void> saveCategory(Category category) async {
    await _client.from('categories').upsert(category.toMap(), onConflict: 'id');
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _client.from('categories').delete().eq('id', categoryId);
  }

  @override
  Future<void> saveTransaction(TransactionRecord transaction) async {
    await _client
        .from('transactions')
        .upsert(transaction.toMap(), onConflict: 'id');
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await _client.from('transactions').delete().eq('id', transactionId);
  }

  @override
  Future<void> saveBudget(Budget budget) async {
    await _client.from('budgets').upsert(budget.toMap(), onConflict: 'id');
  }

  @override
  Future<void> deleteBudget(String budgetId) async {
    await _client.from('budgets').delete().eq('id', budgetId);
  }

  @override
  Future<int> importTransactions(
    String userId,
    List<TransactionRecord> records,
  ) async {
    if (records.isEmpty) return 0;
    final existingRows = await _client
        .from('transactions')
        .select('external_id')
        .eq('user_id', userId)
        .not('external_id', 'is', null);
    final existing = existingRows
        .map((row) => row['external_id'] as String)
        .toSet();
    final fresh = records.where((r) => !existing.contains(r.externalId)).toList();
    if (fresh.isEmpty) return 0;
    await _client.from('transactions').insert(fresh.map((r) => r.toMap()).toList());
    return fresh.length;
  }
}
