import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/daily_summary.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  // Getter for the client (useful for realtime subscriptions)
  SupabaseClient get client => _client;

  // ==================== Income Operations ====================

  /// Fetch all income records
  Future<List<Income>> fetchAllIncome({String? context}) async {
    try {
      final response =
          await _client.from('income').select().order('date', ascending: false);

      final incomes = (response as List)
          .map((json) => Income.fromJson(json as Map<String, dynamic>))
          .toList();

      if (context != null) {
        return incomes.where((income) => income.context == context).toList();
      }

      return incomes;
    } catch (e) {
      throw Exception('Failed to fetch income: $e');
    }
  }

  /// Fetch income for a specific date and context
  Future<Income?> fetchIncomeByDate(DateTime date,
      {String context = 'hotel'}) async {
    try {
      final response = await _client
          .from('income')
          .select()
          .eq('date', date.toIso8601String())
          .eq('context', context)
          .maybeSingle();

      if (response == null) return null;
      return Income.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch income by date: $e');
    }
  }

  /// Fetch income for a date range
  Future<List<Income>> fetchIncomeByDateRange(
      DateTime startDate, DateTime endDate,
      {String? context}) async {
    try {
      final response = await _client
          .from('income')
          .select()
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .order('date', ascending: false);

      final incomes = (response as List)
          .map((json) => Income.fromJson(json as Map<String, dynamic>))
          .toList();

      if (context != null) {
        return incomes.where((income) => income.context == context).toList();
      }

      return incomes;
    } catch (e) {
      throw Exception('Failed to fetch income by date range: $e');
    }
  }

  /// Create or update income
  Future<Income> upsertIncome(Income income) async {
    try {
      final response = await _client
          .from('income')
          .upsert(income.toInsertJson(), onConflict: 'date,context')
          .select()
          .single();

      return Income.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to upsert income: $e');
    }
  }

  /// Delete income
  Future<void> deleteIncome(String id) async {
    try {
      await _client.from('income').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete income: $e');
    }
  }

  // ==================== Expense Operations ====================

  /// Fetch all expense records
  Future<List<Expense>> fetchAllExpense({String? context}) async {
    try {
      final response = await _client
          .from('expense')
          .select()
          .order('date', ascending: false);

      final expenses = (response as List)
          .map((json) => Expense.fromJson(json as Map<String, dynamic>))
          .toList();

      if (context != null) {
        return expenses.where((expense) => expense.context == context).toList();
      }

      return expenses;
    } catch (e) {
      throw Exception('Failed to fetch expense: $e');
    }
  }

  /// Fetch expense for a specific date and context
  Future<Expense?> fetchExpenseByDate(DateTime date,
      {String context = 'hotel'}) async {
    try {
      final response = await _client
          .from('expense')
          .select()
          .eq('date', date.toIso8601String())
          .eq('context', context)
          .maybeSingle();

      if (response == null) return null;
      return Expense.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch expense by date: $e');
    }
  }

  /// Fetch expense for a date range
  Future<List<Expense>> fetchExpenseByDateRange(
      DateTime startDate, DateTime endDate,
      {String? context}) async {
    try {
      final response = await _client
          .from('expense')
          .select()
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .order('date', ascending: false);

      final expenses = (response as List)
          .map((json) => Expense.fromJson(json as Map<String, dynamic>))
          .toList();

      if (context != null) {
        return expenses.where((expense) => expense.context == context).toList();
      }

      return expenses;
    } catch (e) {
      throw Exception('Failed to fetch expense by date range: $e');
    }
  }

  /// Create or update expense
  Future<Expense> upsertExpense(Expense expense) async {
    try {
      final response = await _client
          .from('expense')
          .upsert(expense.toInsertJson(), onConflict: 'date,context')
          .select()
          .single();

      return Expense.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to upsert expense: $e');
    }
  }

  /// Delete expense
  Future<void> deleteExpense(String id) async {
    try {
      await _client.from('expense').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  // ==================== Daily Summary Operations ====================

  /// Fetch all daily summaries
  Future<List<DailySummary>> fetchAllDailySummaries({String? context}) async {
    try {
      // Fetch filtered expenses and incomes
      final expenses = await fetchAllExpense(context: context);
      final incomes = await fetchAllIncome(context: context);

      // Group by date
      final Map<DateTime, List<Expense>> expensesByDate = {};
      final Map<DateTime, List<Income>> incomesByDate = {};

      for (var expense in expenses) {
        final date =
            DateTime(expense.date.year, expense.date.month, expense.date.day);
        expensesByDate.putIfAbsent(date, () => []).add(expense);
      }

      for (var income in incomes) {
        final date =
            DateTime(income.date.year, income.date.month, income.date.day);
        incomesByDate.putIfAbsent(date, () => []).add(income);
      }

      // Calculate summaries
      final Set<DateTime> allDates = {
        ...expensesByDate.keys,
        ...incomesByDate.keys
      };
      final List<DailySummary> summaries = [];

      for (var date in allDates) {
        final dayExpenses = expensesByDate[date] ?? [];
        final dayIncomes = incomesByDate[date] ?? [];

        double totalExpense =
            dayExpenses.fold(0.0, (sum, e) => sum + e.totalExpense);
        double totalIncome =
            dayIncomes.fold(0.0, (sum, i) => sum + i.totalIncome);
        int mealsCount = dayIncomes.fold(0, (sum, i) => sum + i.mealsCount);

        summaries.add(DailySummary(
          id: '${context ?? 'all'}_${date.toIso8601String()}',
          date: date,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          profit: totalIncome - totalExpense,
          mealsCount: mealsCount,
        ));
      }

      summaries.sort((a, b) => b.date.compareTo(a.date)); // Most recent first
      return summaries;
    } catch (e) {
      throw Exception('Failed to fetch daily summaries: $e');
    }
  }

  /// Fetch daily summary for a specific date
  Future<DailySummary?> fetchDailySummaryByDate(DateTime date) async {
    try {
      final response = await _client
          .from('daily_summary')
          .select()
          .eq('date', date.toIso8601String())
          .maybeSingle();

      if (response == null) return null;
      return DailySummary.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch daily summary by date: $e');
    }
  }

  /// Fetch daily summaries for a date range
  Future<List<DailySummary>> fetchDailySummariesByDateRange(
      DateTime startDate, DateTime endDate,
      {String? context}) async {
    try {
      // Fetch filtered expenses and incomes for the date range
      final expenses =
          await fetchExpenseByDateRange(startDate, endDate, context: context);
      final incomes =
          await fetchIncomeByDateRange(startDate, endDate, context: context);

      // Group by date
      final Map<DateTime, List<Expense>> expensesByDate = {};
      final Map<DateTime, List<Income>> incomesByDate = {};

      for (var expense in expenses) {
        final date =
            DateTime(expense.date.year, expense.date.month, expense.date.day);
        expensesByDate.putIfAbsent(date, () => []).add(expense);
      }

      for (var income in incomes) {
        final date =
            DateTime(income.date.year, income.date.month, income.date.day);
        incomesByDate.putIfAbsent(date, () => []).add(income);
      }

      // Calculate summaries
      final Set<DateTime> allDates = {
        ...expensesByDate.keys,
        ...incomesByDate.keys
      };
      final List<DailySummary> summaries = [];

      for (var date in allDates) {
        final dayExpenses = expensesByDate[date] ?? [];
        final dayIncomes = incomesByDate[date] ?? [];

        double totalExpense =
            dayExpenses.fold(0.0, (sum, e) => sum + e.totalExpense);
        double totalIncome =
            dayIncomes.fold(0.0, (sum, i) => sum + i.totalIncome);
        int mealsCount = dayIncomes.fold(0, (sum, i) => sum + i.mealsCount);

        summaries.add(DailySummary(
          id: '${context ?? 'all'}_${date.toIso8601String()}',
          date: date,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          profit: totalIncome - totalExpense,
          mealsCount: mealsCount,
        ));
      }

      summaries.sort((a, b) => b.date.compareTo(a.date)); // Most recent first
      return summaries;
    } catch (e) {
      throw Exception('Failed to fetch daily summaries by date range: $e');
    }
  }

  /// Update meals count for a specific date
  Future<DailySummary> updateMealsCount(DateTime date, int mealsCount) async {
    try {
      final response = await _client
          .from('daily_summary')
          .update({'meals_count': mealsCount})
          .eq('date', date.toIso8601String())
          .select()
          .single();

      return DailySummary.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update meals count: $e');
    }
  }

  // ==================== Analytics Operations ====================

  /// Get the best profit day from a list of summaries
  DailySummary? getBestProfitDay(List<DailySummary> summaries) {
    if (summaries.isEmpty) return null;

    return summaries.reduce(
        (current, next) => next.profit > current.profit ? next : current);
  }

  /// Calculate weekly summary
  Future<Map<String, double>> fetchWeeklySummary(DateTime weekStart,
      {String? context}) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final summaries = await fetchDailySummariesByDateRange(weekStart, weekEnd,
        context: context);

    double totalIncome = 0;
    double totalExpense = 0;
    double totalProfit = 0;

    for (var summary in summaries) {
      totalIncome += summary.totalIncome;
      totalExpense += summary.totalExpense;
      totalProfit += summary.profit;
    }

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'totalProfit': totalProfit,
    };
  }

  /// Calculate monthly summary
  Future<Map<String, double>> fetchMonthlySummary(int year, int month,
      {String? context}) async {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);
    final summaries = await fetchDailySummariesByDateRange(monthStart, monthEnd,
        context: context);

    double totalIncome = 0;
    double totalExpense = 0;
    double totalProfit = 0;

    for (var summary in summaries) {
      totalIncome += summary.totalIncome;
      totalExpense += summary.totalExpense;
      totalProfit += summary.profit;
    }

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'totalProfit': totalProfit,
    };
  }

  // ==================== Realtime Subscriptions ====================

  /// Subscribe to income changes
  RealtimeChannel subscribeToIncome(
      void Function(PostgresChangePayload) callback) {
    return _client
        .channel('income_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'income',
          callback: callback,
        )
        .subscribe();
  }

  /// Subscribe to expense changes
  RealtimeChannel subscribeToExpense(
      void Function(PostgresChangePayload) callback) {
    return _client
        .channel('expense_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expense',
          callback: callback,
        )
        .subscribe();
  }

  /// Subscribe to daily summary changes
  RealtimeChannel subscribeToDailySummary(
      void Function(PostgresChangePayload) callback) {
    return _client
        .channel('daily_summary_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'daily_summary',
          callback: callback,
        )
        .subscribe();
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
