import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient client = Supabase.instance.client;

  // Helper getters for common tables
  SupabaseQueryBuilder get expenses => client.from('expenses');
  SupabaseQueryBuilder get incomes => client.from('incomes');
  SupabaseQueryBuilder get expenseCategories =>
      client.from('expense_categories');
  SupabaseQueryBuilder get incomeCategories => client.from('income_categories');
  SupabaseQueryBuilder get dailySummary => client.from('daily_summary');

  User? get currentUser => client.auth.currentUser;
  String? get currentUserId => client.auth.currentUser?.id;
}
