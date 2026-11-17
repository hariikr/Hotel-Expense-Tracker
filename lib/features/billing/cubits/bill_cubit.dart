import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_model.dart';
import '../repositories/bill_repository.dart';
import '../../transactions/cubits/transaction_cubit.dart';
import '../../transactions/models/income_model.dart';
import '../../settings/cubits/category_cubit.dart';
import '../../settings/repositories/category_repository.dart';
import '../../settings/models/category_model.dart';
import '../../../core/services/supabase_service.dart';

// States
abstract class BillState extends Equatable {
  const BillState();
  @override
  List<Object?> get props => [];
}

class BillInitial extends BillState {}

class BillLoading extends BillState {}

class BillLoaded extends BillState {
  final List<BillModel> bills;
  final int _loadTimestamp;

  BillLoaded({
    this.bills = const [],
    int? loadTimestamp,
  }) : _loadTimestamp = loadTimestamp ?? DateTime.now().millisecondsSinceEpoch;

  @override
  List<Object?> get props => [bills, _loadTimestamp];
}

class BillCreated extends BillState {
  final BillModel bill;
  const BillCreated(this.bill);
  @override
  List<Object?> get props => [bill];
}

class BillError extends BillState {
  final String message;
  const BillError(this.message);
  @override
  List<Object?> get props => [message];
}

class BillStatementLoaded extends BillState {
  final List<BillModel> bills;
  final String customerName;
  final DateTime startDate;
  final DateTime endDate;

  const BillStatementLoaded({
    required this.bills,
    required this.customerName,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [bills, customerName, startDate, endDate];
}

// Cubit
class BillCubit extends Cubit<BillState> {
  final BillRepository _repository;
  final CategoryRepository _categoryRepository;

  BillCubit(
      {BillRepository? repository, CategoryRepository? categoryRepository})
      : _repository = repository ?? BillRepository(),
        _categoryRepository = categoryRepository ?? CategoryRepository(),
        super(BillInitial());

  Future<void> loadBills() async {
    try {
      emit(BillLoading());
      final bills = await _repository.getBills();
      emit(BillLoaded(bills: bills));
    } catch (e) {
      emit(BillError(e.toString()));
    }
  }

  Future<BillModel?> createBill({
    required BillModel bill,
    required List<BillItemModel> items,
    required TransactionCubit transactionCubit,
    required CategoryCubit categoryCubit,
  }) async {
    try {
      // Generate bill number
      final billNumber = await _repository.generateBillNumber(bill.billDate);
      final billWithNumber = bill.copyWith(billNumber: billNumber);

      // Create bill in DB
      final createdBill = await _repository.createBill(billWithNumber, items);

      // Auto-create income entry for this bill
      final userId = SupabaseService().currentUserId;
      if (userId != null) {
        // Robust category lookup: checking DB directly if Cubit state is not ready
        String? orderCategoryId;

        // 1. Get all income categories (Directly from Repository for reliability)
        final categories = await _categoryRepository.getIncomeCategories();

        if (categories.isNotEmpty) {
          // Priority 1: Exact match "Order"
          final exactOrder = categories.where((c) => c.name == 'Order');

          if (exactOrder.isNotEmpty) {
            orderCategoryId = exactOrder.first.id;
          } else {
            // Priority 2: Case-insensitive "order" or "orders"
            final fuzzyOrder = categories.where((c) {
              final name = c.name.toLowerCase();
              return name == 'order' ||
                  name == 'orders' ||
                  name.contains('order');
            });

            if (fuzzyOrder.isNotEmpty) {
              orderCategoryId = fuzzyOrder.first.id;
            } else {
              // Priority 3: Fallback to "billing"
              final billing = categories
                  .where((c) => c.name.toLowerCase().contains('billing'));
              if (billing.isNotEmpty) {
                orderCategoryId = billing.first.id;
              }
            }
          }
        }

        // 2. SELF-HEALING: If no "Order" category exists, CREATE IT!
        if (orderCategoryId == null) {
          try {
            final newCat = await _categoryRepository.addCategory(
                'Order', CategoryType.income);
            orderCategoryId = newCat.id;
            // Also tell CategoryCubit to reload
            categoryCubit.loadCategories();
          } catch (e) {
            // If creation fails due to unique constraint, try to fetch one last time
            final finalCheck = await _categoryRepository.getIncomeCategories();
            if (finalCheck.isNotEmpty) {
              orderCategoryId = finalCheck.first.id;
            }
          }
        }

        if (orderCategoryId != null) {
          final income = IncomeModel(
            id: const Uuid().v4(),
            userId: userId,
            amount: createdBill.totalAmount,
            date: createdBill.billDate,
            categoryId: orderCategoryId,
            description:
                'Order Bill #${createdBill.billNumber} - ${createdBill.customerName}',
          );

          await transactionCubit.addIncome(income);

          // Run background tasks in parallel to save time
          await Future.wait([
            _repository.updateBillIncomeId(createdBill.id, income.id),
            _repository.autoSaveDishesFromBill(items),
          ]);
        } else {
          // If no category found, still save dishes
          await _repository.autoSaveDishesFromBill(items);
        }
      }

      // Reload bills list
      await loadBills();

      return createdBill;
    } catch (e) {
      emit(BillError(e.toString()));
      return null;
    }
  }

  Future<void> deleteBill(String id) async {
    try {
      await _repository.deleteBill(id);
      await loadBills();
    } catch (e) {
      emit(BillError(e.toString()));
    }
  }

  // ===== STATEMENTS =====

  Future<void> getCustomerStatement({
    required String query,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      emit(BillLoading());
      final bills = await _repository.getBillsByCustomer(
        query: query,
        startDate: startDate,
        endDate: endDate,
      );
      emit(BillStatementLoaded(
        bills: bills,
        customerName: query,
        startDate: startDate,
        endDate: endDate,
      ));
    } catch (e) {
      emit(BillError(e.toString()));
    }
  }

  Future<List<Map<String, String>>> getDistinctCustomers() async {
    return await _repository.getAllDistinctCustomers();
  }
}
