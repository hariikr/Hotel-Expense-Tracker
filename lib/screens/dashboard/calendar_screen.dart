import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../models/daily_summary.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar View'),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoaded) {
            final summariesMap = <DateTime, DailySummary>{};
            for (var summary in state.allSummaries) {
              final date = Formatters.normalizeDate(summary.date);
              summariesMap[date] = summary;
            }

            return Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: TableCalendar<DailySummary>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppTheme.profitColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        final normalized = Formatters.normalizeDate(date);
                        final summary = summariesMap[normalized];

                        if (summary != null) {
                          final color = summary.profit > 0
                              ? AppTheme.profitColor
                              : summary.profit < 0
                                  ? AppTheme.lossColor
                                  : AppTheme.neutralColor;

                          return Positioned(
                            bottom: 2,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                      defaultBuilder: (context, date, _) {
                        final normalized = Formatters.normalizeDate(date);
                        final summary = summariesMap[normalized];

                        if (summary != null) {
                          final color = summary.profit > 0
                              ? AppTheme.profitColor
                              : summary.profit < 0
                                  ? AppTheme.lossColor
                                  : AppTheme.neutralColor;

                          return Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${date.day}',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (summary.mealsCount > 0)
                                    Text(
                                      '${summary.mealsCount}',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: color,
                                        fontSize: 10,
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

                // Selected Day Details
                if (_selectedDay != null) ...[
                  Expanded(
                    child: _buildSelectedDayDetails(
                      summariesMap[Formatters.normalizeDate(_selectedDay!)],
                    ),
                  ),
                ],
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildSelectedDayDetails(DailySummary? summary) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Formatters.formatDateFull(_selectedDay!),
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            if (summary != null) ...[
              _buildDetailRow(
                  'Income', summary.totalIncome, AppTheme.profitColor),
              const SizedBox(height: 12),
              _buildDetailRow(
                  'Expense', summary.totalExpense, AppTheme.lossColor),
              const SizedBox(height: 12),
              _buildDetailRow(
                  'Profit',
                  summary.profit,
                  summary.profit >= 0
                      ? AppTheme.profitColor
                      : AppTheme.lossColor),
              const SizedBox(height: 12),
              _buildDetailRow(
                  'Meals', summary.mealsCount.toDouble(), AppTheme.primaryColor,
                  isCurrency: false),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddIncomeScreen(selectedDate: _selectedDay),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Income'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddExpenseScreen(selectedDate: _selectedDay),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Expense'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Delete button for hotel context only
              BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardLoaded && state.selectedContext == 'hotel') {
                    return ElevatedButton.icon(
                      onPressed: () => _showDeleteConfirmationDialog(context),
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text('Delete Data', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    );
                  }
                  return const SizedBox.shrink(); // Hide delete button if not in hotel context
                },
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No data for this day'),
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
                icon: const Icon(Icons.add),
                label: const Text('Add Data for This Day'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, double value, Color color,
      {bool isCurrency = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          isCurrency
              ? Formatters.formatCurrency(value)
              : value.toInt().toString(),
          style: AppTheme.headingSmall.copyWith(
            color: color,
          ),
        ),
      ],
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

      // Get the current context from the dashboard state
      final currentState = context.read<DashboardBloc>().state;
      final currentContext = currentState is DashboardLoaded 
          ? currentState.selectedContext 
          : 'hotel';

      // Dispatch the delete event
      context.read<DashboardBloc>().add(
        DeleteDailyData(_selectedDay!, context: currentContext),
      );

      // Hide the loading snackbar 
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
