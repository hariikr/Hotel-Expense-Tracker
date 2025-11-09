import 'package:equatable/equatable.dart';
import '../../models/expense.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllExpense extends ExpenseEvent {
  const LoadAllExpense();
}

class LoadExpenseByDate extends ExpenseEvent {
  final DateTime date;
  final String context;

  const LoadExpenseByDate(this.date, {this.context = 'hotel'});

  @override
  List<Object?> get props => [date, context];
}

class UpsertExpense extends ExpenseEvent {
  final Expense expense;

  const UpsertExpense(this.expense);

  @override
  List<Object?> get props => [expense];
}

class DeleteExpense extends ExpenseEvent {
  final String id;

  const DeleteExpense(this.id);

  @override
  List<Object?> get props => [id];
}

class ExpenseUpdated extends ExpenseEvent {
  final List<Expense> expenses;

  const ExpenseUpdated(this.expenses);

  @override
  List<Object?> get props => [expenses];
}
