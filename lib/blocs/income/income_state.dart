import 'package:equatable/equatable.dart';
import '../../models/income.dart';

abstract class IncomeState extends Equatable {
  const IncomeState();

  @override
  List<Object?> get props => [];
}

class IncomeInitial extends IncomeState {
  const IncomeInitial();
}

class IncomeLoading extends IncomeState {
  const IncomeLoading();
}

class IncomeLoaded extends IncomeState {
  final List<Income> incomes;
  final Income? selectedIncome;

  const IncomeLoaded({
    required this.incomes,
    this.selectedIncome,
  });

  IncomeLoaded copyWith({
    List<Income>? incomes,
    Income? selectedIncome,
  }) {
    return IncomeLoaded(
      incomes: incomes ?? this.incomes,
      selectedIncome: selectedIncome ?? this.selectedIncome,
    );
  }

  @override
  List<Object?> get props => [incomes, selectedIncome];
}

class IncomeError extends IncomeState {
  final String message;

  const IncomeError(this.message);

  @override
  List<Object?> get props => [message];
}

class IncomeOperationSuccess extends IncomeState {
  final String message;

  const IncomeOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
