import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/data_service.dart';
import '../../services/supabase_service.dart';
import 'income_event.dart';
import 'income_state.dart';

class IncomeBloc extends Bloc<IncomeEvent, IncomeState> {
  final DataService _dataService;
  final SupabaseService? _supabaseService;
  RealtimeChannel? _incomeSubscription;

  IncomeBloc(this._dataService)
      : _supabaseService =
            _dataService is SupabaseService ? _dataService : null,
        super(const IncomeInitial()) {
    on<LoadAllIncome>(_onLoadAllIncome);
    on<LoadIncomeByDate>(_onLoadIncomeByDate);
    on<UpsertIncome>(_onUpsertIncome);
    on<DeleteIncome>(_onDeleteIncome);
    on<IncomeUpdated>(_onIncomeUpdated);

    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    if (_supabaseService != null) {
      _incomeSubscription = _supabaseService!.subscribeToIncome(
        (payload) {
          add(const LoadAllIncome());
        },
      );
    }
  }

  Future<void> _onLoadAllIncome(
    LoadAllIncome event,
    Emitter<IncomeState> emit,
  ) async {
    emit(const IncomeLoading());
    try {
      final incomes = await _dataService.fetchAllIncome();
      emit(IncomeLoaded(incomes: incomes));
    } catch (e) {
      emit(IncomeError(e.toString()));
    }
  }

  Future<void> _onLoadIncomeByDate(
    LoadIncomeByDate event,
    Emitter<IncomeState> emit,
  ) async {
    try {
      final income = await _dataService.fetchIncomeByDate(event.date,
          context: event.context);
      if (state is IncomeLoaded) {
        emit((state as IncomeLoaded).copyWith(selectedIncome: income));
      } else {
        emit(IncomeLoaded(
          incomes: const [],
          selectedIncome: income,
        ));
      }
    } catch (e) {
      emit(IncomeError(e.toString()));
    }
  }

  Future<void> _onUpsertIncome(
    UpsertIncome event,
    Emitter<IncomeState> emit,
  ) async {
    try {
      await _dataService.upsertIncome(event.income);
      emit(const IncomeOperationSuccess('Income saved successfully'));
      add(const LoadAllIncome());
    } catch (e) {
      emit(IncomeError(e.toString()));
    }
  }

  Future<void> _onDeleteIncome(
    DeleteIncome event,
    Emitter<IncomeState> emit,
  ) async {
    try {
      await _dataService.deleteIncome(event.id);
      emit(const IncomeOperationSuccess('Income deleted successfully'));
      add(const LoadAllIncome());
    } catch (e) {
      emit(IncomeError(e.toString()));
    }
  }

  Future<void> _onIncomeUpdated(
    IncomeUpdated event,
    Emitter<IncomeState> emit,
  ) async {
    if (state is IncomeLoaded) {
      emit((state as IncomeLoaded).copyWith(incomes: event.incomes));
    } else {
      emit(IncomeLoaded(incomes: event.incomes));
    }
  }

  @override
  Future<void> close() {
    if (_incomeSubscription != null && _supabaseService != null) {
      _supabaseService!.unsubscribe(_incomeSubscription!);
    }
    return super.close();
  }
}
