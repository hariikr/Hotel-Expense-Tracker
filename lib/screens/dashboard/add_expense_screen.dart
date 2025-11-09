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

  // Individual controllers for each expense category
  final _fishController = TextEditingController();
  final _meatController = TextEditingController();
  final _chickenController = TextEditingController();
  final _milkController = TextEditingController();
  final _parottaController = TextEditingController();
  final _pathiriController = TextEditingController();
  final _dosaController = TextEditingController();
  final _appamController = TextEditingController();
  final _coconutController = TextEditingController();
  final _vegetablesController = TextEditingController();
  final _riceController = TextEditingController();
  final _laborManishaController = TextEditingController();
  final _laborMidhunController = TextEditingController();
  final _othersController = TextEditingController();
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
      // Load existing expense data into individual fields
      _loadExistingExpense();
    } else {
      // Load draft if available (for backward compatibility)
      _loadDraft();
    }
  }

  void _loadDraft() async {
    final hasDraft = await _storageService.hasDraft(_selectedDate);
    if (hasDraft) {
      final draft = await _storageService.loadExpenseDraft(_selectedDate);
      if (draft != null && draft.isNotEmpty) {
        // For backward compatibility, we'll still need to parse old draft format
        if (draft.containsKey('text')) {
          final text = draft['text']!;
          // Parse the old format text and populate individual fields
          _parseAndSetExpenseText(text);
        }
        
        setState(() {
          _isDraftLoaded = true;
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

  /// Parse old text format and set individual field values
  void _parseAndSetExpenseText(String text) {
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

        // Set the appropriate controller based on category
        switch (category) {
          case 'fish':
            _fishController.text = amount.toString();
            break;
          case 'meat':
            _meatController.text = amount.toString();
            break;
          case 'chicken':
            _chickenController.text = amount.toString();
            break;
          case 'milk':
            _milkController.text = amount.toString();
            break;
          case 'parotta':
            _parottaController.text = amount.toString();
            break;
          case 'pathiri':
            _pathiriController.text = amount.toString();
            break;
          case 'dosa':
            _dosaController.text = amount.toString();
            break;
          case 'appam':
            _appamController.text = amount.toString();
            break;
          case 'coconut':
            _coconutController.text = amount.toString();
            break;
          case 'vegetables':
            _vegetablesController.text = amount.toString();
            break;
          case 'rice':
            _riceController.text = amount.toString();
            break;
          case 'labor manisha':
          case 'manisha':
            _laborManishaController.text = amount.toString();
            break;
          case 'labor midhun':
          case 'midhun':
            _laborMidhunController.text = amount.toString();
            break;
          case 'others':
            _othersController.text = amount.toString();
            break;
        }
      }
    }
  }

  double _calculateTotal() {
    double total = 0.0;
    total += double.tryParse(_fishController.text) ?? 0.0;
    total += double.tryParse(_meatController.text) ?? 0.0;
    total += double.tryParse(_chickenController.text) ?? 0.0;
    total += double.tryParse(_milkController.text) ?? 0.0;
    total += double.tryParse(_parottaController.text) ?? 0.0;
    total += double.tryParse(_pathiriController.text) ?? 0.0;
    total += double.tryParse(_dosaController.text) ?? 0.0;
    total += double.tryParse(_appamController.text) ?? 0.0;
    total += double.tryParse(_coconutController.text) ?? 0.0;
    total += double.tryParse(_vegetablesController.text) ?? 0.0;
    total += double.tryParse(_riceController.text) ?? 0.0;
    total += double.tryParse(_laborManishaController.text) ?? 0.0;
    total += double.tryParse(_laborMidhunController.text) ?? 0.0;
    total += double.tryParse(_othersController.text) ?? 0.0;
    return total;
  }

  void _autoSaveDraft() {
    // Cancel previous timer
    _autoSaveTimer?.cancel();

    // Set new timer for auto-save after 1 second of inactivity
    _autoSaveTimer = Timer(const Duration(seconds: 1), () async {
      setState(() => _isAutoSaving = true);

      // For backward compatibility, we'll save in the old text format as well
      final draftData = <String, String>{};
      final textFormat = _generateTextFormat();
      if (textFormat.isNotEmpty) {
        draftData['text'] = textFormat;
      }

      if (draftData.isNotEmpty) {
        await _storageService.saveExpenseDraft(_selectedDate, draftData);
      }

      if (mounted) {
        setState(() => _isAutoSaving = false);
      }
    });
  }

  /// Generate old text format for backward compatibility
  String _generateTextFormat() {
    final lines = <String>[];
    final fish = double.tryParse(_fishController.text) ?? 0.0;
    if (fish > 0) lines.add('fish ${fish}rs');
    final meat = double.tryParse(_meatController.text) ?? 0.0;
    if (meat > 0) lines.add('meat ${meat}rs');
    final chicken = double.tryParse(_chickenController.text) ?? 0.0;
    if (chicken > 0) lines.add('chicken ${chicken}rs');
    final milk = double.tryParse(_milkController.text) ?? 0.0;
    if (milk > 0) lines.add('milk ${milk}rs');
    final parotta = double.tryParse(_parottaController.text) ?? 0.0;
    if (parotta > 0) lines.add('parotta ${parotta}rs');
    final pathiri = double.tryParse(_pathiriController.text) ?? 0.0;
    if (pathiri > 0) lines.add('pathiri ${pathiri}rs');
    final dosa = double.tryParse(_dosaController.text) ?? 0.0;
    if (dosa > 0) lines.add('dosa ${dosa}rs');
    final appam = double.tryParse(_appamController.text) ?? 0.0;
    if (appam > 0) lines.add('appam ${appam}rs');
    final coconut = double.tryParse(_coconutController.text) ?? 0.0;
    if (coconut > 0) lines.add('coconut ${coconut}rs');
    final vegetables = double.tryParse(_vegetablesController.text) ?? 0.0;
    if (vegetables > 0) lines.add('vegetables ${vegetables}rs');
    final rice = double.tryParse(_riceController.text) ?? 0.0;
    if (rice > 0) lines.add('rice ${rice}rs');
    final laborManisha = double.tryParse(_laborManishaController.text) ?? 0.0;
    if (laborManisha > 0) lines.add('labor manisha ${laborManisha}rs');
    final laborMidhun = double.tryParse(_laborMidhunController.text) ?? 0.0;
    if (laborMidhun > 0) lines.add('labor midhun ${laborMidhun}rs');
    final others = double.tryParse(_othersController.text) ?? 0.0;
    if (others > 0) lines.add('others ${others}rs');
    return lines.join('\n');
  }

  Future<void> _loadExistingExpense() async {
    final expense = widget.existingExpense!;
    setState(() {
      _selectedDate = expense.date;
      _fishController.text = expense.fish.toString();
      _meatController.text = expense.meat.toString();
      _chickenController.text = expense.chicken.toString();
      _milkController.text = expense.milk.toString();
      _parottaController.text = expense.parotta.toString();
      _pathiriController.text = expense.pathiri.toString();
      _dosaController.text = expense.dosa.toString();
      _appamController.text = expense.appam.toString();
      _coconutController.text = expense.coconut.toString();
      _vegetablesController.text = expense.vegetables.toString();
      _riceController.text = expense.rice.toString();
      _laborManishaController.text = expense.laborManisha.toString();
      _laborMidhunController.text = expense.laborMidhun.toString();
      _othersController.text = expense.others.toString();
    });
  }

  Future<void> _copyFromPreviousDay() async {
    try {
      final previousDay = _selectedDate.subtract(const Duration(days: 1));
      final normalizedPreviousDay = Formatters.normalizeDate(previousDay);

      // Get the current context (hotel or house) from dashboard state
      final dashboardState = context.read<DashboardBloc>().state;
      final contextType = dashboardState is DashboardLoaded
          ? dashboardState.selectedContext
          : 'hotel';

      // Load expense using bloc
      context
          .read<ExpenseBloc>()
          .add(LoadExpenseByDate(normalizedPreviousDay, context: contextType));

      // Wait for the state to update
      await Future.delayed(const Duration(milliseconds: 800));

      final state = context.read<ExpenseBloc>().state;
      if (state is ExpenseLoaded && state.selectedExpense != null) {
        final expense = state.selectedExpense!;
        setState(() {
          _fishController.text = expense.fish.toString();
          _meatController.text = expense.meat.toString();
          _chickenController.text = expense.chicken.toString();
          _milkController.text = expense.milk.toString();
          _parottaController.text = expense.parotta.toString();
          _pathiriController.text = expense.pathiri.toString();
          _dosaController.text = expense.dosa.toString();
          _appamController.text = expense.appam.toString();
          _coconutController.text = expense.coconut.toString();
          _vegetablesController.text = expense.vegetables.toString();
          _riceController.text = expense.rice.toString();
          _laborManishaController.text = expense.laborManisha.toString();
          _laborMidhunController.text = expense.laborMidhun.toString();
          _othersController.text = expense.others.toString();
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  void _applyTemplate(String templateName) {
    setState(() {
      // Clear all fields first
      _fishController.clear();
      _meatController.clear();
      _chickenController.clear();
      _milkController.clear();
      _parottaController.clear();
      _pathiriController.clear();
      _dosaController.clear();
      _appamController.clear();
      _coconutController.clear();
      _vegetablesController.clear();
      _riceController.clear();
      _laborManishaController.clear();
      _laborMidhunController.clear();
      _othersController.clear();

      // Apply template values based on template type
      switch (templateName) {
        case 'weekend':
          _fishController.text = '500';
          _meatController.text = '400';
          _chickenController.text = '350';
          _vegetablesController.text = '200';
          _riceController.text = '150';
          _parottaController.text = '300';
          _laborManishaController.text = '200';
          _laborMidhunController.text = '200';
          break;
        case 'weekday':
          _fishController.text = '300';
          _meatController.text = '250';
          _chickenController.text = '200';
          _vegetablesController.text = '150';
          _riceController.text = '100';
          _dosaController.text = '200';
          _laborManishaController.text = '200';
          _laborMidhunController.text = '200';
          break;
        case 'minimal':
          _vegetablesController.text = '100';
          _riceController.text = '80';
          _milkController.text = '50';
          _laborManishaController.text = '150';
          _laborMidhunController.text = '150';
          break;
      }
    });
  }

  void _selectDate() async {
    // Save current draft before changing date
    _autoSaveTimer?.cancel();
    final draftData = <String, String>{};
    final textFormat = _generateTextFormat();
    if (textFormat.isNotEmpty) {
      draftData['text'] = textFormat;
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
              // For backward compatibility, parse the old format
              _parseAndSetExpenseText(draft['text']!);
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
        // Clear all fields if no draft exists
        setState(() {
          _fishController.clear();
          _meatController.clear();
          _chickenController.clear();
          _milkController.clear();
          _parottaController.clear();
          _pathiriController.clear();
          _dosaController.clear();
          _appamController.clear();
          _coconutController.clear();
          _vegetablesController.clear();
          _riceController.clear();
          _laborManishaController.clear();
          _laborMidhunController.clear();
          _othersController.clear();
          _isDraftLoaded = false;
        });
      }
    }
  }

  void _saveExpense() {
    // Custom validation: ensure at least one field has a value
    if (_calculateTotal() <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one expense value'),
          backgroundColor: AppTheme.lossColor,
        ),
      );
      return;
    }
    
    final dashboardState = context.read<DashboardBloc>().state;
    final contextType = dashboardState is DashboardLoaded
        ? dashboardState.selectedContext
        : 'hotel';

    final expense = Expense(
      id: widget.existingExpense?.id ?? const Uuid().v4(),
      date: Formatters.normalizeDate(_selectedDate),
      context: contextType,
      fish: double.tryParse(_fishController.text) ?? 0.0,
      meat: double.tryParse(_meatController.text) ?? 0.0,
      chicken: double.tryParse(_chickenController.text) ?? 0.0,
      milk: double.tryParse(_milkController.text) ?? 0.0,
      parotta: double.tryParse(_parottaController.text) ?? 0.0,
      pathiri: double.tryParse(_pathiriController.text) ?? 0.0,
      dosa: double.tryParse(_dosaController.text) ?? 0.0,
      appam: double.tryParse(_appamController.text) ?? 0.0,
      coconut: double.tryParse(_coconutController.text) ?? 0.0,
      vegetables: double.tryParse(_vegetablesController.text) ?? 0.0,
      rice: double.tryParse(_riceController.text) ?? 0.0,
      laborManisha: double.tryParse(_laborManishaController.text) ?? 0.0,
      laborMidhun: double.tryParse(_laborMidhunController.text) ?? 0.0,
      others: double.tryParse(_othersController.text) ?? 0.0,
    );

    setState(() {
      _isLoading = true;
    });

    // Clear draft after saving
    _storageService.clearExpenseDraft(_selectedDate);

    context.read<ExpenseBloc>().add(UpsertExpense(expense));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Auto-save before exiting
        _autoSaveTimer?.cancel();
        final totalValue = _calculateTotal();
        if (totalValue > 0) {
          final draftData = {'text': _generateTextFormat()};
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
                      subtitle: Text(Formatters.formatDateFull(_selectedDate)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                            icon: const Icon(Icons.content_copy, size: 18),
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

                  // Individual Expense Input Fields - Organized by Category
                  Column(
                    children: [
                      // Food Items Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Food Items', style: AppTheme.headingSmall),
                              const SizedBox(height: 12),
                              _buildExpenseField('Fish (₹)', _fishController),
                              const SizedBox(height: 8),
                              _buildExpenseField('Meat (₹)', _meatController),
                              const SizedBox(height: 8),
                              _buildExpenseField('Chicken (₹)', _chickenController),
                              const SizedBox(height: 8),
                              _buildExpenseField('Milk (₹)', _milkController),
                              const SizedBox(height: 8),
                              _buildExpenseField('Parotta (₹)', _parottaController),
                              const SizedBox(height: 8),
                              _buildExpenseField('Pathiri (₹)', _pathiriController),
                              const SizedBox(height: 8),
                              _buildExpenseField('Dosa (₹)', _dosaController),
                              const SizedBox(height: 8),
                              _buildExpenseField('Appam (₹)', _appamController),
                              const SizedBox(height: 8),
                              _buildExpenseField('Coconut (₹)', _coconutController),
                              const SizedBox(height: 8),
                              _buildExpenseField('Vegetables (₹)', _vegetablesController),
                              const SizedBox(height: 8),
                              _buildExpenseField('Rice (₹)', _riceController),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Labor & Others Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Labor & Other Expenses', style: AppTheme.headingSmall),
                              const SizedBox(height: 12),
                              _buildExpenseField('Labor Manisha (₹)', _laborManishaController),
                              const SizedBox(height: 8),
                              _buildExpenseField('Labor Midhun (₹)', _laborMidhunController),
                              const SizedBox(height: 8),
                              _buildExpenseField('Others (₹)', _othersController),
                            ],
                          ),
                        ),
                      ),
                    ],
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
    // Dispose all text controllers
    _fishController.dispose();
    _meatController.dispose();
    _chickenController.dispose();
    _milkController.dispose();
    _parottaController.dispose();
    _pathiriController.dispose();
    _dosaController.dispose();
    _appamController.dispose();
    _coconutController.dispose();
    _vegetablesController.dispose();
    _riceController.dispose();
    _laborManishaController.dispose();
    _laborMidhunController.dispose();
    _othersController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
