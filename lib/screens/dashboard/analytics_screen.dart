import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/transactions/cubits/transaction_cubit.dart';
import '../../features/transactions/models/expense_model.dart';
import '../../features/transactions/models/income_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../services/export_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    DateTime start, end;

    switch (_selectedPeriod) {
      case 'This Week':
        start = now.subtract(Duration(days: now.weekday - 1));
        end = now;
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31);
        break;
      default:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
    }

    await context.read<TransactionCubit>().loadTransactionsRange(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        title: const Text(
          'Analytics & Insights',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _showExportDialog(context),
            tooltip: 'Export Data',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TransactionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is TransactionLoaded) {
            return RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Selector
                    _buildPeriodSelector(),

                    const SizedBox(height: 16),

                    // Overview Cards
                    _buildOverviewCards(state),

                    const SizedBox(height: 24),

                    // Best Profit Day & Key Stats
                    _buildKeyInsights(state),

                    const SizedBox(height: 24),

                    // Expense by Category
                    _buildCategoryBreakdown(
                        state.expenses, 'Expense Breakdown'),

                    const SizedBox(height: 24),

                    // Income by Category
                    _buildCategoryBreakdown(state.incomes, 'Income Breakdown',
                        isExpense: false),

                    const SizedBox(height: 24),

                    // Trends
                    _buildTrends(state),

                    const SizedBox(height: 24),

                    // Top Expenses
                    _buildTopTransactions(state.expenses, 'Top Expenses',
                        isExpense: true),

                    const SizedBox(height: 24),

                    // Top Incomes
                    _buildTopTransactions(state.incomes, 'Top Incomes',
                        isExpense: false),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            );
          }

          return const Center(child: Text('No Data Available'));
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          const Text(
            'Period:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  isExpanded: true,
                  items: ['This Week', 'This Month', 'This Year']
                      .map((period) => DropdownMenuItem(
                            value: period,
                            child: Text(period),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPeriod = value;
                      });
                      _loadData();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(TransactionLoaded state) {
    final savingsRate = state.totalIncome > 0
        ? ((state.profit / state.totalIncome) * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Income',
                  '₹${state.totalIncome.toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.green,
                  '+${state.incomes.length} transactions',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Expense',
                  '₹${state.totalExpense.toStringAsFixed(0)}',
                  Icons.trending_down,
                  Colors.red,
                  '-${state.expenses.length} transactions',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            state.profit >= 0 ? 'Net Profit' : 'Net Loss',
            '₹${state.profit.abs().toStringAsFixed(0)}',
            state.profit >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
            state.profit >= 0 ? Colors.green : Colors.red,
            state.profit >= 0
                ? 'Savings Rate: $savingsRate%'
                : 'Overspending: ${savingsRate.replaceAll('-', '')}%',
            isWide: true,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyInsights(TransactionLoaded state) {
    // Calculate daily profits/losses
    final Map<DateTime, double> dailyProfits = {};
    final Map<DateTime, double> dailyExpenses = {};
    final Map<DateTime, double> dailyIncomes = {};

    for (var expense in state.expenses) {
      final date = Formatters.normalizeDate(expense.date);
      dailyExpenses[date] = (dailyExpenses[date] ?? 0) + expense.amount;
    }

    for (var income in state.incomes) {
      final date = Formatters.normalizeDate(income.date);
      dailyIncomes[date] = (dailyIncomes[date] ?? 0) + income.amount;
    }

    // Calculate profit for each day
    final allDates = {...dailyExpenses.keys, ...dailyIncomes.keys};
    for (var date in allDates) {
      final income = dailyIncomes[date] ?? 0;
      final expense = dailyExpenses[date] ?? 0;
      dailyProfits[date] = income - expense;
    }

    // Find best and worst days
    DateTime? bestDay;
    double bestProfit = double.negativeInfinity;
    DateTime? worstDay;
    double worstProfit = double.infinity;
    int profitDays = 0;
    int lossDays = 0;

    dailyProfits.forEach((date, profit) {
      if (profit > bestProfit) {
        bestProfit = profit;
        bestDay = date;
      }
      if (profit < worstProfit) {
        worstProfit = profit;
        worstDay = date;
      }
      if (profit > 0) profitDays++;
      if (profit < 0) lossDays++;
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Key Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Best Profit Day
          if (bestDay != null && bestProfit > 0)
            _buildInsightRow(
              Icons.celebration,
              'Best Profit Day',
              Formatters.formatDateFull(bestDay!),
              '₹${bestProfit.toStringAsFixed(0)}',
              Colors.green,
            ),

          if (bestDay != null && bestProfit > 0) const SizedBox(height: 12),

          // Worst Loss Day
          if (worstDay != null && worstProfit < 0)
            _buildInsightRow(
              Icons.warning_amber,
              'Highest Loss Day',
              Formatters.formatDateFull(worstDay!),
              '₹${worstProfit.abs().toStringAsFixed(0)}',
              Colors.red,
            ),

          if (worstDay != null && worstProfit < 0) const SizedBox(height: 12),

          // Profit vs Loss Days
          Row(
            children: [
              Expanded(
                child: _buildMiniCard(
                  'Profit Days',
                  profitDays.toString(),
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniCard(
                  'Loss Days',
                  lossDays.toString(),
                  Icons.trending_down,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Transaction Count
          Row(
            children: [
              Expanded(
                child: _buildMiniCard(
                  'Total Transactions',
                  '${state.expenses.length + state.incomes.length}',
                  Icons.receipt_long,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniCard(
                  'Active Days',
                  dailyProfits.length.toString(),
                  Icons.calendar_today,
                  AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
    IconData icon,
    String label,
    String detail,
    String amount,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String subtitle, {
    bool isWide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isWide ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(List<dynamic> transactions, String title,
      {bool isExpense = true}) {
    if (transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group by category
    final Map<String, double> categoryTotals = {};
    for (var transaction in transactions) {
      final category = isExpense
          ? (transaction as ExpenseModel).categoryName ?? 'Other'
          : (transaction as IncomeModel).categoryName ?? 'Other';
      final amount = transaction.amount;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }

    final total = categoryTotals.values.fold(0.0, (sum, val) => sum + val);

    // Sort by amount
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
              Icon(
                Icons.pie_chart_rounded,
                color: isExpense ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Pie Chart Visualization
          _buildPieChart(sortedCategories, total, isExpense),
          const SizedBox(height: 20),
          // Category List
          ...sortedCategories.take(5).map((entry) {
            final percentage = (entry.value / total * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(
                                    sortedCategories.indexOf(entry), isExpense),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${entry.value.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isExpense ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.value / total,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getCategoryColor(
                                  sortedCategories.indexOf(entry), isExpense),
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPieChart(
      List<MapEntry<String, double>> categories, double total, bool isExpense) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          // Pie Chart
          Expanded(
            flex: 3,
            child: CustomPaint(
              size: const Size(200, 200),
              painter: PieChartPainter(
                categories: categories.take(5).toList(),
                total: total,
                isExpense: isExpense,
              ),
            ),
          ),
          // Legend
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: categories.take(5).map((entry) {
                final index = categories.indexOf(entry);
                final percentage =
                    (entry.value / total * 100).toStringAsFixed(0);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(index, isExpense),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${entry.key}\n$percentage%',
                          style: const TextStyle(fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(int index, bool isExpense) {
    final expenseColors = [
      Colors.red.shade400,
      Colors.orange.shade400,
      Colors.deepOrange.shade400,
      Colors.pink.shade400,
      Colors.red.shade300,
    ];
    final incomeColors = [
      Colors.green.shade400,
      Colors.teal.shade400,
      Colors.lightGreen.shade400,
      Colors.green.shade300,
      const Color(0xFF50C878), // Emerald
    ];
    final colors = isExpense ? expenseColors : incomeColors;
    return colors[index % colors.length];
  }

  Widget _buildTrends(TransactionLoaded state) {
    // Group by date
    final Map<DateTime, double> dailyExpenses = {};
    final Map<DateTime, double> dailyIncomes = {};

    for (var expense in state.expenses) {
      final date = Formatters.normalizeDate(expense.date);
      dailyExpenses[date] = (dailyExpenses[date] ?? 0) + expense.amount;
    }

    for (var income in state.incomes) {
      final date = Formatters.normalizeDate(income.date);
      dailyIncomes[date] = (dailyIncomes[date] ?? 0) + income.amount;
    }

    final avgDailyExpense = dailyExpenses.values.isEmpty
        ? 0.0
        : dailyExpenses.values.reduce((a, b) => a + b) / dailyExpenses.length;

    final avgDailyIncome = dailyIncomes.values.isEmpty
        ? 0.0
        : dailyIncomes.values.reduce((a, b) => a + b) / dailyIncomes.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          const Row(
            children: [
              Icon(Icons.show_chart, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Trends & Averages',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bar Chart Visualization
          _buildBarChart(avgDailyIncome, avgDailyExpense, state.totalIncome,
              state.totalExpense),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTrendItem(
                  'Avg. Daily Income',
                  '₹${avgDailyIncome.toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTrendItem(
                  'Avg. Daily Expense',
                  '₹${avgDailyExpense.toStringAsFixed(0)}',
                  Icons.trending_down,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTrendItem(
            (avgDailyIncome - avgDailyExpense) >= 0
                ? 'Avg. Daily Profit'
                : 'Avg. Daily Loss',
            '₹${(avgDailyIncome - avgDailyExpense).abs().toStringAsFixed(0)}',
            (avgDailyIncome - avgDailyExpense) >= 0
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            (avgDailyIncome - avgDailyExpense) >= 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(double avgIncome, double avgExpense, double totalIncome,
      double totalExpense) {
    final maxValue = [
      avgIncome,
      avgExpense,
      totalIncome / 30,
      totalExpense / 30
    ].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Daily Comparison',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBar(
                  'Avg\nIncome',
                  avgIncome,
                  maxValue,
                  Colors.green,
                ),
                _buildBar(
                  'Avg\nExpense',
                  avgExpense,
                  maxValue,
                  Colors.red,
                ),
                _buildBar(
                  'Total\nIncome',
                  totalIncome,
                  maxValue * 30,
                  Colors.green.shade300,
                ),
                _buildBar(
                  'Total\nExpense',
                  totalExpense,
                  maxValue * 30,
                  Colors.red.shade300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double value, double maxValue, Color color) {
    final height = maxValue > 0 ? (value / maxValue) * 90 : 0.0;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (value > 0)
              Flexible(
                child: Text(
                  '₹${value > 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              height: height.clamp(10, 90),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTransactions(List<dynamic> transactions, String title,
      {required bool isExpense}) {
    if (transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedTransactions = List.from(transactions)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final topTransactions = sortedTransactions.take(5).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
              Icon(
                Icons.star,
                color: isExpense ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topTransactions.map((transaction) {
            final category = isExpense
                ? (transaction as ExpenseModel).categoryName ?? 'Other'
                : (transaction as IncomeModel).categoryName ?? 'Other';
            final amount = transaction.amount;
            final date = transaction.date;
            final description = isExpense
                ? (transaction as ExpenseModel).description
                : (transaction as IncomeModel).description;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isExpense
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    child: Icon(
                      isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isExpense ? Colors.red : Colors.green,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (description != null && description.isNotEmpty)
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          Formatters.formatDateShort(date),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isExpense ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    final state = context.read<TransactionCubit>().state;
    if (state is! TransactionLoaded) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.table_chart, color: AppTheme.primaryColor),
              title: const Text('Export CSV'),
              subtitle: const Text('Export transactions as CSV file'),
              onTap: () async {
                Navigator.pop(dialogContext);
                await _exportCSV(context, state);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.summarize, color: AppTheme.primaryColor),
              title: const Text('Export Summary'),
              subtitle: const Text('Export summary report as text'),
              onTap: () async {
                Navigator.pop(dialogContext);
                await _exportSummary(context, state);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCSV(BuildContext context, TransactionLoaded state) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final dates = _getDateRange();
      await ExportService.exportToCSV(
        expenses: state.expenses,
        incomes: state.incomes,
        startDate: dates.$1,
        endDate: dates.$2,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportSummary(
      BuildContext context, TransactionLoaded state) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final dates = _getDateRange();
      final totalIncome =
          state.incomes.fold(0.0, (sum, income) => sum + income.amount);
      final totalExpense =
          state.expenses.fold(0.0, (sum, expense) => sum + expense.amount);
      final profit = totalIncome - totalExpense;

      // Group by category
      final expenseByCategory = <String, double>{};
      for (var expense in state.expenses) {
        final category = expense.categoryName ?? 'Unknown';
        expenseByCategory[category] =
            (expenseByCategory[category] ?? 0) + expense.amount;
      }

      final incomeByCategory = <String, double>{};
      for (var income in state.incomes) {
        final category = income.categoryName ?? 'Unknown';
        incomeByCategory[category] =
            (incomeByCategory[category] ?? 0) + income.amount;
      }

      await ExportService.exportSummaryReport(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        profit: profit,
        startDate: dates.$1,
        endDate: dates.$2,
        expenseByCategory: expenseByCategory,
        incomeByCategory: incomeByCategory,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Summary exported successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  (DateTime, DateTime) _getDateRange() {
    final now = DateTime.now();
    DateTime start, end;

    switch (_selectedPeriod) {
      case 'This Week':
        start = now.subtract(Duration(days: now.weekday - 1));
        end = now;
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31);
        break;
      default:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
    }

    return (start, end);
  }
}

// Custom Pie Chart Painter
class PieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> categories;
  final double total;
  final bool isExpense;

  PieChartPainter({
    required this.categories,
    required this.total,
    required this.isExpense,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 2 : size.height / 2;
    double startAngle = -90 * (3.14159 / 180); // Start from top

    for (int i = 0; i < categories.length; i++) {
      final entry = categories[i];
      final sweepAngle = (entry.value / total) * 2 * 3.14159;

      final paint = Paint()
        ..color = _getColor(i)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.85),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Add shadow/depth
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.85),
        startAngle,
        sweepAngle,
        true,
        shadowPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle (donut effect)
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, centerPaint);

    // Draw total in center
    final textPainter = TextPainter(
      text: TextSpan(
        text: '₹${(total / 1000).toStringAsFixed(1)}k',
        style: TextStyle(
          color: isExpense ? Colors.red : Colors.green,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  Color _getColor(int index) {
    final expenseColors = [
      Colors.red.shade400,
      Colors.orange.shade400,
      Colors.deepOrange.shade400,
      Colors.pink.shade400,
      Colors.red.shade300,
    ];
    final incomeColors = [
      Colors.green.shade400,
      Colors.teal.shade400,
      Colors.lightGreen.shade400,
      Colors.green.shade300,
      const Color(0xFF50C878), // Emerald
    ];
    final colors = isExpense ? expenseColors : incomeColors;
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
