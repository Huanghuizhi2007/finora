import '../../../domain/entities/budget.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/finance_account.dart';
import '../../../domain/entities/transaction_record.dart';

abstract class FinanceRepository {
  Future<List<FinanceAccount>> fetchAccounts(String userId);

  Future<List<Category>> fetchCategories(String userId);

  Future<List<TransactionRecord>> fetchTransactions(
    String userId, {
    DateTime? from,
    DateTime? to,
    String? query,
    TransactionType? type,
    String? categoryId,
    String? accountId,
  });

  Future<List<Budget>> fetchBudgets(String userId);

  Future<void> saveAccount(FinanceAccount account);

  Future<void> deleteAccount(String accountId);

  Future<void> saveCategory(Category category);

  Future<void> deleteCategory(String categoryId);

  Future<void> saveTransaction(TransactionRecord transaction);

  Future<void> deleteTransaction(String transactionId);

  Future<void> saveBudget(Budget budget);

  Future<void> deleteBudget(String budgetId);

  Future<int> importTransactions(String userId, List<TransactionRecord> records);
}
