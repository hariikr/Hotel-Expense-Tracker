import 'package:flutter/material.dart';
import '../../models/daily_summary.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';

class BestProfitCard extends StatelessWidget {
  final DailySummary summary;

  const BestProfitCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: AppTheme.profitColor.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppTheme.profitColor.withOpacity(0.15),
              AppTheme.profitColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.profitColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
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
                        'Best Profit Day',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        Formatters.formatDateFull(summary.date),
                        style: AppTheme.headingSmall.copyWith(
                          color: AppTheme.profitColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat(
                  label: 'Income',
                  value: Formatters.formatCurrency(summary.totalIncome),
                  icon: Icons.arrow_upward,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.textSecondary.withOpacity(0.2),
                ),
                _buildStat(
                  label: 'Expense',
                  value: Formatters.formatCurrency(summary.totalExpense),
                  icon: Icons.arrow_downward,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.textSecondary.withOpacity(0.2),
                ),
                _buildStat(
                  label: 'Profit',
                  value: Formatters.formatCurrency(summary.profit),
                  icon: Icons.star,
                  valueColor: AppTheme.profitColor,
                ),
              ],
            ),
            if (summary.mealsCount > 0) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.restaurant,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${summary.mealsCount} meals served',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStat({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 18,
            color: valueColor ?? AppTheme.textSecondary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
