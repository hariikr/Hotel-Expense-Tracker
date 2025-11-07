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
      final summaries = await _supabaseService.fetchAllDailySummaries();
      final bestProfit = _supabaseService.getBestProfitDay(summaries);

      double totalIncome = 0;
      double totalExpense = 0;
      double totalProfit = 0;

      for (var summary in summaries) {
        totalIncome += summary.totalIncome;
        totalExpense += summary.totalExpense;
        totalProfit += summary.profit;
      }

      emit(DashboardLoaded(
        allSummaries: summaries,
        bestProfitDay: bestProfit,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        totalProfit: totalProfit,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onRefreshDashboardData(
    RefreshDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final summaries = await _supabaseService.fetchAllDailySummaries();
      final bestProfit = _supabaseService.getBestProfitDay(summaries);

      double totalIncome = 0;
      double totalExpense = 0;
      double totalProfit = 0;

      for (var summary in summaries) {
        totalIncome += summary.totalIncome;
        totalExpense += summary.totalExpense;
        totalProfit += summary.profit;
      }

      if (state is DashboardLoaded) {
        emit((state as DashboardLoaded).copyWith(
          allSummaries: summaries,
          bestProfitDay: bestProfit,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          totalProfit: totalProfit,
        ));
      } else {
        emit(DashboardLoaded(
          allSummaries: summaries,
          bestProfitDay: bestProfit,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          totalProfit: totalProfit,
        ));
      }
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onLoadWeeklySummary(
    LoadWeeklySummary event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      try {
        final weeklySummary =
            await _supabaseService.fetchWeeklySummary(event.weekStart);
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
        final monthlySummary =
            await _supabaseService.fetchMonthlySummary(event.year, event.month);
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
      double totalProfit = 0;

      for (var summary in event.summaries) {
        totalIncome += summary.totalIncome;
        totalExpense += summary.totalExpense;
        totalProfit += summary.profit;
      }

      emit((state as DashboardLoaded).copyWith(
        allSummaries: event.summaries,
        bestProfitDay: bestProfit,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        totalProfit: totalProfit,
      ));
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
