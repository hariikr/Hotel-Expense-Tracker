import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load weekly and monthly summaries based on the current context in state
    final now = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = context.read<DashboardBloc>().state;
      final currentContext = currentState is DashboardLoaded ? currentState.selectedContext : 'hotel';
      
      context
          .read<DashboardBloc>()
          .add(LoadWeeklySummary(Formatters.getWeekStart(now), context: currentContext));
      context.read<DashboardBloc>().add(LoadMonthlySummary(now.year, now.month, context: currentContext));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            final contextType = state is DashboardLoaded ? state.selectedContext : 'hotel';
            return Text('${contextType.toUpperCase()} Analytics');
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
          indicatorColor: Colors.white,
        ),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildWeeklyView(state),
                _buildMonthlyView(state),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildWeeklyView(DashboardLoaded state) {
    final now = DateTime.now();
    final weekStart = Formatters.getWeekStart(now);
    final weekEnd = Formatters.getWeekEnd(now);

    // Filter summaries by date and selected context
    final weeklySummaries = state.allSummaries.where((s) {
      final normalizedDate = Formatters.normalizeDate(s.date);
      final normalizedStart = Formatters.normalizeDate(weekStart);
      final normalizedEnd = Formatters.normalizeDate(weekEnd);
      return (normalizedDate.isAtSameMomentAs(normalizedStart) ||
              normalizedDate.isAfter(normalizedStart)) &&
          (normalizedDate.isAtSameMomentAs(normalizedEnd) ||
              normalizedDate.isBefore(normalizedEnd));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Week of ${Formatters.formatDate(weekStart)}',
                    style: AppTheme.headingSmall,
                  ),
                  const SizedBox(height: 16),
                  if (state.weeklySummary != null) ...[
                    _buildSummaryRow(
                        'Income',
                        state.weeklySummary!['totalIncome']!,
                        AppTheme.profitColor),
                    const Divider(height: 24),
                    _buildSummaryRow(
                        'Expense',
                        state.weeklySummary!['totalExpense']!,
                        AppTheme.lossColor),
                    const Divider(height: 24),
                    _buildSummaryRow(
                        'Profit',
                        state.weeklySummary!['totalProfit']!,
                        state.weeklySummary!['totalProfit']! >= 0
                            ? AppTheme.profitColor
                            : AppTheme.lossColor),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Chart
          Text(
            'Weekly Trend',
            style: AppTheme.headingSmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                 child: _buildBarChart(weeklySummaries, isWeekly: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyView(DashboardLoaded state) {
    final now = DateTime.now();
    final monthStart = Formatters.getMonthStart(now);
    final monthEnd = Formatters.getMonthEnd(now);

    final monthlySummaries = state.allSummaries.where((s) {
      final normalizedDate = Formatters.normalizeDate(s.date);
      final normalizedStart = Formatters.normalizeDate(monthStart);
      final normalizedEnd = Formatters.normalizeDate(monthEnd);
      return (normalizedDate.isAtSameMomentAs(normalizedStart) ||
              normalizedDate.isAfter(normalizedStart)) &&
          (normalizedDate.isAtSameMomentAs(normalizedEnd) ||
              normalizedDate.isBefore(normalizedEnd));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    Formatters.formatMonthYear(now),
                    style: AppTheme.headingSmall,
                  ),
                  const SizedBox(height: 16),
                  if (state.monthlySummary != null) ...[
                    _buildSummaryRow(
                        'Income',
                        state.monthlySummary!['totalIncome']!,
                        AppTheme.profitColor),
                    const Divider(height: 24),
                    _buildSummaryRow(
                        'Expense',
                        state.monthlySummary!['totalExpense']!,
                        AppTheme.lossColor),
                    const Divider(height: 24),
                    _buildSummaryRow(
                        'Profit',
                        state.monthlySummary!['totalProfit']!,
                        state.monthlySummary!['totalProfit']! >= 0
                            ? AppTheme.profitColor
                            : AppTheme.lossColor),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

           // Chart
           Text(
             'Monthly Trend',
             style: AppTheme.headingSmall,
           ),
           const SizedBox(height: 16),
           SizedBox(
             height: 300,
             child: Card(
               child: Padding(
                 padding: const EdgeInsets.all(16),
                 child: _buildBarChart(monthlySummaries),
               ),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500),
        ),
        Text(
          Formatters.formatCurrency(value),
          style: AppTheme.headingSmall.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildBarChart(List summaries, {bool isWeekly = false}) {
    if (summaries.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Calculate max value for Y-axis
    double maxValue = 0.0;
    for (var summary in summaries) {
      if (summary.totalIncome > maxValue) maxValue = summary.totalIncome;
      if (summary.totalExpense > maxValue) maxValue = summary.totalExpense;
    }
    final double maxY = maxValue > 0 ? maxValue * 1.2 : 100.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
               getTitlesWidget: (value, meta) {
                 if (value.toInt() >= 0 && value.toInt() < summaries.length) {
                   return Text(
                     isWeekly
                         ? Formatters.formatDayOfWeek(summaries[value.toInt()].date)
                         : '${summaries[value.toInt()].date.day}',
                     style: AppTheme.bodySmall,
                   );
                 }
                 return const Text('');
               },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(summaries.length, (index) {
          final summary = summaries[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: summary.totalIncome,
                color: AppTheme.profitColor,
                width: 12,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: summary.totalExpense,
                color: AppTheme.lossColor,
                width: 12,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }


}
