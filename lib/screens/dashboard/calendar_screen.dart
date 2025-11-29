import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../models/daily_summary.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/calendar_filters.dart';
import '../../widgets/month_summary_card.dart';
import '../../services/share_service.dart';
import 'add_income_screen.dart';
import 'add_expense_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  CalendarFilter _selectedFilter = CalendarFilter.all;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
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
              child: const Icon(Icons.calendar_month_rounded, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calendar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  Formatters.formatMonth(_focusedDay),
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
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.today, size: 20),
            ),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            tooltip: 'Today',
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.share, size: 20),
            ),
            onPressed: () => _shareMonthSummary(context),
            tooltip: 'Share Month Report',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoaded) {
            final summariesMap = <DateTime, DailySummary>{};
            for (var summary in state.allSummaries) {
              final date = Formatters.normalizeDate(summary.date);
              summariesMap[date] = summary;
            }

            // Calculate month statistics
            final monthStats = _calculateMonthStats(summariesMap);

            return RefreshIndicator(
              onRefresh: () async {
                context.read<DashboardBloc>().add(const RefreshDashboardData());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Month Summary Card
                    MonthSummaryCard(
                      month: _focusedDay,
                      totalIncome: monthStats['income']!,
                      totalExpense: monthStats['expense']!,
                      profit: monthStats['profit']!,
                      profitDays: monthStats['profitDays']!.toInt(),
                      lossDays: monthStats['lossDays']!.toInt(),
                      totalDays: monthStats['totalDays']!.toInt(),
                    ),

                    const SizedBox(height: 8),

                    // Filter Chips
                    CalendarFilters(
                      selectedFilter: _selectedFilter,
                      onFilterChanged: (filter) {
                        setState(() => _selectedFilter = filter);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Calendar
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: TableCalendar<DailySummary>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          calendarFormat: _calendarFormat,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Month',
                            CalendarFormat.week: 'Week',
                          },
                          headerStyle: HeaderStyle(
                            formatButtonVisible: true,
                            titleCentered: true,
                            formatButtonShowsNext: false,
                            formatButtonDecoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            formatButtonTextStyle: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            leftChevronIcon: const Icon(
                              Icons.chevron_left,
                              color: AppTheme.primaryColor,
                            ),
                            rightChevronIcon: const Icon(
                              Icons.chevron_right,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            selectedDecoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            markerDecoration: const BoxDecoration(
                              color: AppTheme.profitColor,
                              shape: BoxShape.circle,
                            ),
                            outsideDaysVisible: false,
                          ),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            setState(() {
                              _focusedDay = focusedDay;
                            });
                          },
                          onFormatChanged: (format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          },
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, date, _) {
                              final normalized = Formatters.normalizeDate(date);
                              final summary = summariesMap[normalized];

                              if (summary != null && _shouldShowDay(summary)) {
                                final color = _getColorForSummary(summary);

                                return Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        color.withOpacity(0.15),
                                        color.withOpacity(0.05),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: color.withOpacity(0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${date.day}',
                                          style: AppTheme.bodyMedium.copyWith(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        if (summary.profit != 0)
                                          Text(
                                            Formatters.formatCurrencyCompact(
                                                summary.profit.abs()),
                                            style: AppTheme.bodySmall.copyWith(
                                              color: color,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return null;
                            },
                            todayBuilder: (context, date, _) {
                              final normalized = Formatters.normalizeDate(date);
                              final summary = summariesMap[normalized];

                              if (summary != null && _shouldShowDay(summary)) {
                                final color = _getColorForSummary(summary);

                                return Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        color.withOpacity(0.2),
                                        color.withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${date.day}',
                                          style: AppTheme.bodyMedium.copyWith(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (summary.profit != 0)
                                          Text(
                                            Formatters.formatCurrencyCompact(
                                                summary.profit.abs()),
                                            style: AppTheme.bodySmall.copyWith(
                                              color: color,
                                              fontSize: 9,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Selected Day Details
                    if (_selectedDay != null) ...[
                      _buildSelectedDayDetails(
                        summariesMap[Formatters.normalizeDate(_selectedDay!)],
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          }

          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return const Center(child: Text('No data available'));
        },
      ),
    );
  }

  Widget _buildSelectedDayDetails(DailySummary? summary) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: summary != null
                ? (summary.profit >= 0
                    ? [Colors.green.shade50, Colors.white]
                    : [Colors.red.shade50, Colors.white])
                : [Colors.grey.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: summary != null
                          ? (summary.profit >= 0
                              ? AppTheme.profitColor
                              : AppTheme.lossColor)
                          : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      summary != null
                          ? (summary.profit >= 0
                              ? Icons.trending_up
                              : Icons.trending_down)
                          : Icons.calendar_today,
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
                          Formatters.formatDateFull(_selectedDay!),
                          style: AppTheme.headingSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (summary != null)
                          Text(
                            summary.profit >= 0 ? 'Profitable Day' : 'Loss Day',
                            style: AppTheme.bodySmall.copyWith(
                              color: summary.profit >= 0
                                  ? AppTheme.profitColor
                                  : AppTheme.lossColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (summary != null) ...[
                const Divider(height: 24),

                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Income',
                        Formatters.formatCurrency(summary.totalIncome),
                        Icons.arrow_upward,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Expense',
                        Formatters.formatCurrency(summary.totalExpense),
                        Icons.arrow_downward,
                        Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        summary.profit >= 0 ? 'Profit' : 'Loss',
                        Formatters.formatCurrency(summary.profit.abs()),
                        summary.profit >= 0 ? Icons.check_circle : Icons.cancel,
                        summary.profit >= 0
                            ? AppTheme.profitColor
                            : AppTheme.lossColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Meals',
                        summary.mealsCount.toString(),
                        Icons.restaurant,
                        AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddIncomeScreen(selectedDate: _selectedDay),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit Income'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.profitColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                              builder: (context) =>
                                  AddExpenseScreen(selectedDate: _selectedDay),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit Expense'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.lossColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareDaySummary(summary),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Clean icon-only delete button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showDeleteConfirmationDialog(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.shade100,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade600,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No data for this day',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first entry to start tracking',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddIncomeScreen(selectedDate: _selectedDay),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Income for This Day'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Map<String, double> _calculateMonthStats(
      Map<DateTime, DailySummary> summariesMap) {
    double totalIncome = 0;
    double totalExpense = 0;
    double profitDays = 0;
    double lossDays = 0;
    int totalDays = 0;

    final monthStart = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final monthEnd = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    for (var day = monthStart;
        day.isBefore(monthEnd) || day.isAtSameMomentAs(monthEnd);
        day = day.add(const Duration(days: 1))) {
      final normalized = Formatters.normalizeDate(day);
      final summary = summariesMap[normalized];

      if (summary != null) {
        totalIncome += summary.totalIncome;
        totalExpense += summary.totalExpense;
        totalDays++;

        if (summary.profit > 0) {
          profitDays++;
        } else if (summary.profit < 0) {
          lossDays++;
        }
      }
    }

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'profit': totalIncome - totalExpense,
      'profitDays': profitDays,
      'lossDays': lossDays,
      'totalDays': totalDays.toDouble(),
    };
  }

  bool _shouldShowDay(DailySummary summary) {
    switch (_selectedFilter) {
      case CalendarFilter.all:
        return true;
      case CalendarFilter.profit:
        return summary.profit > 0;
      case CalendarFilter.loss:
        return summary.profit < 0;
      case CalendarFilter.highIncome:
        return summary.totalIncome > 3000; // Threshold
      case CalendarFilter.highExpense:
        return summary.totalExpense > 2000; // Threshold
    }
  }

  Color _getColorForSummary(DailySummary summary) {
    if (summary.profit > 0) {
      return AppTheme.profitColor;
    } else if (summary.profit < 0) {
      return AppTheme.lossColor;
    } else {
      return AppTheme.neutralColor;
    }
  }

  Future<void> _shareMonthSummary(BuildContext context) async {
    final state = context.read<DashboardBloc>().state;
    if (state is DashboardLoaded) {
      final summariesMap = <DateTime, DailySummary>{};
      for (var summary in state.allSummaries) {
        final date = Formatters.normalizeDate(summary.date);
        summariesMap[date] = summary;
      }

      final monthStats = _calculateMonthStats(summariesMap);

      await ShareService.shareMonthlySummary(
        month: Formatters.formatMonth(_focusedDay),
        totalIncome: monthStats['income']!,
        totalExpense: monthStats['expense']!,
        totalMeals: 0, // Could calculate from summaries
        profitableDays: monthStats['profitDays']!.toInt(),
        totalDays: monthStats['totalDays']!.toInt(),
      );
    }
  }

  Future<void> _shareDaySummary(DailySummary summary) async {
    await ShareService.shareDailySummary(
      date: summary.date,
    );
  }

  /// Show confirmation dialog before deleting data
  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete all data for ${Formatters.formatDateFull(_selectedDay!)}? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteDataForSelectedDay();
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Delete'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Delete income and expense data for the selected day
  Future<void> _deleteDataForSelectedDay() async {
    try {
      // Show a loading indicator
      final snackBar = SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 10),
            const Text('Deleting data...'),
          ],
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      // Dispatch the delete event
      context.read<DashboardBloc>().add(
            DeleteDailyData(_selectedDay!, context: 'hotel'),
          ); // Hide the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Hide the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
