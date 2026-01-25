import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/category_model.dart';
import '../repositories/category_repository.dart';

// States
abstract class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<CategoryModel> expenseCategories;
  final List<CategoryModel> incomeCategories;

  const CategoryLoaded({
    this.expenseCategories = const [],
    this.incomeCategories = const [],
  });

  @override
  List<Object> get props => [expenseCategories, incomeCategories];

  CategoryLoaded copyWith({
    List<CategoryModel>? expenseCategories,
    List<CategoryModel>? incomeCategories,
  }) {
    return CategoryLoaded(
      expenseCategories: expenseCategories ?? this.expenseCategories,
      incomeCategories: incomeCategories ?? this.incomeCategories,
    );
  }
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);
  @override
  List<Object> get props => [message];
}

// Cubit
class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository _repository;

  CategoryCubit({CategoryRepository? repository})
      : _repository = repository ?? CategoryRepository(),
        super(CategoryInitial());

  Future<void> loadCategories() async {
    try {
      emit(CategoryLoading());
      final expenses = await _repository.getExpenseCategories();
      final incomes = await _repository.getIncomeCategories();
      emit(CategoryLoaded(
          expenseCategories: expenses, incomeCategories: incomes));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> addCategory(String name, CategoryType type) async {
    if (state is! CategoryLoaded) return;

    try {
      final currentState = state as CategoryLoaded;
      // Optimistic update could be done here, but let's wait for DB

      final newCategory = await _repository.addCategory(name, type);

      if (type == CategoryType.expense) {
        final updatedList =
            List<CategoryModel>.from(currentState.expenseCategories)
              ..add(newCategory);
        emit(currentState.copyWith(expenseCategories: updatedList));
      } else {
        final updatedList =
            List<CategoryModel>.from(currentState.incomeCategories)
              ..add(newCategory);
        emit(currentState.copyWith(incomeCategories: updatedList));
      }
    } catch (e) {
      emit(CategoryError(e.toString()));
      // Reload to ensure consistency
      loadCategories();
    }
  }

  Future<void> deleteCategory(String id, CategoryType type) async {
    if (state is! CategoryLoaded) return;

    try {
      final currentState = state as CategoryLoaded;
      await _repository.deleteCategory(id, type);

      if (type == CategoryType.expense) {
        final updatedList =
            currentState.expenseCategories.where((c) => c.id != id).toList();
        emit(currentState.copyWith(expenseCategories: updatedList));
      } else {
        final updatedList =
            currentState.incomeCategories.where((c) => c.id != id).toList();
        emit(currentState.copyWith(incomeCategories: updatedList));
      }
    } catch (e) {
      emit(CategoryError(e.toString()));
      loadCategories();
    }
  }
}
