import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../features/transactions/models/expense_model.dart';
import '../../features/transactions/models/income_model.dart';
import '../../features/transactions/repositories/transaction_repository.dart';
import '../../models/daily_summary.dart';
import '../../services/language_service.dart';
import '../../services/share_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';

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
  int _txFilter = 0;

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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: AppTheme.appBarTitle(
          LanguageService.getLanguageCode() == 'ml' ? 'കലണ്ടർ' : 'Calendar',
          icon: Icons.calendar_month,
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
    if (_isLoading && _expenses.isEmpty && _incomes.isEmpty) {
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMonthStrip(monthStats),
            const SizedBox(height: 12),
            _buildCalendarCard(summariesMap),
            const SizedBox(height: 16),
            if (_selectedDay != null)
              _buildDayDetails(
                  summariesMap[Formatters.normalizeDate(_selectedDay!)]),
          ],
        ),
      ),
    );
  }

  String _compact(double v) {
    final a = v.abs();
    final sign = v < 0 ? '-' : '';
    if (a >= 10000000) return '$sign${(a / 10000000).toStringAsFixed(1)}Cr';
    if (a >= 100000) return '$sign${(a / 100000).toStringAsFixed(1)}L';
    if (a >= 1000) return '$sign${(a / 1000).toStringAsFixed(1)}k';
    return '$sign${a.toStringAsFixed(0)}';
  }

  Widget _buildMonthStrip(Map<String, double> stats) {
    final profit = stats['profit']!;
    final isProfit = profit >= 0;
    final accent = isProfit ? AppTheme.profitColor : AppTheme.lossColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isProfit ? 'Net profit' : 'Net loss',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatCurrency(profit.abs()),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(10, 6, 12, 6),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfit ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${stats['profitDays']!.toInt()}/${stats['totalDays']!.toInt()} profit days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statPill(
                  'Income',
                  Formatters.formatCurrency(stats['income']!),
                  AppTheme.profitColor,
                  Icons.south_west_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statPill(
                  'Expense',
                  Formatters.formatCurrency(stats['expense']!),
                  AppTheme.lossColor,
                  Icons.north_east_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(Map<DateTime, DailySummary> summariesMap) {
    final isMonth = _calendarFormat == CalendarFormat.month;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          _buildCalendarHeader(isMonth),
          TableCalendar<DailySummary>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerVisible: false,
            rowHeight: 58,
            daysOfWeekHeight: 28,
            availableGestures: AvailableGestures.horizontalSwipe,
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              weekendStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: EdgeInsets.all(3),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) =>
                  _dayCell(day, summariesMap),
              todayBuilder: (context, day, _) =>
                  _dayCell(day, summariesMap, isToday: true),
              selectedBuilder: (context, day, _) => _dayCell(
                day,
                summariesMap,
                isSelected: true,
                isToday: isSameDay(day, DateTime.now()),
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _txFilter = 0;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppTheme.profitColor, 'Profit'),
              const SizedBox(width: 16),
              _legendDot(AppTheme.lossColor, 'Loss'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1.2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader(bool isMonth) {
    final today = DateTime.now();
    final onToday = isSameDay(_focusedDay, today) &&
        isSameDay(_selectedDay, today);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateFormat(isMonth ? 'MMMM yyyy' : 'MMM d, yyyy')
                  .format(_focusedDay),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          if (!onToday)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: TextButton(
                onPressed: () => setState(() {
                  _focusedDay = today;
                  _selectedDay = today;
                }),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          IconButton(
            tooltip: isMonth ? 'Week view' : 'Month view',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() {
              _calendarFormat =
                  isMonth ? CalendarFormat.week : CalendarFormat.month;
            }),
            icon: Icon(
              isMonth ? Icons.view_week_outlined : Icons.calendar_view_month,
              color: AppTheme.textSecondary,
            ),
          ),
          IconButton(
            tooltip: 'Previous',
            visualDensity: VisualDensity.compact,
            onPressed: () => _shiftFocus(-1, isMonth),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            tooltip: 'Next',
            visualDensity: VisualDensity.compact,
            onPressed: () => _shiftFocus(1, isMonth),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  void _shiftFocus(int dir, bool isMonth) {
    setState(() {
      _focusedDay = isMonth
          ? DateTime(_focusedDay.year, _focusedDay.month + dir, 1)
          : _focusedDay.add(Duration(days: 7 * dir));
    });
  }

  Widget _dayCell(
    DateTime day,
    Map<DateTime, DailySummary> summariesMap, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    final summary = summariesMap[Formatters.normalizeDate(day)];
    final hasData = summary != null;
    final isProfit = hasData && summary.profit >= 0;
    final tone = isProfit ? AppTheme.profitColor : AppTheme.lossColor;

    final Color bg;
    final Color textColor;
    final Color subColor;
    if (isSelected) {
      bg = AppTheme.primaryColor;
      textColor = Colors.white;
      subColor = Colors.white.withOpacity(0.9);
    } else if (hasData) {
      bg = tone.withOpacity(0.1);
      textColor = AppTheme.textPrimary;
      subColor = tone;
    } else {
      bg = Colors.transparent;
      textColor = AppTheme.textPrimary;
      subColor = AppTheme.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: isToday && !isSelected
            ? Border.all(color: AppTheme.primaryColor, width: 1.5)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isToday || isSelected || hasData
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: textColor,
            ),
          ),
          if (hasData)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                _compact(summary.profit),
                maxLines: 1,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayDetails(DailySummary? summary) {
    final day = _selectedDay!;
    final dayTx = _filterTransactionsForDay(_expenses, _incomes, day);
    final expenses = dayTx['expenses']!.cast<ExpenseModel>();
    final incomes = dayTx['incomes']!.cast<IncomeModel>();
    final showExpenses = _txFilter != 1;
    final showIncomes = _txFilter != 2;
    final visibleExpenses = showExpenses ? expenses : <ExpenseModel>[];
    final visibleIncomes = showIncomes ? incomes : <IncomeModel>[];
    final totalCount = expenses.length + incomes.length;
    final profit = summary?.profit ?? 0;
    final accent = profit >= 0 ? AppTheme.profitColor : AppTheme.lossColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('EEE').format(day).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          '${day.day}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(day),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          totalCount == 0
                              ? 'No transactions'
                              : '$totalCount transaction${totalCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (summary != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${profit >= 0 ? '+' : '-'}₹${profit.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
                  if (totalCount > 0)
                    IconButton(
                      tooltip: 'Share day report',
                      onPressed: () => ShareService.shareDailySummary(
                        date: day,
                        incomes: incomes,
                        expenses: expenses,
                      ),
                      icon: const Icon(Icons.share_outlined,
                          color: AppTheme.primaryColor),
                    ),
                ],
              ),
              if (summary != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _statPill(
                        'Income',
                        '₹${summary.totalIncome.toStringAsFixed(0)}',
                        AppTheme.profitColor,
                        Icons.south_west_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statPill(
                        'Expense',
                        '₹${summary.totalExpense.toStringAsFixed(0)}',
                        AppTheme.lossColor,
                        Icons.north_east_rounded,
                      ),
                    ),
                  ],
                ),
              ],
              if (totalCount > 0) ...[
                const SizedBox(height: 14),
                _buildSegmentedFilter(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (totalCount == 0)
          _emptyState(
            Icons.event_available_outlined,
            'Nothing recorded on this day',
          )
        else if (visibleExpenses.isEmpty && visibleIncomes.isEmpty)
          _emptyState(
            Icons.filter_list_off,
            'No ${_txFilter == 1 ? 'expenses' : 'income'} on this day',
          )
        else ...[
          for (final e in visibleExpenses)
            _buildTransactionTile(expense: e, isExpense: true),
          for (final i in visibleIncomes)
            _buildTransactionTile(income: i, isExpense: false),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Center(
              child: Text(
                'Swipe left on a transaction to delete',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedFilter() {
    const labels = ['All', 'Expense', 'Income'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = _txFilter == i;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _txFilter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }


  Future<bool> _confirmDelete(bool isExpense) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            style: TextButton.styleFrom(foregroundColor: AppTheme.lossColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result == true;
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
    final color = isExpense ? AppTheme.lossColor : AppTheme.profitColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: AlignmentDirectional.centerEnd,
          padding: const EdgeInsetsDirectional.only(end: 20),
          decoration: BoxDecoration(
            color: AppTheme.lossColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline,
              color: Colors.white, size: 26),
        ),
        confirmDismiss: (_) => _confirmDelete(isExpense),
        onDismissed: (_) {
          _deleteAndReload(id, isExpense);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              content: Text(
                  '${isExpense ? 'Expense' : 'Income'} deleted successfully'),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isExpense
                      ? Icons.north_east_rounded
                      : Icons.south_west_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (description != null && description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${isExpense ? '-' : '+'}₹${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
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
