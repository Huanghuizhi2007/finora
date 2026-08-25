import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/analytics_engine.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/money_formatter.dart';
import '../../state/finance_controller.dart';
import 'day_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  void _changeMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();
    final series = AnalyticsEngine.dailySeries(finance.transactions, _month);
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday;
    final days = AppDateUtils.daysInMonth(_month);
    final today = DateTime.now();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: finance.refresh,
        color: AppColors.primaryBlue,
        backgroundColor: AppColors.card,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: <Widget>[
                    Text(
                      '日历记账',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _changeMonth(-1),
                      tooltip: '上个月',
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      AppDateUtils.monthLabel(_month),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeMonth(1),
                      tooltip: '下个月',
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: <Widget>[
                    for (var i = 1; i <= 7; i++)
                      Expanded(
                        child: Center(
                          child: Text(
                            AppDateUtils.weekdayLabel(i),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final dayNumber = index - firstWeekday + 2;
                    if (dayNumber < 1 || dayNumber > days) {
                      return const SizedBox.shrink();
                    }
                    final date = DateTime(_month.year, _month.month, dayNumber);
                    final point = series[dayNumber - 1];
                    final isToday = AppDateUtils.sameDay(date, today);

                    return _DayCell(
                      day: dayNumber,
                      point: point,
                      isToday: isToday,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DayDetailPage(
                              date: date,
                              transactions: finance.filteredTransactions(
                                from: AppDateUtils.startOfDay(date),
                                to: AppDateUtils.endOfDay(date),
                              ),
                              finance: finance,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: firstWeekday + days - 1,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              sliver: SliverToBoxAdapter(
                child: _Legend(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.point,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final DailyPoint point;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasData = point.income > 0 || point.expense > 0;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isToday
                  ? AppColors.primaryBlue.withOpacity(0.7)
                  : Colors.transparent,
              width: isToday ? 1.2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '$day',
                style: TextStyle(
                  color: isToday
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              if (point.expense > 0)
                Text(
                  MoneyFormat.compact(point.expense).replaceFirst('¥', ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              if (point.income > 0)
                Text(
                  MoneyFormat.compact(point.income).replaceFirst('¥', ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.income,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              if (!hasData) const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(Icons.circle, size: 8, color: AppColors.expense),
        const SizedBox(width: 4),
        const Text(
          '支出',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.circle, size: 8, color: AppColors.income),
        const SizedBox(width: 4),
        const Text(
          '收入',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.circle, size: 8, color: AppColors.primaryBlue),
        const SizedBox(width: 4),
        const Text(
          '今天',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}
