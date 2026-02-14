import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../features/transactions/models/expense_model.dart';
import '../../features/transactions/models/income_model.dart';
import '../../features/transactions/repositories/transaction_repository.dart';
import '../../models/daily_summary.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/month_summary_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen>
    with WidgetsBindingObserver {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Own data state — independent from the shared TransactionCubit
  final TransactionRepository _repository = TransactionRepository();
  List<ExpenseModel> _expenses = [];
  List<IncomeModel> _incomes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDay = DateTime.now();
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
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  /// Public method to allow external refresh (e.g., from MainNavigation)
  void refresh() => _loadData();

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Fetch all transactions for the calendar view
      final results = await Future.wait([
        _repository.getExpenses(),
        _repository.getIncomes(),
      ]);
      if (mounted) {
        setState(() {
          _expenses = results[0] as List<ExpenseModel>;
          _incomes = results[1] as List<IncomeModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Map<DateTime, DailySummary> _generateSummaries(
      List<ExpenseModel> expenses, List<IncomeModel> incomes) {
    final Map<DateTime, DailySummary> map = {};

    for (var e in expenses) {
      final date = Formatters.normalizeDate(e.date);
      if (!map.containsKey(date)) {
        map[date] = DailySummary(
          id: date.toIso8601String(),
          date: date,
          totalIncome: 0,
          totalExpense: 0,
          profit: 0,
          mealsCount: 0,
        );
      }
      final current = map[date]!;
      map[date] = current.copyWith(
        totalExpense: current.totalExpense + e.amount,
        profit: current.totalIncome - (current.totalExpense + e.amount),
      );
    }

    for (var i in incomes) {
      final date = Formatters.normalizeDate(i.date);
      if (!map.containsKey(date)) {
        map[date] = DailySummary(
          id: date.toIso8601String(),
          date: date,
          totalIncome: 0,
          totalExpense: 0,
          profit: 0,
          mealsCount: 0,
        );
      }
      final current = map[date]!;
      map[date] = current.copyWith(
        totalIncome: current.totalIncome + i.amount,
        profit: (current.totalIncome + i.amount) - current.totalExpense,
      );
    }

    return map;
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
              child: const Icon(Icons.calendar_month, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Calendar View',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final summariesMap = _generateSummaries(_expenses, _incomes);
    final monthStats = _calculateMonthStats(summariesMap);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            MonthSummaryCard(
              month: _focusedDay,
              totalIncome: monthStats['income']!,
              totalExpense: monthStats['expense']!,
              profit: monthStats['profit']!,
              profitDays: monthStats['profitDays']!.toInt(),
              lossDays: monthStats['lossDays']!.toInt(),
              totalDays: monthStats['totalDays']!.toInt(),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              child: TableCalendar<DailySummary>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                  weekendStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: AppTheme.accentColor,
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    final summary =
                        summariesMap[Formatters.normalizeDate(date)];
                    if (summary != null) {
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                summary.profit >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
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
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedDay != null)
              _buildDayDetails(
                  summariesMap[Formatters.normalizeDate(_selectedDay!)]),
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetails(DailySummary? summary) {
    if (summary == null || _selectedDay == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                const Text(
                  'No transactions for this day',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Filter transactions for selected day from own data
    final selectedDayTransactions = _filterTransactionsForDay(
      _expenses,
      _incomes,
      _selectedDay!,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day summary card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    summary.profit >= 0
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.formatDateFull(summary.date),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        'Income',
                        '₹${summary.totalIncome.toStringAsFixed(0)}',
                        Icons.arrow_downward,
                        Colors.green,
                      ),
                      _buildSummaryItem(
                        'Expense',
                        '₹${summary.totalExpense.toStringAsFixed(0)}',
                        Icons.arrow_upward,
                        Colors.red,
                      ),
                      _buildSummaryItem(
                        'Profit',
                        '₹${summary.profit.toStringAsFixed(0)}',
                        summary.profit >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        summary.profit >= 0 ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Transactions list
          if (selectedDayTransactions['expenses']!.isEmpty &&
              selectedDayTransactions['incomes']!.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No transactions recorded',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                ...selectedDayTransactions['expenses']!
                    .map((expense) => _buildTransactionTile(
                          expense: expense,
                          isExpense: true,
                        )),
                ...selectedDayTransactions['incomes']!
                    .map((income) => _buildTransactionTile(
                          income: income,
                          isExpense: false,
                        )),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile({
    ExpenseModel? expense,
    IncomeModel? income,
    required bool isExpense,
  }) {
    final amount = isExpense ? expense!.amount : income!.amount;
    final category = isExpense
        ? (expense!.categoryName ?? 'Expense')
        : (income!.categoryName ?? 'Income');
    final description = isExpense ? expense!.description : income!.description;
    final id = isExpense ? expense!.id : income!.id;

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: Text(
                'Are you sure you want to delete this ${isExpense ? 'expense' : 'income'}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteAndReload(id, isExpense);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${isExpense ? 'Expense' : 'Income'} deleted successfully'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isExpense
                ? Colors.red.withOpacity(0.2)
                : Colors.green.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            category,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: description != null && description.isNotEmpty
              ? Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isExpense ? '-' : '+'}₹${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: isExpense ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Transaction'),
                      content: Text(
                          'Are you sure you want to delete this ${isExpense ? 'expense' : 'income'}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    _deleteAndReload(id, isExpense);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${isExpense ? 'Expense' : 'Income'} deleted successfully'),
                        backgroundColor: Colors.red,
                        action: SnackBarAction(
                          label: 'OK',
                          textColor: Colors.white,
                          onPressed: () {},
                        ),
                      ),
                    );
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAndReload(String id, bool isExpense) async {
    try {
      if (isExpense) {
        await _repository.deleteExpense(id);
      } else {
        await _repository.deleteIncome(id);
      }
      // Reload calendar data after deletion
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, List<dynamic>> _filterTransactionsForDay(
    List<ExpenseModel> expenses,
    List<IncomeModel> incomes,
    DateTime day,
  ) {
    final normalizedDay = Formatters.normalizeDate(day);

    final dayExpenses = expenses
        .where((e) => Formatters.normalizeDate(e.date) == normalizedDay)
        .toList();

    final dayIncomes = incomes
        .where((i) => Formatters.normalizeDate(i.date) == normalizedDay)
        .toList();

    return {
      'expenses': dayExpenses,
      'incomes': dayIncomes,
    };
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
}
