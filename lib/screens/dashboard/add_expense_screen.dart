import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/supabase_service.dart';
import '../../features/settings/cubits/category_cubit.dart';
import '../../features/transactions/cubits/transaction_cubit.dart';
import '../../features/transactions/models/expense_model.dart';
import '../../utils/app_theme.dart';
import '../settings/manage_categories_screen.dart';
import '../widgets/entry_form_widgets.dart';

class AddExpenseScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const AddExpenseScreen({super.key, this.selectedDate});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  static const _color = AppTheme.lossColor;

  late DateTime _selectedDate;
  final Map<String, TextEditingController> _amountControllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  bool _isLoading = false;

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
    'gas': Icons.local_fire_department,
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

  static const List<Color> _categoryColors = [
    Color(0xFFE53935),
    Color(0xFFD81B60),
    Color(0xFF8E24AA),
    Color(0xFF5C6BC0),
    Color(0xFF1E88E5),
    Color(0xFF00ACC1),
    Color(0xFF00897B),
    Color(0xFF43A047),
    Color(0xFF7CB342),
    Color(0xFFF9A825),
    Color(0xFFFF8F00),
    Color(0xFFF4511E),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    context.read<CategoryCubit>().loadCategories();
  }

  @override
  void dispose() {
    for (final c in _amountControllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String id) =>
      _amountControllers.putIfAbsent(id, TextEditingController.new);

  FocusNode _focusFor(String id) => _focusNodes.putIfAbsent(id, FocusNode.new);

  double get _totalAmount => _amountControllers.values
      .fold(0, (sum, c) => sum + parseAmount(c.text));

  int get _filledCount =>
      _amountControllers.values.where((c) => parseAmount(c.text) > 0).length;

  IconData _iconFor(String name) {
    final lower = name.toLowerCase();
    for (final entry in _categoryIcons.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return Icons.category;
  }

  Future<void> _saveExpenses() async {
    final userId = SupabaseService().currentUserId;
    if (userId == null) {
      showEntrySnack(
          context, entryT('Please log in again', 'വീണ്ടും ലോഗിൻ ചെയ്യുക'),
          error: true);
      return;
    }

    final expensesToSave = <ExpenseModel>[];
    for (final entry in _amountControllers.entries) {
      final amount = parseAmount(entry.value.text);
      if (amount > 0) {
        expensesToSave.add(ExpenseModel(
          id: const Uuid().v4(),
          userId: userId,
          amount: amount,
          date: _selectedDate,
          categoryId: entry.key,
          description: '',
        ));
      }
    }

    if (expensesToSave.isEmpty) {
      showEntrySnack(context,
          entryT('Enter at least one amount', 'ഒരു തുകയെങ്കിലും നൽകുക'),
          error: true);
      return;
    }

    final total = _totalAmount;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final cubit = context.read<TransactionCubit>();
      for (final expense in expensesToSave) {
        await cubit.addExpense(expense);
      }
      await cubit.loadTransactions(DateTime.now());

      if (mounted) {
        HapticFeedback.mediumImpact();
        showEntrySnack(
          context,
          entryT(
            '${expensesToSave.length} expenses saved: ${entryMoney.format(total)}',
            '${expensesToSave.length} ചെലവുകൾ സേവ് ചെയ്തു: ${entryMoney.format(total)}',
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showEntrySnack(
          context,
          entryT("Couldn't save. $e", 'സേവ് ചെയ്യാനായില്ല. $e'),
          error: true,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalAmount;
    final filled = _filledCount;

    return PopScope(
      canPop: total <= 0 || _isLoading,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await confirmDiscardEntries(context)) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(entryT('Add expenses', 'ചെലവ് ചേർക്കുക')),
          actions: [
            IconButton(
              tooltip: entryT('Edit categories', 'വിഭാഗങ്ങൾ മാറ്റുക'),
              icon: const Icon(Icons.tune),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ManageCategoriesScreen()),
              ),
            ),
          ],
        ),
        body: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            if (state is CategoryError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off,
                          size: 48, color: AppTheme.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        entryT("Couldn't load categories",
                            'വിഭാഗങ്ങൾ ലോഡ് ചെയ്യാനായില്ല'),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            context.read<CategoryCubit>().loadCategories(),
                        icon: const Icon(Icons.refresh),
                        label: Text(entryT('Try again', 'വീണ്ടും ശ്രമിക്കുക')),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is! CategoryLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            final categories = state.expenseCategories;
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EntryDatePicker(
                          date: _selectedDate,
                          color: _color,
                          onChanged: (d) => setState(() => _selectedDate = d),
                        ),
                        if (categories.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Text(
                              entryT(
                                'No expense categories yet. Tap the settings icon above to add some.',
                                'ചെലവ് വിഭാഗങ്ങൾ ഇല്ല. മുകളിലെ ഐക്കൺ അമർത്തി ചേർക്കുക.',
                              ),
                              style: const TextStyle(
                                  fontSize: 15, color: AppTheme.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  );
                }
                final i = index - 1;
                final category = categories[i];
                final isLast = i == categories.length - 1;
                return _ExpenseRow(
                  name: category.name,
                  icon: _iconFor(category.name),
                  color: _categoryColors[i % _categoryColors.length],
                  controller: _controllerFor(category.id),
                  focusNode: _focusFor(category.id),
                  isLast: isLast,
                  onChanged: () => setState(() {}),
                  onNext: isLast
                      ? () => FocusScope.of(context).unfocus()
                      : () => _focusFor(categories[i + 1].id).requestFocus(),
                );
              },
            );
          },
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: EntryBottomBar(
            totalLabel: entryT('Total expense', 'ആകെ ചെലവ്'),
            total: total,
            detail: filled > 0
                ? entryT('$filled ${filled == 1 ? 'item' : 'items'}',
                    '$filled എണ്ണം')
                : null,
            buttonLabel: entryT('Save', 'സേവ്'),
            color: _color,
            loading: _isLoading,
            onSave: total > 0 ? _saveExpenses : null,
          ),
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLast;
  final VoidCallback onChanged;
  final VoidCallback onNext;

  const _ExpenseRow({
    required this.name,
    required this.icon,
    required this.color,
    required this.controller,
    required this.focusNode,
    required this.isLast,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = parseAmount(controller.text) > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: hasValue ? color.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: focusNode.requestFocus,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasValue ? color : AppTheme.darkSurface,
                width: hasValue ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 132,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: amountInputFormatters,
                    textInputAction:
                        isLast ? TextInputAction.done : TextInputAction.next,
                    onSubmitted: (_) => onNext(),
                    onChanged: (_) => onChanged(),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                      hintText: '0',
                      isDense: true,
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: color, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
