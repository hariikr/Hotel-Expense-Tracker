import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../transactions/models/expense_model.dart';
import '../../transactions/models/income_model.dart';
import '../../transactions/repositories/transaction_repository.dart';
import '../../billing/models/bill_model.dart';
import '../../billing/repositories/bill_repository.dart';

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
  final List<BillModel> bills;
  final double allTimeTotalExpense;
  final double allTimeTotalIncome;
  final int _loadTimestamp;

  TransactionLoaded({
    this.expenses = const [],
    this.incomes = const [],
    this.bills = const [],
    required this.selectedDate,
    this.allTimeTotalExpense = 0,
    this.allTimeTotalIncome = 0,
    int? loadTimestamp,
  }) : _loadTimestamp = loadTimestamp ?? DateTime.now().millisecondsSinceEpoch;

  // Daily totals (from the filtered list)
  double get dailyExpense => expenses.fold(0, (sum, item) => sum + item.amount);
  double get dailyIncome => incomes.fold(0, (sum, item) => sum + item.amount);
  double get dailyProfit => dailyIncome - dailyExpense;

  // Specific Order income for the dashboard
  double get dailyOrderIncome => incomes
      .where((i) => i.categoryName?.toLowerCase() == 'order')
      .fold(0.0, (sum, item) => sum + item.amount);

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
        bills,
        selectedDate,
        allTimeTotalExpense,
        allTimeTotalIncome,
        _loadTimestamp
      ];

  TransactionLoaded copyWith({
    List<ExpenseModel>? expenses,
    List<IncomeModel>? incomes,
    List<BillModel>? bills,
    DateTime? selectedDate,
    double? allTimeTotalExpense,
    double? allTimeTotalIncome,
  }) {
    return TransactionLoaded(
      expenses: expenses ?? this.expenses,
      incomes: incomes ?? this.incomes,
      bills: bills ?? this.bills,
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
  final BillRepository _billRepository;

  TransactionCubit(
      {TransactionRepository? repository, BillRepository? billRepository})
      : _repository = repository ?? TransactionRepository(),
        _billRepository = billRepository ?? BillRepository(),
        super(TransactionInitial());

  Future<void> loadTransactions(DateTime date) async {
    try {
      emit(TransactionLoading());

      // Fetch daily and all-time data in parallel
      final results = await Future.wait([
        _repository.getExpenses(date: date),
        _repository.getIncomes(date: date),
        _billRepository.getBills(date: date),
        _repository.getTotalExpenseAmount(),
        _repository.getTotalIncomeAmount(),
      ]);

      if (results.any((r) => r == null)) {
        print('⚠️ Warning: Some transaction results are null');
      }

      final expenses = (results[0] as List<ExpenseModel>?) ?? [];
      final incomes = (results[1] as List<IncomeModel>?) ?? [];
      final bills = (results[2] as List<BillModel>?) ?? [];
      final allTimeExpense = (results[3] as double?) ?? 0.0;
      final allTimeIncome = (results[4] as double?) ?? 0.0;

      emit(TransactionLoaded(
        expenses: expenses,
        incomes: incomes,
        bills: bills,
        selectedDate: date,
        allTimeTotalExpense: allTimeExpense,
        allTimeTotalIncome: allTimeIncome,
      ));
    } catch (e, stack) {
      print('❌ Error in loadTransactions: $e');
      print(stack);
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
        bills: const [], // Range might not need bills or we can fetch them if needed
        selectedDate: start, // Just a reference
      ));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      final newExpense = await _repository.addExpense(expense);

      // Update UI state only if loaded and date matches
      if (state is TransactionLoaded) {
        final currentState = state as TransactionLoaded;
        if (isSameDay(newExpense.date, currentState.selectedDate)) {
          final updatedList = List<ExpenseModel>.from(currentState.expenses)
            ..insert(0, newExpense);
          emit(currentState.copyWith(expenses: updatedList));
        }
      }
    } catch (e) {
      if (state is TransactionLoaded) {
        emit(TransactionError(e.toString()));
        loadTransactions((state as TransactionLoaded).selectedDate);
      }
    }
  }

  Future<void> addIncome(IncomeModel income) async {
    try {
      final newIncome = await _repository.addIncome(income);

      // Update UI state only if loaded and date matches
      if (state is TransactionLoaded) {
        final currentState = state as TransactionLoaded;
        if (isSameDay(newIncome.date, currentState.selectedDate)) {
          final updatedList = List<IncomeModel>.from(currentState.incomes)
            ..insert(0, newIncome);
          emit(currentState.copyWith(incomes: updatedList));
        }
      }
    } catch (e) {
      if (state is TransactionLoaded) {
        emit(TransactionError(e.toString()));
        loadTransactions((state as TransactionLoaded).selectedDate);
      }
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
