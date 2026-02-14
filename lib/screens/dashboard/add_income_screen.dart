import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../features/settings/cubits/category_cubit.dart';
import '../../features/settings/models/category_model.dart';
import '../../features/transactions/cubits/transaction_cubit.dart';
import '../../features/transactions/models/income_model.dart';
import '../../core/services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';

class AddIncomeScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const AddIncomeScreen({super.key, this.selectedDate});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  late DateTime _selectedDate;
  final _onlineController = TextEditingController();
  final _offlineController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    // Ensure categories are loaded so we can find 'Online' and 'Offline'
    context.read<CategoryCubit>().loadCategories();
  }

  Future<void> _saveIncome() async {
    final onlineAmount = double.tryParse(_onlineController.text) ?? 0;
    final offlineAmount = double.tryParse(_offlineController.text) ?? 0;

    if (onlineAmount <= 0 && offlineAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final categoryCubit = context.read<CategoryCubit>();
      final transactionCubit = context.read<TransactionCubit>();

      final userId = SupabaseService().currentUserId;
      if (userId == null) throw Exception('User not logged in');

      final incomeCategories = categoryCubit.state is CategoryLoaded
          ? (categoryCubit.state as CategoryLoaded).incomeCategories
          : <CategoryModel>[];

      final onlineCat = incomeCategories.firstWhere(
        (c) => c.name.toLowerCase() == 'online',
        orElse: () =>
            throw Exception('Category "Online" not found. Run migration.'),
      );

      final offlineCat = incomeCategories.firstWhere(
        (c) =>
            c.name.toLowerCase() == 'offline' || c.name.toLowerCase() == 'cash',
        orElse: () =>
            throw Exception('Category "Offline" not found. Run migration.'),
      );

      if (onlineAmount > 0) {
        await transactionCubit.addIncome(IncomeModel(
          id: const Uuid().v4(),
          userId: userId,
          amount: onlineAmount,
          date: _selectedDate,
          categoryId: onlineCat.id,
          description: 'Online Income',
        ));
      }

      if (offlineAmount > 0) {
        await transactionCubit.addIncome(IncomeModel(
          id: const Uuid().v4(),
          userId: userId,
          amount: offlineAmount,
          date: _selectedDate,
          categoryId: offlineCat.id,
          description: 'Offline Income',
        ));
      }

      // Reload dashboard data to show fresh data immediately
      await transactionCubit.loadTransactions(DateTime.now());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Income saved successfully')),
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Add Income'),
        backgroundColor: AppTheme.profitColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDateSelector(),
            const SizedBox(height: 24),
            _buildAmountField(
                'Online Income', _onlineController, Icons.phone_android),
            const SizedBox(height: 16),
            _buildAmountField(
                'Offline Income', _offlineController, Icons.payments),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveIncome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.profitColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Income',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.profitColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppTheme.profitColor),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Date',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  Formatters.formatDateFull(_selectedDate),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField(
      String label, TextEditingController controller, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.profitColor, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixText: '₹ ',
              border: InputBorder.none,
              hintText: '0.00',
            ),
          ),
        ],
      ),
    );
  }
}
