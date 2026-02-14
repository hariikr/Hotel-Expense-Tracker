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
  final double allTimeTotalExpense;
  final double allTimeTotalIncome;
  final int _loadTimestamp;

  TransactionLoaded({
    this.expenses = const [],
    this.incomes = const [],
    required this.selectedDate,
    this.allTimeTotalExpense = 0,
    this.allTimeTotalIncome = 0,
    int? loadTimestamp,
  }) : _loadTimestamp = loadTimestamp ?? DateTime.now().millisecondsSinceEpoch;

  // Daily totals (from the filtered list)
  double get dailyExpense => expenses.fold(0, (sum, item) => sum + item.amount);
  double get dailyIncome => incomes.fold(0, (sum, item) => sum + item.amount);
  double get dailyProfit => dailyIncome - dailyExpense;

  // Keep old getters for backward compatibility
  double get totalExpense => expenses.fold(0, (sum, item) => sum + item.amount);
  double get totalIncome => incomes.fold(0, (sum, item) => sum + item.amount);
  double get profit => totalIncome - totalExpense;

  // All-time totals
  double get allTimeProfit => allTimeTotalIncome - allTimeTotalExpense;

  @override
  List<Object> get props => [
        expenses,
        incomes,
        selectedDate,
        allTimeTotalExpense,
        allTimeTotalIncome,
        _loadTimestamp
      ];

  TransactionLoaded copyWith({
    List<ExpenseModel>? expenses,
    List<IncomeModel>? incomes,
    DateTime? selectedDate,
    double? allTimeTotalExpense,
    double? allTimeTotalIncome,
  }) {
    return TransactionLoaded(
      expenses: expenses ?? this.expenses,
      incomes: incomes ?? this.incomes,
      selectedDate: selectedDate ?? this.selectedDate,
      allTimeTotalExpense: allTimeTotalExpense ?? this.allTimeTotalExpense,
      allTimeTotalIncome: allTimeTotalIncome ?? this.allTimeTotalIncome,
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

      // Fetch daily and all-time data in parallel
      final results = await Future.wait([
        _repository.getExpenses(date: date),
        _repository.getIncomes(date: date),
        _repository.getTotalExpenseAmount(),
        _repository.getTotalIncomeAmount(),
      ]);

      final expenses = results[0] as List<ExpenseModel>;
      final incomes = results[1] as List<IncomeModel>;
      final allTimeExpense = results[2] as double;
      final allTimeIncome = results[3] as double;

      emit(TransactionLoaded(
        expenses: expenses,
        incomes: incomes,
        selectedDate: date,
        allTimeTotalExpense: allTimeExpense,
        allTimeTotalIncome: allTimeIncome,
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
