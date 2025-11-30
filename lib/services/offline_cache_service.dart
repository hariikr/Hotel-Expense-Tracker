import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/daily_summary.dart';

class OfflineCacheService {
  static const String _incomesCacheKey = 'cached_incomes';
  static const String _expensesCacheKey = 'cached_expenses';
  static const String _summariesCacheKey = 'cached_summaries';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _pendingOperationsKey = 'pending_operations';

  // Cache income data
  Future<void> cacheIncomes(List<Income> incomes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = incomes.map((income) => income.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_incomesCacheKey, jsonString);
      await _updateLastSync();
    } catch (e) {
      print('Error caching incomes: $e');
    }
  }

  // Get cached incomes
  Future<List<Income>> getCachedIncomes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_incomesCacheKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => Income.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting cached incomes: $e');
      return [];
    }
  }

  // Cache expenses
  Future<void> cacheExpenses(List<Expense> expenses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = expenses.map((expense) => expense.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_expensesCacheKey, jsonString);
      await _updateLastSync();
    } catch (e) {
      print('Error caching expenses: $e');
    }
  }

  // Get cached expenses
  Future<List<Expense>> getCachedExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_expensesCacheKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => Expense.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting cached expenses: $e');
      return [];
    }
  }

  // Cache daily summaries
  Future<void> cacheSummaries(List<DailySummary> summaries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = summaries.map((summary) => summary.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_summariesCacheKey, jsonString);
      await _updateLastSync();
    } catch (e) {
      print('Error caching summaries: $e');
    }
  }

  // Get cached summaries
  Future<List<DailySummary>> getCachedSummaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_summariesCacheKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => DailySummary.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting cached summaries: $e');
      return [];
    }
  }

  // Save pending operation (for offline sync)
  Future<void> savePendingOperation(Map<String, dynamic> operation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getPendingOperations();
      existing.add(operation);
      final jsonString = jsonEncode(existing);
      await prefs.setString(_pendingOperationsKey, jsonString);
    } catch (e) {
      print('Error saving pending operation: $e');
    }
  }

  // Get pending operations
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_pendingOperationsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting pending operations: $e');
      return [];
    }
  }

  // Clear pending operations after successful sync
  Future<void> clearPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingOperationsKey);
    } catch (e) {
      print('Error clearing pending operations: $e');
    }
  }

  // Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSyncKey);

      if (timestamp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      print('Error getting last sync time: $e');
      return null;
    }
  }

  // Update last sync timestamp
  Future<void> _updateLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_lastSyncKey, now);
    } catch (e) {
      print('Error updating last sync: $e');
    }
  }

  // Check if data is stale (older than 1 hour)
  Future<bool> isCacheStale() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastSync);
    return difference.inHours > 1;
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_incomesCacheKey);
      await prefs.remove(_expensesCacheKey);
      await prefs.remove(_summariesCacheKey);
      await prefs.remove(_lastSyncKey);
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Check if we have any cached data
  Future<bool> hasCachedData() async {
    final incomes = await getCachedIncomes();
    final expenses = await getCachedExpenses();
    final summaries = await getCachedSummaries();

    return incomes.isNotEmpty || expenses.isNotEmpty || summaries.isNotEmpty;
  }
}
