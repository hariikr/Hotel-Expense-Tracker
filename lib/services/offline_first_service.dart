import '../models/income.dart';
import '../models/expense.dart';
import '../models/daily_summary.dart';
import 'supabase_service.dart';
import 'offline_cache_service.dart';
import 'network_service.dart';
import 'data_service.dart';

/// Offline-first service that prioritizes local cache and syncs when online
class OfflineFirstService implements DataService {
  final SupabaseService _supabaseService;
  final OfflineCacheService _cacheService = OfflineCacheService();
  final NetworkService _networkService = NetworkService();

  OfflineFirstService(this._supabaseService);

  // ==================== Income Operations ====================

  /// Fetch all income - returns cached data if offline
  Future<List<Income>> fetchAllIncome({String? context}) async {
    try {
      // Always try to fetch from server if online
      if (_networkService.isOnline) {
        final incomes = await _supabaseService.fetchAllIncome(context: context);
        // Cache the data
        await _cacheService.cacheIncomes(incomes);
        return incomes;
      } else {
        // If offline, return cached data
        print('Offline: Loading incomes from cache');
        return await _cacheService.getCachedIncomes();
      }
    } catch (e) {
      // If online fetch fails, fallback to cache
      print('Error fetching incomes, using cache: $e');
      return await _cacheService.getCachedIncomes();
    }
  }

  /// Fetch income by date - returns cached data if offline
  Future<Income?> fetchIncomeByDate(DateTime date,
      {String context = 'hotel'}) async {
    try {
      if (_networkService.isOnline) {
        final income =
            await _supabaseService.fetchIncomeByDate(date, context: context);
        // Update cache with all incomes
        if (income != null) {
          final allIncomes = await _cacheService.getCachedIncomes();
          final index = allIncomes.indexWhere((i) =>
              i.date.year == date.year &&
              i.date.month == date.month &&
              i.date.day == date.day &&
              i.context == context);
          if (index >= 0) {
            allIncomes[index] = income;
          } else {
            allIncomes.add(income);
          }
          await _cacheService.cacheIncomes(allIncomes);
        }
        return income;
      } else {
        // If offline, search in cache
        print('Offline: Loading income from cache');
        final cachedIncomes = await _cacheService.getCachedIncomes();
        try {
          return cachedIncomes.firstWhere(
            (income) =>
                income.date.year == date.year &&
                income.date.month == date.month &&
                income.date.day == date.day &&
                income.context == context,
          );
        } catch (_) {
          return null;
        }
      }
    } catch (e) {
      print('Error fetching income by date, using cache: $e');
      final cachedIncomes = await _cacheService.getCachedIncomes();
      try {
        return cachedIncomes.firstWhere(
          (income) =>
              income.date.year == date.year &&
              income.date.month == date.month &&
              income.date.day == date.day &&
              income.context == context,
        );
      } catch (_) {
        return null;
      }
    }
  }

