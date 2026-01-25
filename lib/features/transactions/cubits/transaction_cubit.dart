import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../transactions/models/expense_model.dart';
import '../../transactions/models/income_model.dart';
import '../../transactions/repositories/transaction_repository.dart';

// States
abstract class TransactionState extends Equatable {
  const TransactionState();
  @override
  List<Object> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<ExpenseModel> expenses;
  final List<IncomeModel> incomes;
  final DateTime selectedDate;

  const TransactionLoaded({
    this.expenses = const [],
    this.incomes = const [],
    required this.selectedDate,
  });

  double get totalExpense => expenses.fold(0, (sum, item) => sum + item.amount);
  double get totalIncome => incomes.fold(0, (sum, item) => sum + item.amount);
  double get profit => totalIncome - totalExpense;

  @override
  List<Object> get props => [expenses, incomes, selectedDate];

  TransactionLoaded copyWith({
    List<ExpenseModel>? expenses,
    List<IncomeModel>? incomes,
    DateTime? selectedDate,
  }) {
    return TransactionLoaded(
      expenses: expenses ?? this.expenses,
      incomes: incomes ?? this.incomes,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class TransactionError extends TransactionState {
  final String message;
  const TransactionError(this.message);
  @override
  List<Object> get props => [message];
}

// Cubit
class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository _repository;

  TransactionCubit({TransactionRepository? repository})
      : _repository = repository ?? TransactionRepository(),
        super(TransactionInitial());

  Future<void> loadTransactions(DateTime date) async {
    try {
      emit(TransactionLoading());
      final expenses = await _repository.getExpenses(date: date);
      final incomes = await _repository.getIncomes(date: date);

      emit(TransactionLoaded(
        expenses: expenses,
        incomes: incomes,
        selectedDate: date,
      ));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> loadTransactionsRange(DateTime start, DateTime end) async {
    try {
      emit(TransactionLoading());
      final expenses =
          await _repository.getExpenses(startDate: start, endDate: end);
      final incomes =
          await _repository.getIncomes(startDate: start, endDate: end);

      emit(TransactionLoaded(
        expenses: expenses,
        incomes: incomes,
        selectedDate: start, // Just a reference
      ));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> addExpense(ExpenseModel expense) async {
    if (state is! TransactionLoaded) return;
    final currentState = state as TransactionLoaded;

    try {
      final newExpense = await _repository.addExpense(expense);
      // Only update if date matches
      if (isSameDay(newExpense.date, currentState.selectedDate)) {
        final updatedList = List<ExpenseModel>.from(currentState.expenses)
          ..insert(0, newExpense); // Top of list
        emit(currentState.copyWith(expenses: updatedList));
      }
    } catch (e) {
      emit(TransactionError(e.toString()));
      loadTransactions(currentState.selectedDate);
    }
  }

  Future<void> addIncome(IncomeModel income) async {
    if (state is! TransactionLoaded) return;
    final currentState = state as TransactionLoaded;

    try {
      final newIncome = await _repository.addIncome(income);
      if (isSameDay(newIncome.date, currentState.selectedDate)) {
        final updatedList = List<IncomeModel>.from(currentState.incomes)
          ..insert(0, newIncome);
        emit(currentState.copyWith(incomes: updatedList));
      }
    } catch (e) {
      emit(TransactionError(e.toString()));
      loadTransactions(currentState.selectedDate);
    }
  }

  Future<void> deleteExpense(String id) async {
    if (state is! TransactionLoaded) return;
    final currentState = state as TransactionLoaded;
    try {
      await _repository.deleteExpense(id);
      final updatedList =
          currentState.expenses.where((e) => e.id != id).toList();
      emit(currentState.copyWith(expenses: updatedList));
    } catch (e) {
      emit(TransactionError(e.toString()));
      loadTransactions(currentState.selectedDate);
    }
  }

  Future<void> deleteIncome(String id) async {
    if (state is! TransactionLoaded) return;
    final currentState = state as TransactionLoaded;
    try {
      await _repository.deleteIncome(id);
      final updatedList =
          currentState.incomes.where((i) => i.id != id).toList();
      emit(currentState.copyWith(incomes: updatedList));
    } catch (e) {
      emit(TransactionError(e.toString()));
      loadTransactions(currentState.selectedDate);
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
