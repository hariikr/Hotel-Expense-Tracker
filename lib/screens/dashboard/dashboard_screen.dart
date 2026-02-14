import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/transactions/cubits/transaction_cubit.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../utils/app_theme.dart';
import '../../utils/translations.dart';
import '../../services/language_service.dart';
import '../../services/share_service.dart';
import '../../services/smart_insights_service.dart';
import 'add_income_screen.dart';
import 'add_expense_screen.dart';
import '../settings/manage_categories_screen.dart';
import '../ai/ai_chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  String get _lang => LanguageService.getLanguageCode();
  final SmartInsightsService _insightsService = SmartInsightsService();
  SmartInsightsResponse? _smartInsights;
  bool _isLoadingInsights = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    await context.read<TransactionCubit>().loadTransactions(DateTime.now());
    await _loadSmartInsights();
  }

  Future<void> _loadSmartInsights() async {
    setState(() => _isLoadingInsights = true);
    try {
      final authState = context.read<AuthBloc>().state;
      final userId = authState is Authenticated ? authState.user.id : null;

      // Don't load insights if user is not authenticated
      if (userId == null) {
        if (mounted) {
          setState(() => _isLoadingInsights = false);
        }
        return;
      }

      final insights = await _insightsService.getSmartInsights(
        userId: userId,
        period: 'week',
      );
      print('✅ Insights loaded: ${insights.insights.length} insights');
      print(
          '✅ First insight: ${insights.insights.isNotEmpty ? insights.insights.first.title : "none"}');
      if (mounted) {
        setState(() {
          _smartInsights = insights;
          _isLoadingInsights = false;
        });
      }
    } catch (e) {
      print('❌ Error loading insights: $e');
      if (mounted) {
        setState(() => _isLoadingInsights = false);
      }
    }
  }

  Future<void> _shareToday(TransactionLoaded state) async {
    await ShareService.shareDailySummary(
      date: state.selectedDate,
      expenses: state.expenses,
      incomes: state.incomes,
    );
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.account_balance_wallet, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.get(
                    {'en': 'Expense Tracker', 'ml': 'ചെലവ് ട്രാക്കർ'},
                    _lang,
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  AppTranslations.get(AppTranslations.dashboard, _lang),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, state) {
              if (state is TransactionLoaded) {
                return IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  onPressed: () => _shareToday(state),
                  tooltip: 'Share',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(),
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
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
                    // Financial Overview
                    _buildFinancialOverview(state),

                    const SizedBox(height: 16),

                    // Quick Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildQuickActions(context),
                    ),

                    const SizedBox(height: 24),

                    // Smart Insights
                    if (_isLoadingInsights)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading AI Insights...'),
                            ],
                          ),
                        ),
                      )
                    else if (_smartInsights != null &&
                        _smartInsights!.insights.isNotEmpty)
                      _buildSmartInsights()
                    else
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.orange),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'No insights available. Add more transactions to get AI-powered insights.',
                                style: TextStyle(color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Category Statistics
                    _buildCategoryStats(state),

                    const SizedBox(height: 24),

                    // Recent Transactions
                    _buildRecentTransactions(state),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          }

          return const Center(child: Text('No Data'));
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person,
                      color: AppTheme.primaryColor, size: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Expense Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Track. Analyze. Save.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.category, color: AppTheme.primaryColor),
            title: const Text('Manage Categories'),
            subtitle: const Text('Add or edit categories'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageCategoriesScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.chat_bubble, color: AppTheme.secondaryColor),
            title: const Text('AI Assistant'),
            subtitle: const Text('Chat with your financial advisor'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'AI',
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiChatScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<AuthBloc>().add(AuthSignOutRequested());
                      },
                      child: const Text('Logout',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialOverview(TransactionLoaded state) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // === TODAY'S SUMMARY ===
          Row(
            children: [
              const Icon(Icons.today, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text(
                "Today's Summary",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Daily Income & Expense
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Income',
                  '₹${state.dailyIncome.toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Expense',
                  '₹${state.dailyExpense.toStringAsFixed(0)}',
                  Icons.trending_down,
                  Colors.redAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Profit',
                  '₹${state.dailyProfit.toStringAsFixed(0)}',
                  state.dailyProfit >= 0
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  state.dailyProfit >= 0
                      ? Colors.greenAccent
                      : Colors.redAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Divider
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.2),
          ),

          const SizedBox(height: 20),

          // === ALL-TIME TOTAL ===
          Row(
            children: [
              const Icon(Icons.account_balance,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Overall Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total Income & Expense
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Income',
                  '₹${state.allTimeTotalIncome.toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Expense',
                  '₹${state.allTimeTotalExpense.toStringAsFixed(0)}',
                  Icons.trending_down,
                  Colors.redAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Profit',
                  '₹${state.allTimeProfit.toStringAsFixed(0)}',
                  state.allTimeProfit >= 0
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  state.allTimeProfit >= 0
                      ? Colors.greenAccent
                      : Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddIncomeScreen()),
                  ).then((_) => _loadData());
                },
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Add Income'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.profitColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddExpenseScreen()),
                  ).then((_) => _loadData());
                },
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                label: const Text('Add Expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lossColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // AI Assistant Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiChatScreen(),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome, size: 20),
            label: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Ask AI Assistant'),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryStats(TransactionLoaded state) {
    if (state.expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group expenses by category
    final Map<String, double> categoryTotals = {};
    for (var expense in state.expenses) {
      final category = expense.categoryName ?? 'Other';
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + expense.amount;
    }

    // Sort by amount
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = sortedCategories.take(5).toList();

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
              Icon(Icons.pie_chart, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Top Expense Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topCategories.map((entry) {
            final percentage =
                (entry.value / state.totalExpense * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '₹${entry.value.toStringAsFixed(0)} ($percentage%)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: entry.value / state.totalExpense,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor.withOpacity(0.7),
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSmartInsights() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
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
                  Icons.auto_awesome,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Smart Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _loadSmartInsights,
                icon: _isLoadingInsights
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._smartInsights!.insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildInsightCard(insight),
              )),
        ],
      ),
    );
  }

  Widget _buildInsightCard(SmartInsight insight) {
    Color getColor() {
      switch (insight.type) {
        case 'profit':
          return AppTheme.profitColor;
        case 'expense':
        case 'warning':
          return AppTheme.lossColor;
        case 'income':
          return AppTheme.secondaryColor;
        case 'suggestion':
          return AppTheme.accentColor;
        default:
          return AppTheme.primaryColor;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight.icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: getColor(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(TransactionLoaded state) {
    final recentExpenses = state.expenses.take(3).toList();
    final recentIncomes = state.incomes.take(3).toList();

    if (recentExpenses.isEmpty && recentIncomes.isEmpty) {
      return const SizedBox.shrink();
    }

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
              Icon(Icons.history, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recentExpenses.map((expense) => _buildTransactionTile(
                expense.categoryName ?? 'Expense',
                expense.amount,
                isExpense: true,
              )),
          ...recentIncomes.map((income) => _buildTransactionTile(
                income.categoryName ?? 'Income',
                income.amount,
                isExpense: false,
              )),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(String title, double amount,
      {required bool isExpense}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isExpense
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        child: Icon(
          isExpense ? Icons.arrow_upward : Icons.arrow_downward,
          color: isExpense ? Colors.red : Colors.green,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: Text(
        '${isExpense ? '-' : '+'}₹${amount.toStringAsFixed(0)}',
        style: TextStyle(
          color: isExpense ? Colors.red : Colors.green,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
}
