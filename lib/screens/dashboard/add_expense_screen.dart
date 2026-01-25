import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../features/settings/cubits/category_cubit.dart';
// Note: CategoryState comes from category_cubit.dart, no separate file
import '../../features/settings/models/category_model.dart';
import '../../features/transactions/cubits/transaction_cubit.dart';
import '../../features/transactions/models/expense_model.dart';
import '../../core/services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';

class AddExpenseScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const AddExpenseScreen({super.key, this.selectedDate});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late DateTime _selectedDate;
  final List<ExpenseItemController> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _addNewItem(); // Start with one empty item
    // Ensure categories are loaded
    context.read<CategoryCubit>().loadCategories();
  }

  void _addNewItem() {
    setState(() {
      _items.add(ExpenseItemController());
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    } else {
      // Just clear the last remaining item
      _items[0].amountController.clear();
      setState(() {
        _items[0].selectedCategory = null;
      });
    }
  }

  double get _totalAmount {
    return _items.fold(0, (sum, item) {
      return sum + (double.tryParse(item.amountController.text) ?? 0);
    });
  }

  Future<void> _saveExpenses() async {
    // Validate
    final validItems = _items
        .where((item) =>
            item.selectedCategory != null &&
            (double.tryParse(item.amountController.text) ?? 0) > 0)
        .toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter at least one valid expense')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cubit = context.read<TransactionCubit>();
      final userId = SupabaseService().currentUserId;
      if (userId == null) throw Exception('User not logged in');

      for (var item in validItems) {
        final amount = double.parse(item.amountController.text);
        final expense = ExpenseModel(
          id: const Uuid().v4(),
          userId: userId,
          amount: amount,
          date: _selectedDate,
          categoryId: item.selectedCategory!.id,
          description: '', // Optional description
        );

        await cubit.addExpense(expense);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expenses saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: AppTheme.lossColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Date Selector
          _buildDateSelector(),

          // Expense List
          Expanded(
            child: BlocBuilder<CategoryCubit, CategoryState>(
              builder: (context, state) {
                if (state is CategoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CategoryLoaded) {
                  final categories = state.expenseCategories;

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      return _buildExpenseItemRow(i, categories);
                    },
                  );
                }
                return const Center(child: Text('Loading categories...'));
              },
            ),
          ),

          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.lossColor,
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) {
            setState(() => _selectedDate = picked);
          }
        },
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              Formatters.formatDateFull(_selectedDate),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(Icons.edit, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItemRow(int index, List<CategoryModel> categories) {
    final controller = _items[index];

    return Dismissible(
      key: ObjectKey(controller),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeItem(index),
      background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(Icons.delete, color: Colors.white)),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Category Dropdown
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<CategoryModel>(
                  value: controller.selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => controller.selectedCategory = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Amount Field
              Expanded(
                flex: 1,
                child: TextField(
                  controller: controller.amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              // Delete Button (if multiple items)
              if (_items.length > 1)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => _removeItem(index),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 16)),
              Text(
                '₹${_totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lossColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addNewItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveExpenses,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Saving...' : 'Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lossColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ExpenseItemController {
  TextEditingController amountController = TextEditingController();
  CategoryModel? selectedCategory;
}
