import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../widgets/stat_card.dart';
import '../widgets/best_profit_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/context_selector.dart';
import 'add_income_screen.dart';
import 'add_expense_screen.dart';
import 'calendar_screen.dart';
import 'analytics_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const LoadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            final contextType = state is DashboardLoaded ? state.selectedContext : 'hotel';
            return Text(
              '${contextType.toUpperCase()} EXPENSE TRACKER',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        titleSpacing: 16,
        actions: [
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoaded) {
                return ContextSelector(
                  selectedContext: state.selectedContext,
                  onContextChanged: (newContext) {
                    context.read<DashboardBloc>().add(ChangeContext(newContext));
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardBloc>().add(const RefreshDashboardData());
            },
          ),
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
              onRefresh: () async {
                context.read<DashboardBloc>().add(const RefreshDashboardData());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Stats
                    _buildSummarySection(state),
                    const SizedBox(height: 24),

                    // Best Profit Day - Only show for Hotel context
                    if (state.bestProfitDay != null && state.selectedContext != 'house') ...[
                      Text(
                        'BEST PERFORMANCE',
                        style: AppTheme.headingSmall.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      BestProfitCard(summary: state.bestProfitDay!),
                      const SizedBox(height: 24),
                    ],

                    // Quick Actions
                    Text(
                      'QUICK ACTIONS',
                      style: AppTheme.headingSmall.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),

                    // Navigation Cards
                    Text(
                      'NAVIGATE',
                      style: AppTheme.headingSmall.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNavigationCards(context),
                  ],
                ),
              ),
            );
          }

          return const Center(
            child: Text('No data available'),
          );
        },
      ),
    );
  }

  Widget _buildSummarySection(DashboardLoaded state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: state.selectedContext == 'house' ? 'Income from Hotel' : 'Total Income',
                value: Formatters.formatCurrency(state.totalIncome),
                icon: Icons.trending_up,
                color: AppTheme.profitColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Total Expense',
                value: Formatters.formatCurrency(state.totalExpense),
                icon: Icons.trending_down,
                color: AppTheme.lossColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatCard(
          title: 'Net Profit',
          value: Formatters.formatCurrency(state.totalProfit),
          icon: state.totalProfit >= 0
              ? Icons.arrow_upward
              : Icons.arrow_downward,
          color: state.totalProfit >= 0
              ? AppTheme.profitColor
              : AppTheme.lossColor,
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoaded) {
          final isHotel = state.selectedContext == 'hotel';
          final shouldShowQuickActions = state.selectedContext != 'house';
          
          if (!shouldShowQuickActions) {
            return const SizedBox.shrink(); // Don't show quick actions in house context
          }
          
          return Row(
            children: [
              if (isHotel) ...[
                Expanded(
                  child: QuickActionButton(
                    label: 'Add Income',
                    icon: Icons.add_circle_outline,
                    color: AppTheme.profitColor,
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
              ],
              Expanded(
                child: QuickActionButton(
                  label: 'Add Expense',
                  icon: Icons.remove_circle_outline,
                  color: AppTheme.lossColor,
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
        return const SizedBox.shrink(); // Don't show quick actions if state is not loaded
      },
    );
  }

  Widget _buildNavigationCards(BuildContext context) {
    final currentState = context.read<DashboardBloc>().state;
    final shouldShowAnalytics = currentState is DashboardLoaded 
        ? currentState.selectedContext != 'house' 
        : true; // Show analytics by default if state is not loaded yet
    
    return Column(
      children: [
        _buildNavigationCard(
          context,
          title: 'Calendar View',
          subtitle: 'View daily profits and meals',
          icon: Icons.calendar_month,
          color: AppTheme.primaryColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CalendarScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        if (shouldShowAnalytics) ...[
          _buildNavigationCard(
            context,
            title: 'Analytics',
            subtitle: 'View charts and trends',
            icon: Icons.bar_chart,
            color: AppTheme.accentColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsScreen(),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.headingSmall.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
