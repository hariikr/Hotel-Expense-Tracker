import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../features/settings/cubits/category_cubit.dart';
import '../../features/settings/models/category_model.dart';
import '../../features/transactions/cubits/transaction_cubit.dart';
import '../../features/transactions/models/expense_model.dart';
import '../../core/services/supabase_service.dart';
import '../../utils/app_theme.dart';

class AddExpenseScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const AddExpenseScreen({super.key, this.selectedDate});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late DateTime _selectedDate;
  final Map<String, TextEditingController> _amountControllers = {};
  bool _isLoading = false;

  // Category icons mapping
  static const Map<String, IconData> _categoryIcons = {
    'food': Icons.restaurant,
    'grocery': Icons.shopping_cart,
    'groceries': Icons.shopping_cart,
    'vegetables': Icons.eco,
    'meat': Icons.set_meal,
    'fish': Icons.set_meal,
    'chicken': Icons.egg_alt,
    'rice': Icons.rice_bowl,
    'milk': Icons.local_drink,
    'gas': Icons.local_gas_station,
    'lpg': Icons.local_fire_department,
    'electricity': Icons.flash_on,
    'water': Icons.water_drop,
    'rent': Icons.home,
    'salary': Icons.payments,
    'wages': Icons.payments,
    'staff': Icons.people,
    'maintenance': Icons.build,
    'cleaning': Icons.cleaning_services,
    'laundry': Icons.local_laundry_service,
    'transport': Icons.directions_car,
    'travel': Icons.flight,
    'fuel': Icons.local_gas_station,
    'phone': Icons.phone,
    'internet': Icons.wifi,
    'repair': Icons.handyman,
    'supplies': Icons.inventory,
    'equipment': Icons.devices,
    'tax': Icons.receipt_long,
    'insurance': Icons.security,
    'medical': Icons.medical_services,
    'other': Icons.more_horiz,
    'miscellaneous': Icons.more_horiz,
    'hotel': Icons.hotel,
    'room': Icons.bed,
    'kitchen': Icons.kitchen,
    'beverages': Icons.local_cafe,
    'drinks': Icons.local_bar,
  };

  // Category colors
  static const List<Color> _categoryColors = [
    Color(0xFFE53935), // Red
    Color(0xFFD81B60), // Pink
    Color(0xFF8E24AA), // Purple
    Color(0xFF5C6BC0), // Indigo
    Color(0xFF1E88E5), // Blue
    Color(0xFF00ACC1), // Cyan
    Color(0xFF00897B), // Teal
    Color(0xFF43A047), // Green
    Color(0xFF7CB342), // Light Green
    Color(0xFFFDD835), // Yellow
    Color(0xFFFF8F00), // Amber
    Color(0xFFF4511E), // Deep Orange
    Color(0xFF6D4C41), // Brown
    Color(0xFF546E7A), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    context.read<CategoryCubit>().loadCategories();
  }

  @override
  void dispose() {
    for (var controller in _amountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String categoryId) {
    if (!_amountControllers.containsKey(categoryId)) {
      _amountControllers[categoryId] = TextEditingController();
    }
    return _amountControllers[categoryId]!;
  }

  double get _totalAmount {
    double total = 0;
    for (var controller in _amountControllers.values) {
      final amount = double.tryParse(controller.text) ?? 0;
      total += amount;
    }
    return total;
  }

  IconData _getIconForCategory(String name) {
    final lower = name.toLowerCase();
    for (var entry in _categoryIcons.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return Icons.category;
  }

  Color _getColorForIndex(int index) {
    return _categoryColors[index % _categoryColors.length];
  }

  Future<void> _saveExpenses() async {
    // Collect all expenses with amounts
    final List<ExpenseModel> expensesToSave = [];

    for (var entry in _amountControllers.entries) {
      final amount = double.tryParse(entry.value.text) ?? 0;
      if (amount > 0) {
        expensesToSave.add(ExpenseModel(
          id: const Uuid().v4(),
          userId: SupabaseService().currentUserId!,
          amount: amount,
          date: _selectedDate,
          categoryId: entry.key,
          description: '',
        ));
      }
    }

    if (expensesToSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cubit = context.read<TransactionCubit>();

      for (var expense in expensesToSave) {
        await cubit.addExpense(expense);
      }

      // Reload dashboard data to show fresh data immediately
      await cubit.loadTransactions(DateTime.now());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${expensesToSave.length} expenses saved (₹${_totalAmount.toStringAsFixed(0)})'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Expenses'),
        backgroundColor: AppTheme.lossColor,
        elevation: 0,
        actions: [
          // Date selector
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: GestureDetector(
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
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CategoryLoaded) {
            final categories = state.expenseCategories;
            return Column(
              children: [
                // Categories list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final color = _getColorForIndex(index);
                      final icon = _getIconForCategory(category.name);
                      final controller = _getController(category.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            const SizedBox(width: 12),
                            // Category name
                            Expanded(
                              child: Text(
                                category.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Amount input
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: controller,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  prefixText: '₹ ',
                                  prefixStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                  hintText: '0',
                                  hintStyle:
                                      TextStyle(color: Colors.grey.shade400),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: color, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  isDense: true,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Total and Save button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, -4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Total amount display
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.lossColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
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
                      ),
                      const SizedBox(height: 12),
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading || _totalAmount <= 0
                              ? null
                              : _saveExpenses,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.lossColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _totalAmount > 0
                                      ? 'Save Expenses'
                                      : 'Enter amounts to save',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return const Center(child: Text('Loading categories...'));
        },
      ),
    );
  }
}
