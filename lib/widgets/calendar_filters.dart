import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

enum CalendarFilter { all, profit, loss, highIncome, highExpense }

class CalendarFilters extends StatefulWidget {
  final CalendarFilter selectedFilter;
  final Function(CalendarFilter) onFilterChanged;

  const CalendarFilters({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  State<CalendarFilters> createState() => _CalendarFiltersState();
}

class _CalendarFiltersState extends State<CalendarFilters> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All Days',
            icon: Icons.calendar_month,
            filter: CalendarFilter.all,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Profit Days',
            icon: Icons.trending_up,
            filter: CalendarFilter.profit,
            color: AppTheme.profitColor,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Loss Days',
            icon: Icons.trending_down,
            filter: CalendarFilter.loss,
            color: AppTheme.lossColor,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'High Income',
            icon: Icons.arrow_upward,
            filter: CalendarFilter.highIncome,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'High Expense',
            icon: Icons.arrow_downward,
            filter: CalendarFilter.highExpense,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required CalendarFilter filter,
    Color? color,
  }) {
    final isSelected = widget.selectedFilter == filter;
    final chipColor = color ?? AppTheme.primaryColor;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : chipColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : chipColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        widget.onFilterChanged(filter);
      },
      backgroundColor: Colors.white,
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? chipColor : chipColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }
}
