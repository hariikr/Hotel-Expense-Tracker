import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final SupabaseService _supabaseService;
  RealtimeChannel? _summarySubscription;

  DashboardBloc(this._supabaseService) : super(const DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshDashboardData>(_onRefreshDashboardData);
    on<LoadWeeklySummary>(_onLoadWeeklySummary);
    on<LoadMonthlySummary>(_onLoadMonthlySummary);
    on<DailySummaryUpdated>(_onDailySummaryUpdated);
    on<ChangeContext>(_onChangeContext);
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
    emit(const DashboardLoading());
    try {
      final context = event.context ?? 'hotel';
      final summaries = await _supabaseService.fetchAllDailySummaries(context: context);
      final bestProfit = _supabaseService.getBestProfitDay(summaries);

      double totalIncome = 0;
      double totalExpense = 0;

      for (var summary in summaries) {
        totalIncome += summary.totalIncome;
        totalExpense += summary.totalExpense;
      }

      // For house context, income is the total profit from hotel
      if (context == 'house') {
        final hotelSummaries = await _supabaseService.fetchAllDailySummaries(context: 'hotel');
        double hotelTotalIncome = 0;
        double hotelTotalExpense = 0;
        for (var summary in hotelSummaries) {
          hotelTotalIncome += summary.totalIncome;
          hotelTotalExpense += summary.totalExpense;
        }
        totalIncome = hotelTotalIncome - hotelTotalExpense; // Hotel profit as house income
      }

      emit(DashboardLoaded(
        allSummaries: summaries,
        bestProfitDay: bestProfit,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        totalProfit: totalIncome - totalExpense, // Recalculate profit
        selectedContext: context,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onRefreshDashboardData(
    RefreshDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      try {
        final context = event.context ?? (state as DashboardLoaded).selectedContext;
        final summaries = await _supabaseService.fetchAllDailySummaries(context: context);
        final bestProfit = _supabaseService.getBestProfitDay(summaries);

        double totalIncome = 0;
        double totalExpense = 0;

        for (var summary in summaries) {
          totalIncome += summary.totalIncome;
          totalExpense += summary.totalExpense;
        }

        // For house context, income is the total profit from hotel
        if (context == 'house') {
          final hotelSummaries = await _supabaseService.fetchAllDailySummaries(context: 'hotel');
          double hotelTotalIncome = 0;
          double hotelTotalExpense = 0;
          for (var summary in hotelSummaries) {
            hotelTotalIncome += summary.totalIncome;
            hotelTotalExpense += summary.totalExpense;
          }
          totalIncome = hotelTotalIncome - hotelTotalExpense; // Hotel profit as house income
        }

        emit((state as DashboardLoaded).copyWith(
          allSummaries: summaries,
          bestProfitDay: bestProfit,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          totalProfit: totalIncome - totalExpense, // Recalculate profit
          selectedContext: context,
        ));
      } catch (e) {
        emit(DashboardError(e.toString()));
      }
    }
  }

  Future<void> _onLoadWeeklySummary(
    LoadWeeklySummary event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      try {
        final context = event.context ?? (state as DashboardLoaded).selectedContext;
        final weeklySummary =
            await _supabaseService.fetchWeeklySummary(event.weekStart, context: context);
        emit((state as DashboardLoaded).copyWith(
          weeklySummary: weeklySummary,
        ));
      } catch (e) {
        // Keep the current state, just log the error
        print('Error loading weekly summary: $e');
      }
    }
  }

  Future<void> _onLoadMonthlySummary(
    LoadMonthlySummary event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      try {
        final context = event.context ?? (state as DashboardLoaded).selectedContext;
        final monthlySummary =
            await _supabaseService.fetchMonthlySummary(event.year, event.month, context: context);
        emit((state as DashboardLoaded).copyWith(
          monthlySummary: monthlySummary,
        ));
      } catch (e) {
        // Keep the current state, just log the error
        print('Error loading monthly summary: $e');
      }
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

  void _onChangeContext(
    ChangeContext event,
    Emitter<DashboardState> emit,
  ) {
    if (state is DashboardLoaded) {
      emit((state as DashboardLoaded).copyWith(
        selectedContext: event.context,
      ));
      // Reload data with new context
      add(LoadDashboardData(context: event.context));
    }
  }

  Future<void> _onDeleteDailyData(
    DeleteDailyData event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      try {
        // Get all income records for the specific date and context
        final incomeRecords = await _supabaseService.fetchIncomeByDate(
          event.date,
          context: event.context,
        );
        if (incomeRecords != null) {
          await _supabaseService.deleteIncome(incomeRecords.id);
        }

        // Get all expense records for the specific date and context
        final expenseRecords = await _supabaseService.fetchExpenseByDate(
          event.date,
          context: event.context,
        );
        if (expenseRecords != null) {
          await _supabaseService.deleteExpense(expenseRecords.id);
        }

        // Reload the dashboard data to reflect the deletion
        add(LoadDashboardData(context: event.context));
      } catch (e) {
        // If there's an error, emit error state or just log it and continue
        print('Error deleting daily data: $e');
      }
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
