import '../../../core/services/supabase_service.dart';
import '../../transactions/models/expense_model.dart';
import '../../transactions/models/income_model.dart';

class TransactionRepository {
  final SupabaseService _supabaseService;

  TransactionRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  // --- Expenses ---
  Future<List<ExpenseModel>> getExpenses(
      {DateTime? date, DateTime? startDate, DateTime? endDate}) async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) throw Exception('User not logged in');

      var query = _supabaseService.expenses
          .select('*, expense_categories(name)') // Join to get category name
          .eq('user_id', userId);

      if (date != null) {
        final dateStr = date.toIso8601String().split('T')[0];
        query = query.eq('date', dateStr);
      } else if (startDate != null && endDate != null) {
        query = query
            .gte('date', startDate.toIso8601String())
            .lte('date', endDate.toIso8601String());
      }

      final response = await query.order('date', ascending: false);

      return (response as List).map((e) => ExpenseModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    try {
      final response = await _supabaseService.expenses
          .insert(expense.toInsertJson())
          .select('*, expense_categories(name)')
          .single();

      return ExpenseModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  Future<void> deleteExpense(String id) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) throw Exception('User not logged in');
    await _supabaseService.expenses.delete().eq('id', id).eq('user_id', userId);
  }

  // --- Incomes ---
  Future<List<IncomeModel>> getIncomes(
      {DateTime? date, DateTime? startDate, DateTime? endDate}) async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) throw Exception('User not logged in');

      var query = _supabaseService.incomes
          .select('*, income_categories(name)')
          .eq('user_id', userId);

      if (date != null) {
        final dateStr = date.toIso8601String().split('T')[0];
        query = query.eq('date', dateStr);
      } else if (startDate != null && endDate != null) {
        query = query
            .gte('date', startDate.toIso8601String())
            .lte('date', endDate.toIso8601String());
      }

      final response = await query.order('date', ascending: false);

      return (response as List).map((e) => IncomeModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch incomes: $e');
    }
  }

  Future<IncomeModel> addIncome(IncomeModel income) async {
    try {
      final response = await _supabaseService.incomes
          .insert(income.toInsertJson())
          .select('*, income_categories(name)')
          .single();

      return IncomeModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add income: $e');
    }
  }

  Future<void> deleteIncome(String id) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) throw Exception('User not logged in');
    await _supabaseService.incomes.delete().eq('id', id).eq('user_id', userId);
  }
}