  /// Upsert income - saves locally first, syncs when online
  Future<Income> upsertIncome(Income income) async {
    try {
      // Save to cache immediately
      final cachedIncomes = await _cacheService.getCachedIncomes();
      final index = cachedIncomes.indexWhere((i) => i.id == income.id);
      if (index >= 0) {
        cachedIncomes[index] = income;
      } else {
        cachedIncomes.add(income);
      }
      await _cacheService.cacheIncomes(cachedIncomes);

      // Try to sync to server if online
      if (_networkService.isOnline) {
        final result = await _supabaseService.upsertIncome(income);
        // Update cache with server result (has correct ID)
        final finalIndex = cachedIncomes.indexWhere(
            (i) => i.date == income.date && i.context == income.context);
        if (finalIndex >= 0) {
          cachedIncomes[finalIndex] = result;
          await _cacheService.cacheIncomes(cachedIncomes);
        }
        return result;
      } else {
        // If offline, save operation for later sync
        print('Offline: Income saved locally, will sync when online');
        await _cacheService.savePendingOperation({
          'type': 'upsert_income',
          'data': income.toJson(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        return income;
      }
    } catch (e) {
      print('Error upserting income: $e');
      // Even if online save fails, we have it in cache
      await _cacheService.savePendingOperation({
        'type': 'upsert_income',
        'data': income.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return income;
    }
  }

  /// Delete income - removes from cache, syncs deletion when online
  Future<void> deleteIncome(String id) async {
    try {
      // Remove from cache immediately
      final cachedIncomes = await _cacheService.getCachedIncomes();
      cachedIncomes.removeWhere((i) => i.id == id);
      await _cacheService.cacheIncomes(cachedIncomes);

      // Try to delete from server if online
      if (_networkService.isOnline) {
        await _supabaseService.deleteIncome(id);
      } else {
        // If offline, save operation for later sync
        print('Offline: Income deletion saved, will sync when online');
        await _cacheService.savePendingOperation({
          'type': 'delete_income',
          'id': id,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      print('Error deleting income: $e');
      await _cacheService.savePendingOperation({
        'type': 'delete_income',
        'id': id,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // ==================== Expense Operations ====================

  /// Fetch all expense - returns cached data if offline
  Future<List<Expense>> fetchAllExpense({String? context}) async {
    try {
      if (_networkService.isOnline) {
        final expenses =
            await _supabaseService.fetchAllExpense(context: context);
        await _cacheService.cacheExpenses(expenses);
        return expenses;
      } else {
        print('Offline: Loading expenses from cache');
        return await _cacheService.getCachedExpenses();
      }
    } catch (e) {
      print('Error fetching expenses, using cache: $e');
      return await _cacheService.getCachedExpenses();
    }
  }

  /// Fetch expense by date - returns cached data if offline
  Future<Expense?> fetchExpenseByDate(DateTime date,
      {String context = 'hotel'}) async {
    try {
      if (_networkService.isOnline) {
        final expense =
            await _supabaseService.fetchExpenseByDate(date, context: context);
        if (expense != null) {
          final allExpenses = await _cacheService.getCachedExpenses();
          final index = allExpenses.indexWhere((e) =>
              e.date.year == date.year &&
              e.date.month == date.month &&
              e.date.day == date.day &&
              e.context == context);
          if (index >= 0) {
            allExpenses[index] = expense;
          } else {
            allExpenses.add(expense);
          }
          await _cacheService.cacheExpenses(allExpenses);
        }
        return expense;
      } else {
        print('Offline: Loading expense from cache');
        final cachedExpenses = await _cacheService.getCachedExpenses();
        try {
          return cachedExpenses.firstWhere(
            (expense) =>
                expense.date.year == date.year &&
                expense.date.month == date.month &&
                expense.date.day == date.day &&
                expense.context == context,
          );
        } catch (_) {
          return null;
        }
      }
    } catch (e) {
      print('Error fetching expense by date, using cache: $e');
      final cachedExpenses = await _cacheService.getCachedExpenses();
      try {
        return cachedExpenses.firstWhere(
          (expense) =>
              expense.date.year == date.year &&
              expense.date.month == date.month &&
              expense.date.day == date.day &&
              expense.context == context,
        );
      } catch (_) {
        return null;
      }
    }
  }

  /// Upsert expense - saves locally first, syncs when online
  Future<Expense> upsertExpense(Expense expense) async {
    try {
      // Save to cache immediately
      final cachedExpenses = await _cacheService.getCachedExpenses();
      final index = cachedExpenses.indexWhere((e) => e.id == expense.id);
      if (index >= 0) {
        cachedExpenses[index] = expense;
      } else {
        cachedExpenses.add(expense);
      }
      await _cacheService.cacheExpenses(cachedExpenses);

      // Try to sync to server if online
      if (_networkService.isOnline) {
        final result = await _supabaseService.upsertExpense(expense);
        final finalIndex = cachedExpenses.indexWhere(
            (e) => e.date == expense.date && e.context == expense.context);
        if (finalIndex >= 0) {
          cachedExpenses[finalIndex] = result;
          await _cacheService.cacheExpenses(cachedExpenses);
        }
        return result;
      } else {
        print('Offline: Expense saved locally, will sync when online');
        await _cacheService.savePendingOperation({
          'type': 'upsert_expense',
          'data': expense.toJson(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        return expense;
      }
    } catch (e) {
      print('Error upserting expense: $e');
      await _cacheService.savePendingOperation({
        'type': 'upsert_expense',
        'data': expense.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return expense;
    }
  }

  /// Delete expense - removes from cache, syncs deletion when online
  Future<void> deleteExpense(String id) async {
    try {
      // Remove from cache immediately
      final cachedExpenses = await _cacheService.getCachedExpenses();
      cachedExpenses.removeWhere((e) => e.id == id);
      await _cacheService.cacheExpenses(cachedExpenses);

      // Try to delete from server if online
      if (_networkService.isOnline) {
        await _supabaseService.deleteExpense(id);
      } else {
        print('Offline: Expense deletion saved, will sync when online');
        await _cacheService.savePendingOperation({
          'type': 'delete_expense',
          'id': id,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      print('Error deleting expense: $e');
      await _cacheService.savePendingOperation({
        'type': 'delete_expense',
        'id': id,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // ==================== Daily Summary Operations ====================

  /// Fetch all daily summaries - returns cached data if offline
  @override
  Future<List<DailySummary>> fetchAllDailySummaries({String? context}) async {
    try {
      if (_networkService.isOnline) {
        final summaries =
            await _supabaseService.fetchAllDailySummaries(context: context);
        await _cacheService.cacheSummaries(summaries);
        return summaries;
      } else {
        print('Offline: Loading summaries from cache');
        return await _cacheService.getCachedSummaries();
      }
    } catch (e) {
      print('Error fetching summaries, using cache: $e');
      return await _cacheService.getCachedSummaries();
    }
  }

  // ==================== Analytics Operations ====================

  /// Get the best profit day from a list of summaries
  @override
  DailySummary? getBestProfitDay(List<DailySummary> summaries) {
    if (summaries.isEmpty) return null;
    return summaries.reduce(
        (current, next) => next.profit > current.profit ? next : current);
  }

  /// Calculate weekly summary
  @override
  Future<Map<String, double>> fetchWeeklySummary(DateTime weekStart,
      {String? context}) async {
    try {
      if (_networkService.isOnline) {
        return await _supabaseService.fetchWeeklySummary(weekStart,
            context: context);
      } else {
        // Calculate from cached data
        final weekEnd = weekStart.add(const Duration(days: 7));
        final allSummaries = await _cacheService.getCachedSummaries();

        final weekSummaries = allSummaries.where((summary) {
          return summary.date
                  .isAfter(weekStart.subtract(const Duration(days: 1))) &&
              summary.date.isBefore(weekEnd);
        }).toList();

        double totalIncome = 0;
        double totalExpense = 0;
        double totalProfit = 0;

        for (var summary in weekSummaries) {
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
    } catch (e) {
      print('Error fetching weekly summary, calculating from cache: $e');
      final weekEnd = weekStart.add(const Duration(days: 7));
      final allSummaries = await _cacheService.getCachedSummaries();

      final weekSummaries = allSummaries.where((summary) {
        return summary.date
                .isAfter(weekStart.subtract(const Duration(days: 1))) &&
            summary.date.isBefore(weekEnd);
      }).toList();

      double totalIncome = 0;
      double totalExpense = 0;
      double totalProfit = 0;

      for (var summary in weekSummaries) {
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
  }

  /// Calculate monthly summary
  @override
  Future<Map<String, double>> fetchMonthlySummary(int year, int month,
      {String? context}) async {
    try {
      if (_networkService.isOnline) {
        return await _supabaseService.fetchMonthlySummary(year, month,
            context: context);
      } else {
        // Calculate from cached data
        final allSummaries = await _cacheService.getCachedSummaries();

        final monthSummaries = allSummaries.where((summary) {
          return summary.date.year == year && summary.date.month == month;
        }).toList();

        double totalIncome = 0;
        double totalExpense = 0;
        double totalProfit = 0;

        for (var summary in monthSummaries) {
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
    } catch (e) {
      print('Error fetching monthly summary, calculating from cache: $e');
      final allSummaries = await _cacheService.getCachedSummaries();

      final monthSummaries = allSummaries.where((summary) {
        return summary.date.year == year && summary.date.month == month;
      }).toList();

      double totalIncome = 0;
      double totalExpense = 0;
      double totalProfit = 0;

      for (var summary in monthSummaries) {
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
  }

  // ==================== Sync Operations ====================

  /// Sync all pending operations to server
  Future<void> syncPendingOperations() async {
    if (!_networkService.isOnline) {
      print('Cannot sync: Device is offline');
      return;
    }

    try {
      final pendingOps = await _cacheService.getPendingOperations();
      if (pendingOps.isEmpty) {
        print('No pending operations to sync');
        return;
      }

      print('Syncing ${pendingOps.length} pending operations...');

      for (final op in pendingOps) {
        try {
          switch (op['type']) {
            case 'upsert_income':
              final income =
                  Income.fromJson(op['data'] as Map<String, dynamic>);
              await _supabaseService.upsertIncome(income);
              break;
            case 'delete_income':
              await _supabaseService.deleteIncome(op['id'] as String);
              break;
            case 'upsert_expense':
              final expense =
                  Expense.fromJson(op['data'] as Map<String, dynamic>);
              await _supabaseService.upsertExpense(expense);
              break;
            case 'delete_expense':
              await _supabaseService.deleteExpense(op['id'] as String);
              break;
          }
        } catch (e) {
          print('Failed to sync operation: ${op['type']}, error: $e');
          // Continue with other operations
        }
      }

      // Clear pending operations after successful sync
      await _cacheService.clearPendingOperations();
      print('Sync completed successfully');

      // Refresh cache from server
      await refreshCache();
    } catch (e) {
      print('Error during sync: $e');
    }
  }

  /// Refresh cache from server (when online)
  Future<void> refreshCache() async {
    if (!_networkService.isOnline) {
      print('Cannot refresh cache: Device is offline');
      return;
    }

    try {
      print('Refreshing cache from server...');
      final incomes = await _supabaseService.fetchAllIncome();
      final expenses = await _supabaseService.fetchAllExpense();
      final summaries = await _supabaseService.fetchAllDailySummaries();

      await _cacheService.cacheIncomes(incomes);
      await _cacheService.cacheExpenses(expenses);
      await _cacheService.cacheSummaries(summaries);

      print('Cache refreshed successfully');
    } catch (e) {
      print('Error refreshing cache: $e');
    }
  }

  /// Check if there are pending operations
  Future<bool> hasPendingOperations() async {
    final pending = await _cacheService.getPendingOperations();
    return pending.isNotEmpty;
  }

  /// Get count of pending operations
  Future<int> getPendingOperationsCount() async {
    final pending = await _cacheService.getPendingOperations();
    return pending.length;
  }
}
