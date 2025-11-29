import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/translation_helper.dart';
import '../services/language_service.dart';

class SmartInsightsWidget extends StatelessWidget {
  final double todayIncome;
  final double todayExpense;
  final double yesterdayIncome;
  final double yesterdayExpense;
  final double weeklyAvgProfit;
  final double monthlyAvgProfit;
  final String topExpenseCategory;
  final double topExpenseAmount;
  final int consecutiveProfitDays;

  const SmartInsightsWidget({
    super.key,
    required this.todayIncome,
    required this.todayExpense,
    required this.yesterdayIncome,
    required this.yesterdayExpense,
    required this.weeklyAvgProfit,
    required this.monthlyAvgProfit,
    required this.topExpenseCategory,
    required this.topExpenseAmount,
    this.consecutiveProfitDays = 0,
  });

  String get _lang => LanguageService.getLanguageCode();

  @override
  Widget build(BuildContext context) {
    final todayProfit = todayIncome - todayExpense;
    final yesterdayProfit = yesterdayIncome - yesterdayExpense;
    final profitChange = todayProfit - yesterdayProfit;
    final profitChangePercent =
        yesterdayProfit != 0 ? (profitChange / yesterdayProfit * 100) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  T.get(T.smartInsights, _lang),
                  style: AppTheme.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Compared to Yesterday
            _buildInsightCard(
              icon: Icons.trending_up,
              title: T.get(T.comparedToYesterday, _lang),
              content: _getComparisonText(profitChange, profitChangePercent),
              color:
                  profitChange >= 0 ? AppTheme.profitColor : AppTheme.lossColor,
            ),
            const SizedBox(height: 12),

            // Weekly Average
            _buildInsightCard(
              icon: Icons.calendar_view_week,
              title: T.get(T.weeklyPerformance, _lang),
              content:
                  '${T.get(T.avgDailyProfit, _lang)}: ${Formatters.formatCurrency(weeklyAvgProfit)}',
              color: weeklyAvgProfit >= 0
                  ? AppTheme.profitColor
                  : AppTheme.lossColor,
            ),
            const SizedBox(height: 12),

            // Top Expense
            if (topExpenseCategory.isNotEmpty)
              _buildInsightCard(
                icon: Icons.shopping_cart,
                title: T.get(T.highestExpense, _lang),
                content:
                    '$topExpenseCategory: ${Formatters.formatCurrency(topExpenseAmount)}',
                color: Colors.orange,
              ),
            if (topExpenseCategory.isNotEmpty) const SizedBox(height: 12),

            // Streak
            if (consecutiveProfitDays > 0)
              _buildInsightCard(
                icon: Icons.local_fire_department,
                title: T.get(T.profitStreak, _lang),
                content: _getProfitStreakText(consecutiveProfitDays),
                color: Colors.green,
              ),
            if (consecutiveProfitDays > 0) const SizedBox(height: 12),

            // Prediction
            _buildInsightCard(
              icon: Icons.auto_graph,
              title: T.get(T.monthlyProjection, _lang),
              content: _getProjectionText(monthlyAvgProfit),
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
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
                  title,
                  style: AppTheme.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getComparisonText(double change, double percent) {
    if (change > 0) {
      return '${T.get(T.profitIncreased, _lang)} ${Formatters.formatCurrency(change)} (${percent.toStringAsFixed(1)}%)';
    } else if (change < 0) {
      return '${T.get(T.profitDecreased, _lang)} ${Formatters.formatCurrency(change.abs())} (${percent.abs().toStringAsFixed(1)}%)';
    } else {
      return T.get(T.sameAsYesterday, _lang);
    }
  }

  String _getProfitStreakText(int days) {
    final dayText = days > 1 ? T.get(T.days, _lang) : T.get(T.day, _lang);
    return '$days $dayText ${T.get(T.ofProfit, _lang)}';
  }

  String _getProjectionText(double avgProfit) {
    final daysInMonth = 30;
    final projectedProfit = avgProfit * daysInMonth;

    if (projectedProfit > 0) {
      return '${T.get(T.basedOnTrend, _lang)} ${Formatters.formatCurrency(projectedProfit)} ${T.get(T.thisMonth, _lang)}';
    } else {
      return T.get(T.improveDailyProfit, _lang);
    }
  }
}
