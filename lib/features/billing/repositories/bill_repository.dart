import '../../../core/services/supabase_service.dart';
import '../models/bill_model.dart';

class BillRepository {
  final SupabaseService _supabaseService;

  BillRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  /// Generate a sequential bill number for the given date
  Future<String> generateBillNumber(DateTime date) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final dateStr =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final prefix = 'BILL-$dateStr-';

    // Count existing bills for this date
    final response = await _supabaseService.bills
        .select('bill_number')
        .eq('user_id', userId)
        .like('bill_number', '$prefix%');

    final count = (response as List).length;
    final sequence = (count + 1).toString().padLeft(3, '0');
    return '$prefix$sequence';
  }

  /// Create a bill with its items (Optimized with Bulk Insert)
  Future<BillModel> createBill(
      BillModel bill, List<BillItemModel> items) async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) throw Exception('User not logged in');

      // 1. Insert the bill
      final billResponse = await _supabaseService.bills
          .insert(bill.toInsertJson())
          .select()
          .single();

      final createdBill = BillModel.fromJson(billResponse);

      // 2. Prepare bulk insert for bill items
      final List<Map<String, dynamic>> itemsJson = items.map((item) {
        return {
          'bill_id': createdBill.id,
          'item_name': item.itemName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total_price': item.totalPrice,
        };
      }).toList();

      // 3. Bulk Insert Items
      final itemsResponse =
          await _supabaseService.billItems.insert(itemsJson).select();

      final createdItems = (itemsResponse as List)
          .map((e) => BillItemModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return createdBill.copyWith(items: createdItems);
    } catch (e) {
      throw Exception('Failed to create bill: $e');
    }
  }

  /// Update the income_id on a bill after income is created
  Future<void> updateBillIncomeId(String billId, String incomeId) async {
    await _supabaseService.bills
        .update({'income_id': incomeId}).eq('id', billId);
  }

  /// Get all bills for the current user, optionally filtered by date
  Future<List<BillModel>> getBills({DateTime? date}) async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) throw Exception('User not logged in');

      var query = _supabaseService.bills
          .select('*, bill_items(*)')
          .eq('user_id', userId);

      if (date != null) {
        final dateStr = date.toIso8601String().split('T')[0];
        query = query.eq('bill_date', dateStr);
      }

      final response = await query.order('created_at', ascending: false);
 
      if (response == null) return [];
 
      return (response as List)
          .map((e) => BillModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch bills: $e');
    }
  }

  /// Get a single bill by ID with items
  Future<BillModel> getBillById(String id) async {
    try {
      final response = await _supabaseService.bills
          .select('*, bill_items(*)')
          .eq('id', id)
          .single();

      return BillModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch bill: $e');
    }
  }

  /// Delete a bill (cascades to items via DB constraint)
  Future<void> deleteBill(String id) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) throw Exception('User not logged in');

    // Get the bill to find linked income
    final bill = await getBillById(id);

    // Delete the linked income entry if exists
    if (bill.incomeId != null) {
      await _supabaseService.incomes
          .delete()
          .eq('id', bill.incomeId!)
          .eq('user_id', userId);
    }

    // Delete the bill (items cascade)
    await _supabaseService.bills.delete().eq('id', id).eq('user_id', userId);
  }

  /// Get bills for a specific customer name or phone within a date range
  Future<List<BillModel>> getBillsByCustomer({
    required String query,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) throw Exception('User not logged in');

      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      // Since Supabase doesn't easily do '(name OR phone) AND date',
      // we'll fetch then filter or use an or filter if possible.
      final response = await _supabaseService.bills
          .select('*, bill_items(*)')
          .eq('user_id', userId)
          .gte('bill_date', startDateStr)
          .lte('bill_date', endDateStr)
          .or('customer_name.ilike.%$query%,customer_phone.ilike.%$query%')
          .order('bill_date', ascending: true);

      return (response as List)
          .map((e) => BillModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch customer bills: $e');
    }
  }

  /// Get a list of all distinct customers (name + phone) for search suggestions
  Future<List<Map<String, String>>> getAllDistinctCustomers() async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) throw Exception('User not logged in');

      final response = await _supabaseService.bills
          .select('customer_name, customer_phone')
          .eq('user_id', userId);

      final List<Map<String, String>> customers = [];
      final Set<String> seen = {};

      for (final item in (response as List)) {
        final name = item['customer_name'] as String;
        final phone = item['customer_phone'] as String;
        final key = '$name-$phone'.toLowerCase();

        if (!seen.contains(key)) {
          customers.add({'name': name, 'phone': phone});
          seen.add(key);
        }
      }
      return customers;
    } catch (e) {
      return [];
    }
  }

  // ===== SAVED DISHES =====

  /// Get all saved dishes for the current user
  Future<List<Map<String, dynamic>>> getSavedDishes() async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final response = await _supabaseService.savedDishes
        .select()
        .eq('user_id', userId)
        .order('name');

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Save a dish (name + price) for reuse. Uses upsert to update price if name exists.
  Future<void> saveDish(String name, double price) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) throw Exception('User not logged in');

    await _supabaseService.savedDishes.upsert({
      'user_id': userId,
      'name': name,
      'price': price,
    }, onConflict: 'user_id,name');
  }

  /// Delete a saved dish
  Future<void> deleteSavedDish(String id) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) throw Exception('User not logged in');
    await _supabaseService.savedDishes
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// Auto-save all items from a bill as saved dishes (Optimized with Bulk Upsert)
  Future<void> autoSaveDishesFromBill(List<BillItemModel> items) async {
    if (items.isEmpty) return;

    final userId = _supabaseService.currentUserId;
    if (userId == null) return;

    try {
      // Prepare bulk upsert data
      final List<Map<String, dynamic>> dishesJson = items.map((item) {
        return {
          'user_id': userId,
          'name': item.itemName,
          'price': item.unitPrice,
        };
      }).toList();

      // Bulk upsert all dishes at once
      await _supabaseService.savedDishes
          .upsert(dishesJson, onConflict: 'user_id,name');
    } catch (e) {
      print('⚠️ Error in bulk auto-save dishes: $e');
    }
  }
}
