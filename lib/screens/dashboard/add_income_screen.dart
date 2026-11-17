import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/supabase_service.dart';
import '../../features/settings/cubits/category_cubit.dart';
import '../../features/settings/models/category_model.dart';
import '../../features/transactions/cubits/transaction_cubit.dart';
import '../../features/transactions/models/income_model.dart';
import '../../utils/app_theme.dart';
import '../widgets/entry_form_widgets.dart';

class AddIncomeScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const AddIncomeScreen({super.key, this.selectedDate});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  static const _color = AppTheme.profitColor;
  static const _quickAmounts = [100, 500, 1000, 2000];

  late DateTime _selectedDate;
  final _onlineController = TextEditingController();
  final _offlineController = TextEditingController();
  final _onlineFocus = FocusNode();
  bool _isLoading = false;

  double get _online => parseAmount(_onlineController.text);
  double get _offline => parseAmount(_offlineController.text);
  double get _total => _online + _offline;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    context.read<CategoryCubit>().loadCategories();
    _onlineController.addListener(_refresh);
    _offlineController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _onlineController.dispose();
    _offlineController.dispose();
    _onlineFocus.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
    final onlineAmount = _online;
    final offlineAmount = _offline;

    if (onlineAmount <= 0 && offlineAmount <= 0) {
      showEntrySnack(context, entryT('Enter an amount', 'തുക നൽകുക'),
          error: true);
      return;
    }

    FocusScope.of(context).unfocus();
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

      await transactionCubit.loadTransactions(DateTime.now());

      if (mounted) {
        HapticFeedback.mediumImpact();
        showEntrySnack(
          context,
          entryT('Income saved: ${entryMoney.format(onlineAmount + offlineAmount)}',
              'വരുമാനം സേവ് ചെയ്തു: ${entryMoney.format(onlineAmount + offlineAmount)}'),
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
    return PopScope(
      canPop: _total <= 0 || _isLoading,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await confirmDiscardEntries(context)) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(entryT('Add income', 'വരുമാനം ചേർക്കുക')),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            EntryDatePicker(
              date: _selectedDate,
              color: _color,
              onChanged: (d) => setState(() => _selectedDate = d),
            ),
            const SizedBox(height: 20),
            _AmountCard(
              title: entryT('Online', 'ഓൺലൈൻ'),
              subtitle: 'UPI · Swiggy · Zomato',
              icon: Icons.phone_android,
              controller: _onlineController,
              focusNode: _onlineFocus,
              autofocus: true,
              quickAmounts: _quickAmounts,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            _AmountCard(
              title: entryT('Cash', 'ക്യാഷ്'),
              subtitle: entryT('Paid at the counter', 'കൗണ്ടറിൽ ലഭിച്ചത്'),
              icon: Icons.payments_outlined,
              controller: _offlineController,
              quickAmounts: _quickAmounts,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveIncome(),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: EntryBottomBar(
            totalLabel: entryT('Total income', 'ആകെ വരുമാനം'),
            total: _total,
            buttonLabel: entryT('Save', 'സേവ്'),
            color: _color,
            loading: _isLoading,
            onSave: _total > 0 ? _saveIncome : null,
          ),
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final List<int> quickAmounts;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _AmountCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.controller,
    required this.quickAmounts,
    required this.textInputAction,
    this.focusNode,
    this.autofocus = false,
    this.onSubmitted,
  });

  void _add(int amount) {
    final next = parseAmount(controller.text) + amount;
    final text = next == next.roundToDouble()
        ? next.toStringAsFixed(0)
        : next.toStringAsFixed(2);
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = parseAmount(controller.text) > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasValue ? AppTheme.profitColor : AppTheme.darkSurface,
          width: hasValue ? 2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.profitColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.profitColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              if (hasValue)
                IconButton(
                  tooltip: entryT('Clear', 'മായ്ക്കുക'),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: controller.clear,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: amountInputFormatters,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
            decoration: const InputDecoration(
              prefixText: '₹ ',
              prefixStyle: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
              ),
              hintText: '0',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amount in quickAmounts)
                ActionChip(
                  label: Text('+${entryMoney.format(amount)}'),
                  onPressed: () => _add(amount),
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.profitColor,
                  ),
                  backgroundColor: AppTheme.profitColor.withValues(alpha: 0.06),
                  side: BorderSide(
                      color: AppTheme.profitColor.withValues(alpha: 0.25)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
