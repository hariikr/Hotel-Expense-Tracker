import '../../../core/services/supabase_service.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final SupabaseService _supabaseService;

  CategoryRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  Future<List<CategoryModel>> getExpenseCategories() async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) throw Exception('User not logged in');

      final response = await _supabaseService.expenseCategories
          .select()
          .eq('user_id', userId)
          .order('name');

      return (response as List)
          .map((e) => CategoryModel.fromJson(e, CategoryType.expense))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch expense categories: $e');
    }
  }

  Future<List<CategoryModel>> getIncomeCategories() async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) throw Exception('User not logged in');

      final response = await _supabaseService.incomeCategories
          .select()
          .eq('user_id', userId)
          .order('name');

      return (response as List)
          .map((e) => CategoryModel.fromJson(e, CategoryType.income))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch income categories: $e');
    }
  }

  Future<CategoryModel> addCategory(String name, CategoryType type) async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) throw Exception('User not logged in');

      final table = type == CategoryType.expense
          ? _supabaseService.expenseCategories
          : _supabaseService.incomeCategories;

      final response = await table
          .insert({
            'user_id': userId,
            'name': name,
          })
          .select()
          .single();

      return CategoryModel.fromJson(response, type);
    } catch (e) {
      // Check for duplicate error (Postgres usually throws specific code but Supabase wraps it)
      if (e.toString().contains('duplicate key')) {
        throw Exception('Category already exists');
      }
      throw Exception('Failed to add category: $e');
    }
  }

  Future<void> deleteCategory(String id, CategoryType type) async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) throw Exception('User not logged in');

      final table = type == CategoryType.expense
          ? _supabaseService.expenseCategories
          : _supabaseService.incomeCategories;

      await table.delete().eq('id', id).eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }
}
