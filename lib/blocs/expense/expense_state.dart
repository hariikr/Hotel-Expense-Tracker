import 'package:equatable/equatable.dart';
import '../../models/expense.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();
}

class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();
}

class ExpenseLoaded extends ExpenseState {
  final List<Expense> expenses;
  final Expense? selectedExpense;

  const ExpenseLoaded({
    required this.expenses,
    this.selectedExpense,
  });

  ExpenseLoaded copyWith({
    List<Expense>? expenses,
    Expense? selectedExpense,
  }) {
    return ExpenseLoaded(
      expenses: expenses ?? this.expenses,
      selectedExpense: selectedExpense ?? this.selectedExpense,
    );
  }

  @override
  List<Object?> get props => [expenses, selectedExpense];
}

class ExpenseError extends ExpenseState {
  final String message;

  const ExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}

class ExpenseOperationSuccess extends ExpenseState {
  final String message;

  const ExpenseOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
