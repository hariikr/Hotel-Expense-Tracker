import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../blocs/expense/expense_bloc.dart';
import '../../blocs/expense/expense_event.dart';
import '../../blocs/expense/expense_state.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../models/expense.dart';
import '../../services/local_storage_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import 'dart:async';

class AddExpenseScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final Expense? existingExpense;

  const AddExpenseScreen({
    super.key,
    this.selectedDate,
    this.existingExpense,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final LocalStorageService _storageService = LocalStorageService();
  late DateTime _selectedDate;
  bool _isLoading = false;
  Timer? _autoSaveTimer;
  bool _isDraftLoaded = false;
  bool _isAutoSaving = false;

  final List<Map<String, dynamic>> _expenseFields = [
    {'key': 'fish', 'label': 'Fish', 'icon': Icons.set_meal},
    {'key': 'meat', 'label': 'Meat', 'icon': Icons.restaurant},
    {'key': 'chicken', 'label': 'Chicken', 'icon': Icons.lunch_dining},
    {'key': 'milk', 'label': 'Milk', 'icon': Icons.local_drink},
    {'key': 'parotta', 'label': 'Parotta', 'icon': Icons.breakfast_dining},
    {'key': 'pathiri', 'label': 'pathiri', 'icon': Icons.emoji_food_beverage},
    {'key': 'dosa', 'label': 'Dosa', 'icon': Icons.rice_bowl},
    {'key': 'appam', 'label': 'Appam', 'icon': Icons.flatware},
    {'key': 'coconut', 'label': 'Coconut', 'icon': Icons.grain},
    {'key': 'vegetables', 'label': 'Vegetables', 'icon': Icons.local_florist},
    {'key': 'rice', 'label': 'Rice', 'icon': Icons.rice_bowl},
    {'key': 'laborManisha', 'label': 'Labor - Manisha', 'icon': Icons.person},
    {
      'key': 'laborMidhun',
      'label': 'Labor - Midhun',
      'icon': Icons.person_outline
    },
    {'key': 'others', 'label': 'Others', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();

    // Initialize controllers
    for (var field in _expenseFields) {
      _controllers[field['key']] = TextEditingController();
    }

    // Load existing expense data if available
    if (widget.existingExpense != null) {
      _loadExistingExpense();
    } else {
      // Try to load draft from local storage
      _loadDraft();
    }

    // Clean up old drafts
    _storageService.clearOldDrafts();
  }

  Future<void> _loadExistingExpense() async {
    final expense = widget.existingExpense!;
    setState(() {
      _selectedDate = expense.date;
      _controllers['fish']!.text =
          expense.fish > 0 ? expense.fish.toString() : '';
      _controllers['meat']!.text =
          expense.meat > 0 ? expense.meat.toString() : '';
      _controllers['chicken']!.text =
          expense.chicken > 0 ? expense.chicken.toString() : '';
      _controllers['milk']!.text =
          expense.milk > 0 ? expense.milk.toString() : '';
      _controllers['parotta']!.text =
          expense.parotta > 0 ? expense.parotta.toString() : '';
      _controllers['pathiri']!.text =
          expense.pathiri > 0 ? expense.pathiri.toString() : '';
      _controllers['dosa']!.text =
          expense.dosa > 0 ? expense.dosa.toString() : '';
      _controllers['appam']!.text =
          expense.appam > 0 ? expense.appam.toString() : '';
      _controllers['coconut']!.text =
          expense.coconut > 0 ? expense.coconut.toString() : '';
      _controllers['vegetables']!.text =
          expense.vegetables > 0 ? expense.vegetables.toString() : '';
      _controllers['rice']!.text =
          expense.rice > 0 ? expense.rice.toString() : '';
      _controllers['laborManisha']!.text =
          expense.laborManisha > 0 ? expense.laborManisha.toString() : '';
      _controllers['laborMidhun']!.text =
          expense.laborMidhun > 0 ? expense.laborMidhun.toString() : '';
      _controllers['others']!.text =
          expense.others > 0 ? expense.others.toString() : '';
    });
  }

  Future<void> _loadDraft() async {
    final hasDraft = await _storageService.hasDraft(_selectedDate);
    if (hasDraft) {
      final draft = await _storageService.loadExpenseDraft(_selectedDate);
      if (draft != null && draft.isNotEmpty) {
        setState(() {
          _isDraftLoaded = true;
          draft.forEach((key, value) {
            if (_controllers.containsKey(key) && value.isNotEmpty) {
              _controllers[key]!.text = value;
            }
          });
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.restore, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Draft data restored'),
                ],
              ),
              backgroundColor: AppTheme.primaryColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _autoSaveDraft() {
    // Cancel previous timer
    _autoSaveTimer?.cancel();

    // Set new timer for auto-save after 1 second of inactivity
    _autoSaveTimer = Timer(const Duration(seconds: 1), () async {
      setState(() => _isAutoSaving = true);

      final draftData = <String, String>{};
      _controllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          draftData[key] = controller.text;
        }
      });

      if (draftData.isNotEmpty) {
        await _storageService.saveExpenseDraft(_selectedDate, draftData);
      }

      if (mounted) {
        setState(() => _isAutoSaving = false);
      }
    });
  }

  Future<void> _copyFromPreviousDay() async {
    try {
      final previousDay = _selectedDate.subtract(const Duration(days: 1));
      final normalizedPreviousDay = Formatters.normalizeDate(previousDay);

      // Load expense using bloc
      context.read<ExpenseBloc>().add(LoadExpenseByDate(normalizedPreviousDay));

      // Wait for the state to update
      await Future.delayed(const Duration(milliseconds: 800));

      final state = context.read<ExpenseBloc>().state;
      if (state is ExpenseLoaded && state.selectedExpense != null) {
        final expense = state.selectedExpense!;
        setState(() {
          _controllers['fish']!.text =
              expense.fish > 0 ? expense.fish.toString() : '';
          _controllers['meat']!.text =
              expense.meat > 0 ? expense.meat.toString() : '';
          _controllers['chicken']!.text =
              expense.chicken > 0 ? expense.chicken.toString() : '';
          _controllers['milk']!.text =
              expense.milk > 0 ? expense.milk.toString() : '';
          _controllers['parotta']!.text =
              expense.parotta > 0 ? expense.parotta.toString() : '';
          _controllers['pathiri']!.text =
              expense.pathiri > 0 ? expense.pathiri.toString() : '';
          _controllers['dosa']!.text =
              expense.dosa > 0 ? expense.dosa.toString() : '';
          _controllers['appam']!.text =
              expense.appam > 0 ? expense.appam.toString() : '';
          _controllers['coconut']!.text =
              expense.coconut > 0 ? expense.coconut.toString() : '';
          _controllers['vegetables']!.text =
              expense.vegetables > 0 ? expense.vegetables.toString() : '';
          _controllers['rice']!.text =
              expense.rice > 0 ? expense.rice.toString() : '';
          _controllers['laborManisha']!.text =
              expense.laborManisha > 0 ? expense.laborManisha.toString() : '';
          _controllers['laborMidhun']!.text =
              expense.laborMidhun > 0 ? expense.laborMidhun.toString() : '';
          _controllers['others']!.text =
              expense.others > 0 ? expense.others.toString() : '';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Copied from previous day'),
              backgroundColor: AppTheme.primaryColor,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No expense data found for previous day'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading previous day: $e'),
            backgroundColor: AppTheme.lossColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _applyTemplate(String templateName) {
    setState(() {
      // Clear all fields first
      _controllers.forEach((key, controller) => controller.clear());

      // Apply template values based on template type
      switch (templateName) {
        case 'weekend':
          _controllers['fish']!.text = '500';
          _controllers['meat']!.text = '400';
          _controllers['chicken']!.text = '350';
          _controllers['vegetables']!.text = '200';
          _controllers['rice']!.text = '150';
          _controllers['parotta']!.text = '300';
          _controllers['laborManisha']!.text = '200';
          _controllers['laborMidhun']!.text = '200';
          break;
        case 'weekday':
          _controllers['fish']!.text = '300';
          _controllers['meat']!.text = '250';
          _controllers['chicken']!.text = '200';
          _controllers['vegetables']!.text = '150';
          _controllers['rice']!.text = '100';
          _controllers['dosa']!.text = '200';
          _controllers['laborManisha']!.text = '200';
          _controllers['laborMidhun']!.text = '200';
          break;
        case 'minimal':
          _controllers['vegetables']!.text = '100';
          _controllers['rice']!.text = '80';
          _controllers['milk']!.text = '50';
          _controllers['laborManisha']!.text = '200';
          _controllers['laborMidhun']!.text = '200';
          break;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied $templateName template'),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _controllers.forEach((key, controller) => controller.clear());
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  double _calculateTotal() {
    double total = 0.0;
    _controllers.forEach((key, controller) {
      total += double.tryParse(controller.text) ?? 0.0;
    });
    return total;
  }

  Future<void> _selectDate() async {
    // Save current draft before changing date
    _autoSaveTimer?.cancel();
    final draftData = <String, String>{};
    _controllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        draftData[key] = controller.text;
      }
    });
    if (draftData.isNotEmpty) {
      await _storageService.saveExpenseDraft(_selectedDate, draftData);
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });

      // Load draft for new date
      final hasDraft = await _storageService.hasDraft(_selectedDate);
      if (hasDraft) {
        final draft = await _storageService.loadExpenseDraft(_selectedDate);
        if (draft != null && draft.isNotEmpty) {
          setState(() {
            // Clear all fields first
            _controllers.forEach((key, controller) => controller.clear());
            // Load draft values
            draft.forEach((key, value) {
              if (_controllers.containsKey(key) && value.isNotEmpty) {
                _controllers[key]!.text = value;
              }
            });
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Draft data loaded for selected date'),
                backgroundColor: AppTheme.primaryColor,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        // Clear fields if no draft exists
        setState(() {
          _controllers.forEach((key, controller) => controller.clear());
        });
      }
    }
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final expense = Expense(
        id: widget.existingExpense?.id ?? const Uuid().v4(),
        date: Formatters.normalizeDate(_selectedDate),
        fish: double.tryParse(_controllers['fish']!.text) ?? 0.0,
        meat: double.tryParse(_controllers['meat']!.text) ?? 0.0,
        chicken: double.tryParse(_controllers['chicken']!.text) ?? 0.0,
        milk: double.tryParse(_controllers['milk']!.text) ?? 0.0,
        parotta: double.tryParse(_controllers['parotta']!.text) ?? 0.0,
        pathiri: double.tryParse(_controllers['pathiri']!.text) ?? 0.0,
        dosa: double.tryParse(_controllers['dosa']!.text) ?? 0.0,
        appam: double.tryParse(_controllers['appam']!.text) ?? 0.0,
        coconut: double.tryParse(_controllers['coconut']!.text) ?? 0.0,
        vegetables: double.tryParse(_controllers['vegetables']!.text) ?? 0.0,
        rice: double.tryParse(_controllers['rice']!.text) ?? 0.0,
        laborManisha:
            double.tryParse(_controllers['laborManisha']!.text) ?? 0.0,
        laborMidhun: double.tryParse(_controllers['laborMidhun']!.text) ?? 0.0,
        others: double.tryParse(_controllers['others']!.text) ?? 0.0,
      );

      setState(() {
        _isLoading = true;
      });

      // Clear draft after saving
      _storageService.clearExpenseDraft(_selectedDate);

      context.read<ExpenseBloc>().add(UpsertExpense(expense));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Auto-save before exiting
        _autoSaveTimer?.cancel();
        final hasData = _controllers.values.any((c) => c.text.isNotEmpty);
        if (hasData) {
          final draftData = <String, String>{};
          _controllers.forEach((key, controller) {
            if (controller.text.isNotEmpty) {
              draftData[key] = controller.text;
            }
          });
          await _storageService.saveExpenseDraft(_selectedDate, draftData);
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              widget.existingExpense != null ? 'Edit Expense' : 'Add Expense'),
          actions: [
            if (_isAutoSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Saving...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              )
            else if (_isDraftLoaded && widget.existingExpense == null)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white70, size: 18),
                    SizedBox(width: 4),
                    Text('Draft', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
        body: BlocListener<ExpenseBloc, ExpenseState>(
          listener: (context, state) {
            if (state is ExpenseOperationSuccess) {
              setState(() {
                _isLoading = false;
              });
              context.read<DashboardBloc>().add(const RefreshDashboardData());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.profitColor,
                ),
              );
              Navigator.pop(context);
            } else if (state is ExpenseError) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.lossColor,
                ),
              );
            }
          },
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Date Selector
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.calendar_today,
                                color: AppTheme.primaryColor),
                            title: const Text('Date'),
                            subtitle:
                                Text(Formatters.formatDateFull(_selectedDate)),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: _selectDate,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick Actions
                        if (widget.existingExpense == null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _copyFromPreviousDay,
                                  icon:
                                      const Icon(Icons.content_copy, size: 18),
                                  label: const Text('Copy Yesterday'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                onSelected: _applyTemplate,
                                icon: const Icon(Icons.app_registration),
                                tooltip: 'Apply Template',
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'weekend',
                                    child: Text('Weekend Template'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'weekday',
                                    child: Text('Weekday Template'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'minimal',
                                    child: Text('Minimal Template'),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: _clearAll,
                                icon: const Icon(Icons.clear_all),
                                tooltip: 'Clear All',
                                color: AppTheme.lossColor,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Expense Fields
                        ..._expenseFields.map((field) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TextFormField(
                                controller: _controllers[field['key']],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: InputDecoration(
                                  labelText: field['label'],
                                  prefixText: '₹ ',
                                  hintText: '0.00',
                                  suffixIcon: Icon(field['icon']),
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                  // Auto-save draft after user stops typing
                                  _autoSaveDraft();
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return null;
                                  }
                                  final parsed = double.tryParse(value);
                                  if (parsed == null) {
                                    return 'Please enter a valid number';
                                  }
                                  if (parsed < 0) {
                                    return 'Value cannot be negative';
                                  }
                                  return null;
                                },
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom section with total and save button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Total
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.lossColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Expense',
                              style: AppTheme.headingSmall.copyWith(
                                color: AppTheme.lossColor,
                              ),
                            ),
                            Text(
                              Formatters.formatCurrency(_calculateTotal()),
                              style: AppTheme.headingMedium.copyWith(
                                color: AppTheme.lossColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveExpense,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  widget.existingExpense != null
                                      ? 'Update Expense'
                                      : 'Save Expense',
                                  style: AppTheme.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
