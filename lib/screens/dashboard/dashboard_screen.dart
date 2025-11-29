import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../blocs/income/income_bloc.dart';
import '../../blocs/income/income_event.dart';
import '../../blocs/expense/expense_bloc.dart';
import '../../blocs/expense/expense_event.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/translations.dart';
import '../../services/language_service.dart';
import '../../widgets/calculator_widget.dart';
import '../../widgets/smart_insights_widget.dart';
import '../widgets/best_profit_card.dart';
import '../../services/notification_service.dart';
import '../../services/share_service.dart';
import '../../services/undo_service.dart';
import 'add_income_screen.dart';
import 'add_expense_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isNotificationEnabled = false;
  bool _hasUndo = false;
  String _undoMessage = '';

  String get _lang => LanguageService.getLanguageCode();

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const LoadDashboardData());
    _initializeServices();
    _checkUndoAvailability();
  }

  Future<void> _initializeServices() async {
    final notificationService = NotificationService();
    await notificationService.initialize();
    final enabled = await notificationService.isDailyReminderEnabled();
    if (mounted) {
      setState(() => _isNotificationEnabled = enabled);
    }
  }

  Future<void> _checkUndoAvailability() async {
    final hasUndo = await UndoService.hasValidUndo();
    final message = await UndoService.getUndoMessage();
    if (mounted) {
      setState(() {
        _hasUndo = hasUndo;
        _undoMessage = message;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final notificationService = NotificationService();
    if (value) {
      await notificationService.scheduleDailyReminder();
    } else {
      await notificationService.cancelDailyReminder();
    }
    setState(() => _isNotificationEnabled = value);
  }

  Future<void> _handleUndo() async {
    final undoEntry = await UndoService.getLastUndoEntry();
    if (undoEntry == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.get(
          {'en': 'Undo Last Entry', 'ml': 'അവസാന എൻട്രി പഴയപടിയാക്കുക'},
          _lang,
        )),
        content: Text(_undoMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppTranslations.get(AppTranslations.cancel, _lang)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppTranslations.get(
              {'en': 'Undo', 'ml': 'പഴയപടിയാക്കുക'},
              _lang,
            )),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (undoEntry.type == EntryType.income) {
        context.read<IncomeBloc>().add(DeleteIncome(undoEntry.id));
      } else {
        context.read<ExpenseBloc>().add(DeleteExpense(undoEntry.id));
      }
      await UndoService.clearUndo();
      await _checkUndoAvailability();
      context.read<DashboardBloc>().add(const RefreshDashboardData());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.get(
              {
                'en': 'Entry removed successfully',
                'ml': 'എൻട്രി വിജയകരമായി നീക്കം ചെയ്തു'
              },
              _lang,
            )),
          ),
        );
      }
    }
  }

  Future<void> _shareToday() async {
    await ShareService.shareDailySummary(
      date: DateTime.now(),
    );
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
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.food_bank, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.get(
                    _lang == 'ml'
                        ? {'en': 'Hotel Expense', 'ml': 'ഹോട്ടൽ ചെലവ്'}
                        : {'en': 'Hotel Expense', 'ml': 'ഹോട്ടൽ ചെലവ്'},
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
          // Share Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.share, size: 20),
            ),
            onPressed: _shareToday,
            tooltip: 'Share Today\'s Summary',
          ),
          // Notification Toggle
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isNotificationEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                size: 20,
              ),
            ),
            onPressed: () => _toggleNotifications(!_isNotificationEnabled),
            tooltip: _isNotificationEnabled
                ? 'Disable Daily Reminder'
                : 'Enable Daily Reminder (9 PM)',
          ),
          // Refresh Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.refresh, size: 20),
            ),
            onPressed: () {
              context.read<DashboardBloc>().add(const RefreshDashboardData());
              _checkUndoAvailability();
            },
            tooltip: 'Refresh Data',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.lossColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading data',
                    style: AppTheme.headingSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<DashboardBloc>()
                          .add(const LoadDashboardData());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is DashboardLoaded) {
            return RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () async {
                context.read<DashboardBloc>().add(const RefreshDashboardData());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Gradient Section
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Summary Stats with improved design
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            child: _buildSummarySection(state),
                          ),
                        ],
                      ),
                    ),

                    // Main Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Actions - Moved to Top
                          _buildSectionHeader('Quick Actions', Icons.flash_on),
                          const SizedBox(height: 12),
                          _buildQuickActions(context),
                          const SizedBox(height: 24),

                          // Smart Insights
                          if (state.allSummaries.isNotEmpty) ...[
                            _buildSectionHeader(
                                'Smart Insights', Icons.lightbulb_outline),
                            const SizedBox(height: 12),
                            _buildSmartInsights(state),
                            const SizedBox(height: 24),
                          ],

                          // Best Profit Day
                          if (state.bestProfitDay != null) ...[
                            _buildSectionHeader(
                                'Best Performance', Icons.emoji_events),
                            const SizedBox(height: 12),
                            BestProfitCard(summary: state.bestProfitDay!),
                            const SizedBox(height: 24),
                          ],

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const Center(
            child: Text('ഡാറ്റ ലഭ്യമല്ല'),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Undo Button (if available)
          if (_hasUndo) ...[
            FloatingActionButton.extended(
              onPressed: _handleUndo,
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.undo, color: Colors.white),
              label: Text(
                AppTranslations.get(
                  {'en': 'Undo Last Entry', 'ml': 'അവസാന എൻട്രി പഴയപടിയാക്കുക'},
                  _lang,
                ),
                style: const TextStyle(color: Colors.white),
              ),
              heroTag: 'undo',
            ),
            const SizedBox(height: 12),
          ],
          // Calculator Button
          FloatingActionButton(
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => const CalculatorDialog(),
              );
            },
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.calculate, color: Colors.white),
            tooltip: AppTranslations.get(
              {'en': 'Calculator', 'ml': 'കാൽക്കുലേറ്റർ'},
              _lang,
            ),
            heroTag: 'calculator',
          ),
        ],
      ),
    );
  }

  Widget _buildSmartInsights(DashboardLoaded state) {
    if (state.allSummaries.length < 2) {
      return const SizedBox.shrink();
    }

    final today = DateTime.now();
    final todaySummary = state.allSummaries.firstWhere(
      (s) =>
          s.date.year == today.year &&
          s.date.month == today.month &&
          s.date.day == today.day,
      orElse: () => state.allSummaries.first,
    );

    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdaySummary = state.allSummaries.firstWhere(
      (s) =>
          s.date.year == yesterday.year &&
          s.date.month == yesterday.month &&
          s.date.day == yesterday.day,
      orElse: () => state.allSummaries.length > 1
          ? state.allSummaries[1]
          : state.allSummaries.first,
    );

    // Calculate weekly and monthly average
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    final weekSummaries =
        state.allSummaries.where((s) => s.date.isAfter(weekAgo)).toList();
    final monthSummaries =
        state.allSummaries.where((s) => s.date.isAfter(monthAgo)).toList();

    final weeklyAvg = weekSummaries.isEmpty
        ? 0.0
        : weekSummaries.map((s) => s.profit).reduce((a, b) => a + b) /
            weekSummaries.length;
    final monthlyAvg = monthSummaries.isEmpty
        ? 0.0
        : monthSummaries.map((s) => s.profit).reduce((a, b) => a + b) /
            monthSummaries.length;

    // Find consecutive profit days
    int consecutiveProfitDays = 0;
    for (final summary in state.allSummaries.reversed) {
      if (summary.profit > 0) {
        consecutiveProfitDays++;
      } else {
        break;
      }
    }

    return SmartInsightsWidget(
      todayIncome: todaySummary.totalIncome,
      todayExpense: todaySummary.totalExpense,
      yesterdayIncome: yesterdaySummary.totalIncome,
      yesterdayExpense: yesterdaySummary.totalExpense,
      weeklyAvgProfit: weeklyAvg,
      monthlyAvgProfit: monthlyAvg,
      topExpenseCategory: '', // TODO: Calculate from expense data
      topExpenseAmount: 0.0,
      consecutiveProfitDays: consecutiveProfitDays,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTheme.headingSmall.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(DashboardLoaded state) {
    return Column(
      children: [
        // Income and Expense Row
        Row(
          children: [
            Expanded(
              child: _buildModernStatCard(
                title: 'Income',
                value: Formatters.formatCurrency(state.totalIncome),
                icon: Icons.arrow_upward_rounded,
                gradient: AppTheme.profitGradient,
                trend: '+12.5%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernStatCard(
                title: 'Expense',
                value: Formatters.formatCurrency(state.totalExpense),
                icon: Icons.arrow_downward_rounded,
                gradient: AppTheme.lossGradient,
                trend: '+8.3%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Net Profit Card - Larger
        _buildProfitCard(state),
      ],
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
    String? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCard(DashboardLoaded state) {
    final isProfit = state.totalProfit >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient:
                  isProfit ? AppTheme.profitGradient : AppTheme.lossGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isProfit
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Profit',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(state.totalProfit),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isProfit ? AppTheme.profitColor : AppTheme.lossColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isProfit ? AppTheme.profitColor : AppTheme.lossColor)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isProfit ? '+15.2%' : '-8.5%',
              style: TextStyle(
                color: isProfit ? AppTheme.profitColor : AppTheme.lossColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            label: 'Add Income',
            icon: Icons.add_circle_rounded,
            gradient: AppTheme.profitGradient,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddIncomeScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            context,
            label: 'Add Expense',
            icon: Icons.remove_circle_rounded,
            gradient: AppTheme.lossGradient,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddExpenseScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
