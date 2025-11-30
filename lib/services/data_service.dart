import '../models/income.dart';
import '../models/expense.dart';
import '../models/daily_summary.dart';

/// Abstract interface for data operations
/// Implemented by both SupabaseService (online-only) and OfflineFirstService (offline-first)
abstract class DataService {
  // Income operations
  Future<List<Income>> fetchAllIncome({String? context});
  Future<Income?> fetchIncomeByDate(DateTime date, {String context = 'hotel'});
  Future<Income> upsertIncome(Income income);
  Future<void> deleteIncome(String id);

  // Expense operations
  Future<List<Expense>> fetchAllExpense({String? context});
  Future<Expense?> fetchExpenseByDate(DateTime date,
      {String context = 'hotel'});
  Future<Expense> upsertExpense(Expense expense);
  Future<void> deleteExpense(String id);

  // Daily summary operations
  Future<List<DailySummary>> fetchAllDailySummaries({String? context});

  // Analytics operations
  DailySummary? getBestProfitDay(List<DailySummary> summaries);
  Future<Map<String, double>> fetchWeeklySummary(DateTime weekStart,
      {String? context});
  Future<Map<String, double>> fetchMonthlySummary(int year, int month,
      {String? context});
}
