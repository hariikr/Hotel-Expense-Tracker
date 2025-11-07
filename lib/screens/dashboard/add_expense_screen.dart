import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../blocs/expense/expense_bloc.dart';
import '../../blocs/expense/expense_event.dart';
import '../../blocs/expense/expense_state.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../blocs/dashboard/dashboard_state.dart';
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
  final _expenseTextController = TextEditingController();
  final LocalStorageService _storageService = LocalStorageService();
  late DateTime _selectedDate;
  bool _isLoading = false;
  Timer? _autoSaveTimer;
  bool _isDraftLoaded = false;
  bool _isAutoSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();

    if (widget.existingExpense != null) {
      // Load existing expense data
      _loadExistingExpense();
    } else {
      // Load draft if available
      _loadDraft();
    }
  }

  String _expenseToText(Expense expense) {
    final lines = <String>[];
    if (expense.fish > 0) lines.add('fish ${expense.fish}rs');
    if (expense.meat > 0) lines.add('meat ${expense.meat}rs');
    if (expense.chicken > 0) lines.add('chicken ${expense.chicken}rs');
    if (expense.milk > 0) lines.add('milk ${expense.milk}rs');
    if (expense.parotta > 0) lines.add('parotta ${expense.parotta}rs');
    if (expense.pathiri > 0) lines.add('pathiri ${expense.pathiri}rs');
    if (expense.dosa > 0) lines.add('dosa ${expense.dosa}rs');
    if (expense.appam > 0) lines.add('appam ${expense.appam}rs');
    if (expense.coconut > 0) lines.add('coconut ${expense.coconut}rs');
    if (expense.vegetables > 0) lines.add('vegetables ${expense.vegetables}rs');
    if (expense.rice > 0) lines.add('rice ${expense.rice}rs');
    if (expense.laborManisha > 0) lines.add('labor manisha ${expense.laborManisha}rs');
    if (expense.laborMidhun > 0) lines.add('labor midhun ${expense.laborMidhun}rs');
    if (expense.others > 0) lines.add('others ${expense.others}rs');
    return lines.join('\n');
  }

  Map<String, double> _parseExpenseText(String text) {
    final Map<String, double> expenses = {};
    final lines = text.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      // Find the last number in the line
      final numberRegex = RegExp(r'(-?\d+(?:\.\d+)?)');
      final matches = numberRegex.allMatches(line);
      if (matches.isNotEmpty) {
        final lastMatch = matches.last;
        final amount = double.tryParse(lastMatch.group(0)!) ?? 0.0;
        final category = line.substring(0, lastMatch.start).trim().toLowerCase();
        expenses[category] = (expenses[category] ?? 0.0) + amount;
      }
    }
    return expenses;
  }

  double _calculateTotal() {
    final parsed = _parseExpenseText(_expenseTextController.text);
    return parsed.values.fold(0.0, (sum, value) => sum + value);
  }

  Future<void> _loadDraft() async {
    final hasDraft = await _storageService.hasDraft(_selectedDate);
    if (hasDraft) {
      final draft = await _storageService.loadExpenseDraft(_selectedDate);
      if (draft != null && draft.isNotEmpty) {
        setState(() {
          _isDraftLoaded = true;
          if (draft.containsKey('text')) {
            _expenseTextController.text = draft['text']!;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.restore, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Draft loaded'),
                ],
              ),
              backgroundColor: Colors.blue,
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
      if (_expenseTextController.text.trim().isNotEmpty) {
        draftData['text'] = _expenseTextController.text;
      }

      if (draftData.isNotEmpty) {
        await _storageService.saveExpenseDraft(_selectedDate, draftData);
      }

      if (mounted) {
        setState(() => _isAutoSaving = false);
      }
    });
  }

  Future<void> _loadExistingExpense() async {
    final expense = widget.existingExpense!;
    setState(() {
      _selectedDate = expense.date;
      _expenseTextController.text = _expenseToText(expense);
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
          _expenseTextController.text = _expenseToText(expense);
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  void _applyTemplate(String templateName) {
    setState(() {
      // Apply template values based on template type
      switch (templateName) {
        case 'weekend':
          _expenseTextController.text = '''fish 500rs
meat 400rs
chicken 350rs
vegetables 200rs
rice 150rs
parotta 300rs
labor manisha 200rs
labor midhun 200rs''';
          break;
        case 'weekday':
          _expenseTextController.text = '''fish 300rs
meat 250rs
chicken 200rs
vegetables 150rs
rice 100rs
dosa 200rs
labor manisha 200rs
labor midhun 200rs''';
          break;
        case 'minimal':
          _expenseTextController.text = '''vegetables 100rs
rice 80rs
milk 50rs
labor manisha 150rs
labor midhun 150rs''';
          break;
      }
    });
  }

  void _selectDate() async {
    // Save current draft before changing date
    _autoSaveTimer?.cancel();
    final draftData = <String, String>{};
    if (_expenseTextController.text.trim().isNotEmpty) {
      draftData['text'] = _expenseTextController.text;
    }
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
            _isDraftLoaded = true;
            if (draft.containsKey('text')) {
              _expenseTextController.text = draft['text']!;
            }
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
          _expenseTextController.clear();
          _isDraftLoaded = false;
        });
      }
    }
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final dashboardState = context.read<DashboardBloc>().state;
      final contextType = dashboardState is DashboardLoaded ? dashboardState.selectedContext : 'hotel';

      final parsedExpenses = _parseExpenseText(_expenseTextController.text);

      final expense = Expense(
        id: widget.existingExpense?.id ?? const Uuid().v4(),
        date: Formatters.normalizeDate(_selectedDate),
        context: contextType,
        fish: parsedExpenses['fish'] ?? 0.0,
        meat: parsedExpenses['meat'] ?? 0.0,
        chicken: parsedExpenses['chicken'] ?? 0.0,
        milk: parsedExpenses['milk'] ?? 0.0,
        parotta: parsedExpenses['parotta'] ?? 0.0,
        pathiri: parsedExpenses['pathiri'] ?? 0.0,
        dosa: parsedExpenses['dosa'] ?? 0.0,
        appam: parsedExpenses['appam'] ?? 0.0,
        coconut: parsedExpenses['coconut'] ?? 0.0,
        vegetables: parsedExpenses['vegetables'] ?? 0.0,
        rice: parsedExpenses['rice'] ?? 0.0,
        laborManisha: parsedExpenses['labor manisha'] ?? parsedExpenses['manisha'] ?? 0.0,
        laborMidhun: parsedExpenses['labor midhun'] ?? parsedExpenses['midhun'] ?? 0.0,
        others: parsedExpenses.values.where((v) => v != 0).fold(0.0, (sum, v) => sum + v) - 
               (parsedExpenses['fish'] ?? 0) - (parsedExpenses['meat'] ?? 0) - (parsedExpenses['chicken'] ?? 0) -
               (parsedExpenses['milk'] ?? 0) - (parsedExpenses['parotta'] ?? 0) - (parsedExpenses['pathiri'] ?? 0) -
               (parsedExpenses['dosa'] ?? 0) - (parsedExpenses['appam'] ?? 0) - (parsedExpenses['coconut'] ?? 0) -
               (parsedExpenses['vegetables'] ?? 0) - (parsedExpenses['rice'] ?? 0) -
               (parsedExpenses['labor manisha'] ?? parsedExpenses['manisha'] ?? 0) -
               (parsedExpenses['labor midhun'] ?? parsedExpenses['midhun'] ?? 0),
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
        final hasData = _expenseTextController.text.trim().isNotEmpty;
        if (hasData) {
          final draftData = {'text': _expenseTextController.text};
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
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Expense Text Input
                  TextFormField(
                    controller: _expenseTextController,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      labelText: 'Expense Details',
                      hintText: 'Enter expenses like:\nmilk 50rs\nchicken 100rs\nmovie -200rs',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {});
                      // Auto-save draft after user stops typing
                      _autoSaveDraft();
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter expense details';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom section with total and save button
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Expense',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
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
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lossColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Expense'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _expenseTextController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
