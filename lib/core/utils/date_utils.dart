class AppDateUtils {
  AppDateUtils._();

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String monthKey(DateTime month) =>
      '${month.year.toString().padLeft(4, '0')}-'
      '${month.month.toString().padLeft(2, '0')}';

  static String monthLabel(DateTime month) => '${month.year}年${month.month}月';

  static String fullDate(DateTime date) =>
      '${date.year}年${date.month}月${date.day}日';

  static String shortDate(DateTime date) => '${date.month}月${date.day}日';

  static String timeOf(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static int daysInMonth(DateTime month) {
    final next = DateTime(month.year, month.month + 1, 1);
    return next.subtract(const Duration(days: 1)).day;
  }

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);

  static DateTime startOfMonth(DateTime month) =>
      DateTime(month.year, month.month, 1);

  static DateTime endOfMonth(DateTime month) {
    final next = DateTime(month.year, month.month + 1, 1);
    return next.subtract(const Duration(microseconds: 1));
  }

  static DateTime startOfYear(DateTime date) => DateTime(date.year, 1, 1);

  static String weekdayLabel(int weekday) {
    const labels = <String>['一', '二', '三', '四', '五', '六', '日'];
    return labels[weekday - 1];
  }

  static String greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 6) return '夜深了';
    if (hour < 9) return '早上好';
    if (hour < 12) return '上午好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    if (hour < 23) return '晚上好';
    return '夜深了';
  }
}
