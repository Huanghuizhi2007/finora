import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/analytics_engine.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/money_formatter.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/transaction_record.dart';
import '../../state/finance_controller.dart';
import '../budget/budget_page.dart';
import '../widgets/glass_card.dart';

enum _StatsPeriod { thisMonth, lastMonth, thisYear, custom }

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  _StatsPeriod _period = _StatsPeriod.thisMonth;
  DateTimeRange? _customRange;

  (DateTime, DateTime) get _range {
    final now = DateTime.now();
    switch (_period) {
      case _StatsPeriod.thisMonth:
        return (
          AppDateUtils.startOfMonth(now),
          AppDateUtils.endOfMonth(now),
        );
      case _StatsPeriod.lastMonth:
        final month = DateTime(now.year, now.month - 1, 1);
        return (AppDateUtils.startOfMonth(month), AppDateUtils.endOfMonth(month));
      case _StatsPeriod.thisYear:
        return (
          AppDateUtils.startOfYear(now),
          DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case _StatsPeriod.custom:
        final range = _customRange;
        if (range != null) return (range.start, range.end);
        return (
          AppDateUtils.startOfMonth(now),
          AppDateUtils.endOfMonth(now),
        );
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryBlue,
            brightness: Brightness.dark,
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _period = _StatsPeriod.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();
    final (from, to) = _range;
    final records = finance.filteredTransactions(from: from, to: to);
    final anchor = _period == _StatsPeriod.thisYear
        ? DateTime(to.year, 12, 1)
        : DateTime(to.year, to.month, 1);
    final monthSummary = _period == _StatsPeriod.thisYear
        ? _sumRecords(records)
        : AnalyticsEngine.monthly(records, anchor);
    final slices = AnalyticsEngine.categoryBreakdownRange(
      records,
      from,
      to,
      TransactionType.expense,
      finance.categories,
    );
    final daily = _period == _StatsPeriod.thisYear
        ? <DailyPoint>[]
        : AnalyticsEngine.dailySeries(records, anchor);
    final monthSeries = AnalyticsEngine.monthSeries(
      finance.transactions,
      DateTime.now(),
      6,
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: finance.refresh,
        color: AppColors.primaryBlue,
        backgroundColor: AppColors.card,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('统计分析', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BudgetPage(),
                    ),
                  ),
                  tooltip: '预算',
                  icon: const Icon(
                    Icons.track_changes_rounded,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PeriodSelector(
              period: _period,
              onChanged: (value) => setState(() => _period = value),
              onCustom: _pickCustomRange,
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: _SummaryCard(
                    label: '收入',
                    value: MoneyFormat.compact(monthSummary.income),
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: '支出',
                    value: MoneyFormat.compact(monthSummary.expense),
                    color: AppColors.expense,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: '结余',
                    value: MoneyFormat.compact(monthSummary.savings),
                    color: AppColors.cyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ChartCard(
              title: _period == _StatsPeriod.thisYear
                  ? '全年收支趋势'
                  : '每日收支趋势',
              child: SizedBox(
                height: 220,
                child: _TrendChart(daily: daily, monthly: monthSeries),
              ),
            ),
            const SizedBox(height: 20),
            _ChartCard(
              title: '支出分类占比',
              trailing: '${slices.length} 个分类',
              child: slices.isEmpty
                  ? const SizedBox(
                      height: 180,
                      child: Center(
                        child: Text(
                          '暂无支出数据',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 240,
                      child: _CategoryPieChart(slices: slices),
                    ),
            ),
            const SizedBox(height: 20),
            _ChartCard(
              title: '近 6 个月支出',
              child: SizedBox(
                height: 220,
                child: _MonthlyBarChart(series: monthSeries),
              ),
            ),
          ],
        ),
      ),
    );
  }

  MonthlySummary _sumRecords(List<TransactionRecord> records) {
    var income = 0.0;
    var expense = 0.0;
    for (final record in records) {
      if (record.type == TransactionType.income) {
        income += record.amount;
      } else {
        expense += record.amount;
      }
    }
    return MonthlySummary(
      income: income,
      expense: expense,
      savings: income - expense,
      count: records.length,
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.period,
    required this.onChanged,
    required this.onCustom,
  });

  final _StatsPeriod period;
  final ValueChanged<_StatsPeriod> onChanged;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final items = <(_StatsPeriod, String)>[
      (_StatsPeriod.thisMonth, '本月'),
      (_StatsPeriod.lastMonth, '上月'),
      (_StatsPeriod.thisYear, '今年'),
      (_StatsPeriod.custom, '自定义'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = period == item.$1;
          return InkWell(
            onTap: item.$1 == _StatsPeriod.custom ? onCustom : () => onChanged(item.$1),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                item.$2,
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
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    letterSpacing: 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.daily, required this.monthly});

  final List<DailyPoint> daily;
  final Map<String, MonthlySummary> monthly;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    if (daily.isNotEmpty) {
      for (var i = 0; i < daily.length; i++) {
        spots.add(FlSpot(i.toDouble(), daily[i].expense));
      }
    } else {
      var index = 0;
      monthly.forEach((_, summary) {
        spots.add(FlSpot(index.toDouble(), summary.expense));
        index++;
      });
    }
    if (spots.isEmpty) {
      spots.add(const FlSpot(0, 0));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.divider,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: daily.length > 31 ? 1 : 7,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= spots.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    daily.isNotEmpty ? '${index + 1}日' : '${index + 1}月',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      letterSpacing: 0,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.32,
            color: AppColors.primaryBlue,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  const _CategoryPieChart({required this.slices});

  final List<CategorySlice> slices;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 42,
              startDegreeOffset: -90,
              sections: slices.map((slice) {
                return PieChartSectionData(
                  value: slice.amount,
                  color: Color(slice.color),
                  radius: 26,
                  title: '${slice.percent.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                );
              }).toList(),
            ),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: slices.take(6).map((slice) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(slice.color),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${slice.label} ${MoneyFormat.compact(slice.amount)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 0,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({required this.series});

  final Map<String, MonthlySummary> series;

  @override
  Widget build(BuildContext context) {
    final keys = series.keys.toList();
    final bars = <BarChartGroupData>[];
    for (var i = 0; i < keys.length; i++) {
      final summary = series[keys[i]]!;
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: <BarChartRodData>[
            BarChartRodData(
              toY: summary.expense,
              width: 12,
              borderRadius: BorderRadius.circular(6),
              color: AppColors.primaryPurple,
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.divider,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= keys.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    keys[index].substring(5),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      letterSpacing: 0,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: bars,
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }
}
