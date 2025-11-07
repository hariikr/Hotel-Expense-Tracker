import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import 'expense_event.dart';
import 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final SupabaseService _supabaseService;
  RealtimeChannel? _expenseSubscription;

  ExpenseBloc(this._supabaseService) : super(const ExpenseInitial()) {
    on<LoadAllExpense>(_onLoadAllExpense);
    on<LoadExpenseByDate>(_onLoadExpenseByDate);
    on<UpsertExpense>(_onUpsertExpense);
    on<DeleteExpense>(_onDeleteExpense);
    on<ExpenseUpdated>(_onExpenseUpdated);

    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    _expenseSubscription = _supabaseService.subscribeToExpense(
      (payload) {
        add(const LoadAllExpense());
      },
    );
  }

  Future<void> _onLoadAllExpense(
    LoadAllExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseLoading());
    try {
      final expenses = await _supabaseService.fetchAllExpense();
      emit(ExpenseLoaded(expenses: expenses));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onLoadExpenseByDate(
    LoadExpenseByDate event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      final expense = await _supabaseService.fetchExpenseByDate(event.date);
      if (state is ExpenseLoaded) {
        emit((state as ExpenseLoaded).copyWith(selectedExpense: expense));
      } else {
        emit(ExpenseLoaded(
          expenses: const [],
          selectedExpense: expense,
        ));
      }
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onUpsertExpense(
    UpsertExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await _supabaseService.upsertExpense(event.expense);
      emit(const ExpenseOperationSuccess('Expense saved successfully'));
      add(const LoadAllExpense());
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await _supabaseService.deleteExpense(event.id);
      emit(const ExpenseOperationSuccess('Expense deleted successfully'));
      add(const LoadAllExpense());
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onExpenseUpdated(
    ExpenseUpdated event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is ExpenseLoaded) {
      emit((state as ExpenseLoaded).copyWith(expenses: event.expenses));
    } else {
      emit(ExpenseLoaded(expenses: event.expenses));
    }
  }

  @override
  Future<void> close() {
    if (_expenseSubscription != null) {
      _supabaseService.unsubscribe(_expenseSubscription!);
    }
    return super.close();
  }
}
