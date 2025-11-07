import 'package:equatable/equatable.dart';
import '../../models/income.dart';

abstract class IncomeEvent extends Equatable {
  const IncomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllIncome extends IncomeEvent {
  const LoadAllIncome();
}

class LoadIncomeByDate extends IncomeEvent {
  final DateTime date;

  const LoadIncomeByDate(this.date);

  @override
  List<Object?> get props => [date];
}

class UpsertIncome extends IncomeEvent {
  final Income income;

  const UpsertIncome(this.income);

  @override
  List<Object?> get props => [income];
}

class DeleteIncome extends IncomeEvent {
  final String id;

  const DeleteIncome(this.id);

  @override
  List<Object?> get props => [id];
}

class IncomeUpdated extends IncomeEvent {
  final List<Income> incomes;

  const IncomeUpdated(this.incomes);

  @override
  List<Object?> get props => [incomes];
}
