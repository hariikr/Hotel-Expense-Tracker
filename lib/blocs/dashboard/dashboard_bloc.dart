import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';
import '../../utils/app_logger.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final SupabaseService _supabaseService;
  RealtimeChannel? _summarySubscription;

  DashboardBloc(this._supabaseService) : super(const DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshDashboardData>(_onRefreshDashboardData);
    on<LoadWeeklySummary>(_onLoadWeeklySummary);
    on<LoadMonthlySummary>(_onLoadMonthlySummary);
    on<DailySummaryUpdated>(_onDailySummaryUpdated);
    on<DeleteDailyData>(_onDeleteDailyData);

    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    _summarySubscription = _supabaseService.subscribeToDailySummary(
      (payload) {
        add(const RefreshDashboardData());
      },
    );
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    AppLogger.functionEntry('_onLoadDashboardData');
    emit(const DashboardLoading());
    try {
      AppLogger.databaseOperation('SELECT', 'daily_summaries',
          criteria: {'context': 'hotel'});
      final summaries =
          await _supabaseService.fetchAllDailySummaries(context: 'hotel');
      final bestProfit = _supabaseService.getBestProfitDay(summaries);

      double totalIncome = 0;
      double totalExpense = 0;

      for (var summary in summaries) {
        totalIncome += summary.totalIncome;
        totalExpense += summary.totalExpense;
      }

      emit(DashboardLoaded(
        allSummaries: summaries,
        bestProfitDay: bestProfit,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        totalProfit: totalIncome - totalExpense,
        selectedContext: 'hotel',
      ));
      AppLogger.functionExit('_onLoadDashboardData', result: 'success');
    } catch (e, stackTrace) {
      AppLogger.e('_onLoadDashboardData error: $e', stackTrace: stackTrace);
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onRefreshDashboardData(
    RefreshDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    AppLogger.functionEntry('_onRefreshDashboardData');
    if (state is DashboardLoaded) {
      try {
        AppLogger.databaseOperation('SELECT', 'daily_summaries',
            criteria: {'context': 'hotel'});
        final summaries =
            await _supabaseService.fetchAllDailySummaries(context: 'hotel');
        final bestProfit = _supabaseService.getBestProfitDay(summaries);

        double totalIncome = 0;
        double totalExpense = 0;

        for (var summary in summaries) {
          totalIncome += summary.totalIncome;
          totalExpense += summary.totalExpense;
        }

        emit((state as DashboardLoaded).copyWith(
          allSummaries: summaries,
          bestProfitDay: bestProfit,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          totalProfit: totalIncome - totalExpense,
          selectedContext: 'hotel',
        ));
        AppLogger.functionExit('_onRefreshDashboardData', result: 'success');
      } catch (e, stackTrace) {
        AppLogger.e('_onRefreshDashboardData error: $e',
            stackTrace: stackTrace);
        emit(DashboardError(e.toString()));
      }
    } else {
      AppLogger.w('_onRefreshDashboardData: state is not DashboardLoaded');
    }
  }

  Future<void> _onLoadWeeklySummary(
    LoadWeeklySummary event,
    Emitter<DashboardState> emit,
  ) async {
    AppLogger.functionEntry('_onLoadWeeklySummary',
        params: {'weekStart': event.weekStart});
    if (state is DashboardLoaded) {
      try {
        AppLogger.databaseOperation('SELECT', 'weekly_summary',
            criteria: {'week_start': event.weekStart, 'context': 'hotel'});
        final weeklySummary = await _supabaseService
            .fetchWeeklySummary(event.weekStart, context: 'hotel');
        emit((state as DashboardLoaded).copyWith(
          weeklySummary: weeklySummary,
        ));
        AppLogger.functionExit('_onLoadWeeklySummary', result: 'success');
      } catch (e, stackTrace) {
        AppLogger.e('_onLoadWeeklySummary error: $e', stackTrace: stackTrace);
        // Keep the current state, just log the error
        print('Error loading weekly summary: $e');
      }
    } else {
      AppLogger.w('_onLoadWeeklySummary: state is not DashboardLoaded');
    }
  }

  Future<void> _onLoadMonthlySummary(
    LoadMonthlySummary event,
    Emitter<DashboardState> emit,
  ) async {
    AppLogger.functionEntry('_onLoadMonthlySummary',
        params: {'year': event.year, 'month': event.month});
    if (state is DashboardLoaded) {
      try {
        AppLogger.databaseOperation('SELECT', 'monthly_summary', criteria: {
          'year': event.year,
          'month': event.month,
          'context': 'hotel'
        });
        final monthlySummary = await _supabaseService
            .fetchMonthlySummary(event.year, event.month, context: 'hotel');
        emit((state as DashboardLoaded).copyWith(
          monthlySummary: monthlySummary,
        ));
        AppLogger.functionExit('_onLoadMonthlySummary', result: 'success');
      } catch (e, stackTrace) {
        AppLogger.e('_onLoadMonthlySummary error: $e', stackTrace: stackTrace);
        // Keep the current state, just log the error
        print('Error loading monthly summary: $e');
      }
    } else {
      AppLogger.w('_onLoadMonthlySummary: state is not DashboardLoaded');
    }
  }

  Future<void> _onDailySummaryUpdated(
    DailySummaryUpdated event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final bestProfit = _supabaseService.getBestProfitDay(event.summaries);

      double totalIncome = 0;
      double totalExpense = 0;

      for (var summary in event.summaries) {
        totalIncome += summary.totalIncome;
        totalExpense += summary.totalExpense;
      }

      final totalProfit = totalIncome - totalExpense;

      emit((state as DashboardLoaded).copyWith(
        allSummaries: event.summaries,
        bestProfitDay: bestProfit,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        totalProfit: totalProfit,
      ));
    }
  }

  Future<void> _onDeleteDailyData(
    DeleteDailyData event,
    Emitter<DashboardState> emit,
  ) async {
    AppLogger.functionEntry('_onDeleteDailyData',
        params: {'date': event.date, 'context': event.context});
    if (state is DashboardLoaded) {
      try {
        // Get all income records for the specific date and context
        AppLogger.databaseOperation('SELECT', 'income',
            criteria: {'date': event.date, 'context': event.context});
        final incomeRecords = await _supabaseService.fetchIncomeByDate(
          event.date,
          context: event.context,
        );
        if (incomeRecords != null) {
          AppLogger.databaseOperation('DELETE', 'income',
              criteria: {'id': incomeRecords.id});
          await _supabaseService.deleteIncome(incomeRecords.id);
          AppLogger.i('Deleted income record: ${incomeRecords.id}');
        }

        // Get all expense records for the specific date and context
        AppLogger.databaseOperation('SELECT', 'expense',
            criteria: {'date': event.date, 'context': event.context});
        final expenseRecords = await _supabaseService.fetchExpenseByDate(
          event.date,
          context: event.context,
        );
        if (expenseRecords != null) {
          AppLogger.databaseOperation('DELETE', 'expense',
              criteria: {'id': expenseRecords.id});
          await _supabaseService.deleteExpense(expenseRecords.id);
          AppLogger.i('Deleted expense record: ${expenseRecords.id}');
        }

        AppLogger.i(
            'Data for ${event.date} (${event.context}) deleted successfully, reloading dashboard');
        // Reload the dashboard data to reflect the deletion
        add(const LoadDashboardData());
        AppLogger.functionExit('_onDeleteDailyData', result: 'success');
      } catch (e, stackTrace) {
        AppLogger.e('_onDeleteDailyData error: $e', stackTrace: stackTrace);
        // If there's an error, emit error state or just log it and continue
        print('Error deleting daily data: $e');
      }
    } else {
      AppLogger.w('_onDeleteDailyData: state is not DashboardLoaded');
    }
  }

  @override
  Future<void> close() {
    if (_summarySubscription != null) {
      _supabaseService.unsubscribe(_summarySubscription!);
    }
    return super.close();
  }
}
