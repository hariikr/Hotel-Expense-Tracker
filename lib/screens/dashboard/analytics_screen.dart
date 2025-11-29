import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../services/share_service.dart';

enum AnalyticsPeriod { week, month, quarter, year }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.month;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load weekly and monthly summaries
    final now = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<DashboardBloc>()
          .add(LoadWeeklySummary(Formatters.getWeekStart(now)));
      context
          .read<DashboardBloc>()
          .add(LoadMonthlySummary(now.year, now.month));
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.analytics, size: 24),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Period Selector
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AnalyticsPeriod>(
                value: _selectedPeriod,
                icon: const Icon(Icons.arrow_drop_down,
                    color: Colors.white, size: 20),
                dropdownColor: AppTheme.primaryColor,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                items: const [
                  DropdownMenuItem(
                    value: AnalyticsPeriod.week,
                    child: Text('Week'),
                  ),
                  DropdownMenuItem(
                    value: AnalyticsPeriod.month,
                    child: Text('Month'),
                  ),
                  DropdownMenuItem(
                    value: AnalyticsPeriod.quarter,
                    child: Text('Quarter'),
                  ),
                  DropdownMenuItem(
                    value: AnalyticsPeriod.year,
                    child: Text('Year'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPeriod = value;
                    });
                  }
                },
              ),
            ),
          ),
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareAnalytics,
            padding: const EdgeInsets.all(8),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.trending_up), text: 'Overview'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Trends'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Breakdown'),
          ],
        ),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(state),
                _buildTrendsTab(state),
                _buildBreakdownTab(state),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  // Overview Tab - Key metrics and summary
  Widget _buildOverviewTab(DashboardLoaded state) {
    final summaries = _getFilteredSummaries(state);
    final stats = _calculateStats(summaries);

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DashboardBloc>().add(LoadDashboardData());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Info Card
            _buildPeriodInfoCard(),
            const SizedBox(height: 16),

            // Key Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Income',
                    stats['totalIncome']!,
                    Icons.arrow_upward,
                    Colors.green,
                    stats['incomeTrend']!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Total Expense',
                    stats['totalExpense']!,
                    Icons.arrow_downward,
                    Colors.red,
                    stats['expenseTrend']!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    stats['totalProfit']! >= 0 ? 'Net Profit' : 'Net Loss',
                    stats['totalProfit']!.abs(),
                    stats['totalProfit']! >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    stats['totalProfit']! >= 0
                        ? AppTheme.profitColor
                        : AppTheme.lossColor,
                    stats['profitTrend']!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Avg Daily',
                    stats['avgDaily']!,
                    Icons.calendar_today,
                    AppTheme.primaryColor,
                    0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Performance Indicators
            Text(
              'Performance Indicators',
              style: AppTheme.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildPerformanceCard(
              'Success Rate',
              stats['successRate']!,
              Icons.check_circle,
              AppTheme.profitColor,
              isPercentage: true,
            ),
            const SizedBox(height: 12),

            _buildPerformanceCard(
              'Profitable Days',
              stats['profitableDays']!,
              Icons.wb_sunny,
              Colors.orange,
              total: stats['totalDays']!,
            ),
            const SizedBox(height: 12),

            _buildPerformanceCard(
              'Average Meals/Day',
              stats['avgMeals']!,
              Icons.restaurant,
              Colors.purple,
            ),

            const SizedBox(height: 24),

            // Quick Chart Preview
            Text(
              'Profit Trend Overview',
              style: AppTheme.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildMiniLineChart(summaries),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Trends Tab - Detailed charts
  Widget _buildTrendsTab(DashboardLoaded state) {
    final summaries = _getFilteredSummaries(state);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          _buildPeriodInfoCard(),
          const SizedBox(height: 16),

          // Profit/Loss Bar Chart
          Text(
            'Profit & Loss Trend',
            style: AppTheme.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildBarChart(summaries),
            ),
          ),

          const SizedBox(height: 24),

          // Income vs Expense Line Chart
          Text(
            'Income vs Expense',
            style: AppTheme.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildLineChart(summaries),
            ),
          ),
        ],
      ),
    );
  }

  // Breakdown Tab - Pie charts and detailed breakdown
  Widget _buildBreakdownTab(DashboardLoaded state) {
    final summaries = _getFilteredSummaries(state);
    final stats = _calculateStats(summaries);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Info
          _buildPeriodInfoCard(),
          const SizedBox(height: 16),

          // Profit Distribution Pie Chart
          Text(
            'Profit Distribution',
            style: AppTheme.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            height: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildPieChart(stats),
            ),
          ),

          const SizedBox(height: 24),

          // Detailed Breakdown List
          Text(
            'Detailed Breakdown',
            style: AppTheme.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildBreakdownList(summaries),

          const SizedBox(height: 24),

          // Top Days
          Text(
            'Top Performing Days',
            style: AppTheme.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildTopDaysList(summaries),
        ],
      ),
    );
  }

  // Helper Methods
  List _getFilteredSummaries(DashboardLoaded state) {
    final now = _selectedDate;
    DateTime start, end;

    switch (_selectedPeriod) {
      case AnalyticsPeriod.week:
        start = Formatters.getWeekStart(now);
        end = Formatters.getWeekEnd(now);
        break;
      case AnalyticsPeriod.month:
        start = Formatters.getMonthStart(now);
        end = Formatters.getMonthEnd(now);
        break;
      case AnalyticsPeriod.quarter:
        start = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        end = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 4, 0);
        break;
      case AnalyticsPeriod.year:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31);
        break;
    }

    return state.allSummaries.where((s) {
      final normalizedDate = Formatters.normalizeDate(s.date);
      final normalizedStart = Formatters.normalizeDate(start);
      final normalizedEnd = Formatters.normalizeDate(end);
      return (normalizedDate.isAtSameMomentAs(normalizedStart) ||
              normalizedDate.isAfter(normalizedStart)) &&
          (normalizedDate.isAtSameMomentAs(normalizedEnd) ||
              normalizedDate.isBefore(normalizedEnd));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Map<String, double> _calculateStats(List summaries) {
    double totalIncome = 0;
    double totalExpense = 0;
    double profitableDays = 0;
    double totalMeals = 0;

    for (var summary in summaries) {
      totalIncome += summary.totalIncome;
      totalExpense += summary.totalExpense;
      totalMeals += summary.mealsCount;
      if (summary.profit > 0) profitableDays++;
    }

    final totalProfit = totalIncome - totalExpense;
    final totalDays = summaries.length.toDouble();
    final successRate =
        (totalDays > 0 ? (profitableDays / totalDays) * 100 : 0.0).toDouble();
    final avgDaily = (totalDays > 0 ? totalProfit / totalDays : 0.0).toDouble();
    final avgMeals = (totalDays > 0 ? totalMeals / totalDays : 0.0).toDouble();

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'totalProfit': totalProfit,
      'profitableDays': profitableDays,
      'totalDays': totalDays,
      'successRate': successRate,
      'avgDaily': avgDaily,
      'avgMeals': avgMeals,
      'incomeTrend': 5.2, // Could calculate from previous period
      'expenseTrend': -3.1,
      'profitTrend': 8.5,
    };
  }

  Future<void> _shareAnalytics() async {
    final state = context.read<DashboardBloc>().state;
    if (state is DashboardLoaded) {
      final summaries = _getFilteredSummaries(state);
      final stats = _calculateStats(summaries);

      await ShareService.shareMonthlySummary(
        month: _getPeriodName(),
        totalIncome: stats['totalIncome']!,
        totalExpense: stats['totalExpense']!,
        totalMeals: stats['avgMeals']!.toInt(),
        profitableDays: stats['profitableDays']!.toInt(),
        totalDays: stats['totalDays']!.toInt(),
      );
    }
  }

  String _getPeriodName() {
    switch (_selectedPeriod) {
      case AnalyticsPeriod.week:
        return 'Week of ${Formatters.formatDate(Formatters.getWeekStart(_selectedDate))}';
      case AnalyticsPeriod.month:
        return Formatters.formatMonthYear(_selectedDate);
      case AnalyticsPeriod.quarter:
        final quarter = ((_selectedDate.month - 1) ~/ 3) + 1;
        return 'Q$quarter ${_selectedDate.year}';
      case AnalyticsPeriod.year:
        return '${_selectedDate.year}';
    }
  }

  Widget _buildPeriodInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Viewing Period',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getPeriodName(),
                  style: AppTheme.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                iconSize: 20,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    switch (_selectedPeriod) {
                      case AnalyticsPeriod.week:
                        _selectedDate =
                            _selectedDate.subtract(const Duration(days: 7));
                        break;
                      case AnalyticsPeriod.month:
                        _selectedDate = DateTime(
                            _selectedDate.year, _selectedDate.month - 1);
                        break;
                      case AnalyticsPeriod.quarter:
                        _selectedDate = DateTime(
                            _selectedDate.year, _selectedDate.month - 3);
                        break;
                      case AnalyticsPeriod.year:
                        _selectedDate = DateTime(
                            _selectedDate.year - 1, _selectedDate.month);
                        break;
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                iconSize: 20,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    switch (_selectedPeriod) {
                      case AnalyticsPeriod.week:
                        _selectedDate =
                            _selectedDate.add(const Duration(days: 7));
                        break;
                      case AnalyticsPeriod.month:
                        _selectedDate = DateTime(
                            _selectedDate.year, _selectedDate.month + 1);
                        break;
                      case AnalyticsPeriod.quarter:
                        _selectedDate = DateTime(
                            _selectedDate.year, _selectedDate.month + 3);
                        break;
                      case AnalyticsPeriod.year:
                        _selectedDate = DateTime(
                            _selectedDate.year + 1, _selectedDate.month);
                        break;
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String label, double value, IconData icon, Color color, double trend) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (trend != 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        trend > 0 ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: trend > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trend.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: trend > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.formatCurrency(value),
            style: AppTheme.headingSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(
      String label, double value, IconData icon, Color color,
      {bool isPercentage = false, double? total}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPercentage
                      ? '${value.toStringAsFixed(1)}%'
                      : total != null
                          ? '${value.toInt()} / ${total.toInt()}'
                          : value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (!isPercentage && total == null)
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildMiniLineChart(List summaries) {
    if (summaries.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              summaries.length,
              (index) => FlSpot(
                index.toDouble(),
                summaries[index].profit.toDouble(),
              ),
            ),
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List summaries) {
    if (summaries.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    double maxValue = 0;
    for (var s in summaries) {
      if (s.totalIncome > maxValue) maxValue = s.totalIncome;
      if (s.totalExpense > maxValue) maxValue = s.totalExpense;
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${(value / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < summaries.length) {
                  final s = summaries[value.toInt()];
                  return Text(
                    '${s.date.day}',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxValue * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              summaries.length,
              (index) => FlSpot(
                index.toDouble(),
                summaries[index].totalIncome.toDouble(),
              ),
            ),
            isCurved: true,
            color: AppTheme.profitColor,
            barWidth: 3,
            dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: AppTheme.profitColor,
                    strokeWidth: 0,
                  );
                }),
          ),
          LineChartBarData(
            spots: List.generate(
              summaries.length,
              (index) => FlSpot(
                index.toDouble(),
                summaries[index].totalExpense.toDouble(),
              ),
            ),
            isCurved: true,
            color: AppTheme.lossColor,
            barWidth: 3,
            dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: AppTheme.lossColor,
                    strokeWidth: 0,
                  );
                }),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> stats) {
    final totalIncome = stats['totalIncome']!;
    final totalExpense = stats['totalExpense']!;

    if (totalIncome == 0 && totalExpense == 0) {
      return const Center(child: Text('No data available'));
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  color: AppTheme.profitColor,
                  value: totalIncome,
                  title:
                      '${((totalIncome / (totalIncome + totalExpense)) * 100).toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: AppTheme.lossColor,
                  value: totalExpense,
                  title:
                      '${((totalExpense / (totalIncome + totalExpense)) * 100).toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Income', totalIncome, AppTheme.profitColor),
            const SizedBox(height: 12),
            _buildLegendItem('Expense', totalExpense, AppTheme.lossColor),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              Formatters.formatCurrency(value),
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBreakdownList(List summaries) {
    if (summaries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('No data available')),
      );
    }

    return Column(
      children: summaries.take(5).map<Widget>((summary) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: summary.profit >= 0
                  ? AppTheme.profitColor.withOpacity(0.2)
                  : AppTheme.lossColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (summary.profit >= 0
                          ? AppTheme.profitColor
                          : AppTheme.lossColor)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  summary.profit >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: summary.profit >= 0
                      ? AppTheme.profitColor
                      : AppTheme.lossColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.formatDateFull(summary.date),
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Meals: ${summary.mealsCount}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatCurrency(summary.profit.abs()),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: summary.profit >= 0
                          ? AppTheme.profitColor
                          : AppTheme.lossColor,
                    ),
                  ),
                  Text(
                    summary.profit >= 0 ? 'Profit' : 'Loss',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopDaysList(List summaries) {
    if (summaries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('No data available')),
      );
    }

    final sortedSummaries = List.from(summaries)
      ..sort((a, b) => b.profit.compareTo(a.profit));

    return Column(
      children: sortedSummaries.take(3).map<Widget>((summary) {
        final index = sortedSummaries.indexOf(summary);
        final medal = index == 0
            ? '🥇'
            : index == 1
                ? '🥈'
                : '🥉';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.profitColor.withOpacity(0.1),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.profitColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Text(
                medal,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.formatDateFull(summary.date),
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Income: ${Formatters.formatCurrency(summary.totalIncome)}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.profitColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Expense: ${Formatters.formatCurrency(summary.totalExpense)}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.lossColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.profitColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  Formatters.formatCurrency(summary.profit),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBarChart(List summaries, {bool isWeekly = false}) {
    if (summaries.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Calculate max absolute value for Y-axis to show both profit and loss
    double maxValue = 0.0;
    for (var summary in summaries) {
      final profit = summary.totalIncome - summary.totalExpense;
      maxValue = maxValue > profit.abs() ? maxValue : profit.abs();
    }
    final double maxY = maxValue > 0 ? maxValue * 1.2 : 100.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: -maxY, // Allow negative values for losses
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final summary = summaries[group.x];
              final profit = summary.totalIncome - summary.totalExpense;
              return BarTooltipItem(
                '${isWeekly ? Formatters.formatDayOfWeek(summary.date) : summary.date.day}\n'
                'Profit: ${Formatters.formatCurrency(profit)}',
                AppTheme.bodySmall.copyWith(
                  color:
                      profit >= 0 ? AppTheme.profitColor : AppTheme.lossColor,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < summaries.length) {
                  final day = summaries[value.toInt()];
                  final profit = day.totalIncome - day.totalExpense;
                  return Text(
                    isWeekly
                        ? '${Formatters.formatDayOfWeek(day.date)[0]}' // Use first letter
                        : '${day.date.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: profit >= 0
                          ? AppTheme.profitColor
                          : AppTheme.lossColor,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: false, // Remove gridlines for cleaner look
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: List.generate(summaries.length, (index) {
          final summary = summaries[index];
          final profit = summary.totalIncome - summary.totalExpense;
          final color = profit >= 0 ? AppTheme.profitColor : AppTheme.lossColor;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY:
                    profit, // Show profit directly instead of income/expense separately
                color: color,
                width: 20, // Wider bars for better visibility
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                  bottom: Radius.circular(4),
                ),
                borderSide: const BorderSide(
                  color: Colors.white,
                  width: 1,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
