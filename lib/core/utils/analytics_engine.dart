import '../../domain/entities/budget.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/transaction_record.dart';
import 'date_utils.dart';

class MonthlySummary {
  const MonthlySummary({
    required this.income,
    required this.expense,
    required this.savings,
    required this.count,
  });

  final double income;
  final double expense;
  final double savings;
  final int count;
}

class CategorySlice {
  const CategorySlice({
    required this.categoryId,
    required this.label,
    required this.amount,
    required this.percent,
    required this.color,
  });

  final String categoryId;
  final String label;
  final double amount;
  final double percent;
  final int color;
}

class DailyPoint {
  const DailyPoint({
    required this.day,
    required this.income,
    required this.expense,
  });

  final int day;
  final double income;
  final double expense;
}

class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spent,
    required this.percent,
    required this.remaining,
    required this.isOver,
  });

  final Budget budget;
  final double spent;
  final double percent;
  final double remaining;
  final bool isOver;
}

class AnalyticsEngine {
  AnalyticsEngine._();

  static MonthlySummary monthly(
    List<TransactionRecord> transactions,
    DateTime month,
  ) {
    var income = 0.0;
    var expense = 0.0;
    var count = 0;
    for (final t in transactions) {
      if (!AppDateUtils.sameMonth(t.happenedAt, month)) continue;
      count++;
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    return MonthlySummary(
      income: income,
      expense: expense,
      savings: income - expense,
      count: count,
    );
  }

  static List<CategorySlice> categoryBreakdown(
    List<TransactionRecord> transactions,
    DateTime month,
    TransactionType type,
    List<Category> categories,
  ) {
    return categoryBreakdownRange(
      transactions,
      AppDateUtils.startOfMonth(month),
      AppDateUtils.endOfMonth(month),
      type,
      categories,
    );
  }

  static List<CategorySlice> categoryBreakdownRange(
    List<TransactionRecord> transactions,
    DateTime from,
    DateTime to,
    TransactionType type,
    List<Category> categories,
  ) {
    final totals = <String, double>{};
    final labels = <String, String>{};
    final colors = <String, int>{};
    double total = 0;

    for (final t in transactions) {
      if (t.happenedAt.isBefore(from) || t.happenedAt.isAfter(to) || t.type != type) {
        continue;
      }
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
      Category? category;
      for (final c in categories) {
        if (c.id == t.categoryId) {
          category = c;
          break;
        }
      }
      labels[t.categoryId] = category?.name ?? '未分类';
      colors[t.categoryId] = category?.colorValue ?? 0xFF94A3B8;
      total += t.amount;
    }

    if (total <= 0) return <CategorySlice>[];

    final slices = totals.entries.map((entry) {
      final amount = entry.value;
      return CategorySlice(
        categoryId: entry.key,
        label: labels[entry.key]!,
        amount: amount,
        percent: amount / total * 100,
        color: colors[entry.key]!,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return slices;
  }

  static List<DailyPoint> dailySeries(
    List<TransactionRecord> transactions,
    DateTime month,
  ) {
    final days = AppDateUtils.daysInMonth(month);
    final result = <DailyPoint>[];
    for (var day = 1; day <= days; day++) {
      var income = 0.0;
      var expense = 0.0;
      for (final t in transactions) {
        if (!AppDateUtils.sameDay(t.happenedAt, DateTime(month.year, month.month, day))) {
          continue;
        }
        if (t.type == TransactionType.income) {
          income += t.amount;
        } else {
          expense += t.amount;
        }
      }
      result.add(DailyPoint(day: day, income: income, expense: expense));
    }
    return result;
  }

  static Map<String, MonthlySummary> monthSeries(
    List<TransactionRecord> transactions,
    DateTime anchor,
    int months,
  ) {
    final result = <String, MonthlySummary>{};
    for (var offset = months - 1; offset >= 0; offset--) {
      final month = DateTime(anchor.year, anchor.month - offset, 1);
      final key = AppDateUtils.monthKey(month);
      result[key] = monthly(transactions, month);
    }
    return result;
  }

  static double changePercent(MonthlySummary current, MonthlySummary previous) {
    if (previous.expense <= 0) return 0;
    return (current.expense - previous.expense) / previous.expense * 100;
  }

  static BudgetProgress budgetProgress(
    List<TransactionRecord> transactions,
    Budget budget,
  ) {
    final month = DateTime.tryParse('${budget.period}-01') ?? DateTime.now();
    final spent = budget.scope == 'total'
        ? monthly(transactions, month).expense
        : transactions
            .where(
              (t) =>
                  AppDateUtils.sameMonth(t.happenedAt, month) &&
                  t.type == TransactionType.expense &&
                  t.categoryId == budget.categoryId,
            )
            .fold<double>(0, (sum, t) => sum + t.amount);
    final percent = budget.amount <= 0 ? 0.0 : spent / budget.amount * 100;
    return BudgetProgress(
      budget: budget,
      spent: spent,
      percent: percent,
      remaining: budget.amount - spent,
      isOver: spent > budget.amount,
    );
  }
}
