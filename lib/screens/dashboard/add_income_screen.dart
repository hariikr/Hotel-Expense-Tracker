import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../../blocs/income/income_bloc.dart';
import '../../blocs/income/income_event.dart';
import '../../blocs/income/income_state.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../models/income.dart';
import '../../services/local_storage_service.dart';
import '../../services/undo_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/quick_amount_presets.dart';
import '../../widgets/voice_input_button.dart';

class AddIncomeScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final Income? existingIncome;

  const AddIncomeScreen({
    super.key,
    this.selectedDate,
    this.existingIncome,
  });

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _onlineIncomeController = TextEditingController();
  final _offlineIncomeController = TextEditingController();
  final _mealsCountController = TextEditingController();
  late DateTime _selectedDate;
  bool _isLoading = false;
  bool _isAutoSaving = false;
  bool _isDraftLoaded = false;
  Timer? _autoSaveTimer;
  final _storageService = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();

    if (widget.existingIncome != null) {
      _onlineIncomeController.text =
          widget.existingIncome!.onlineIncome.toString();
      _offlineIncomeController.text =
          widget.existingIncome!.offlineIncome.toString();
      _mealsCountController.text = widget.existingIncome!.mealsCount.toString();
      _selectedDate = widget.existingIncome!.date;
    } else {
      // Load draft if not editing existing income
      _loadDraftData();
    }

    // Add listeners for auto-save
    _onlineIncomeController.addListener(_autoSaveDraft);
    _offlineIncomeController.addListener(_autoSaveDraft);
    _mealsCountController.addListener(_autoSaveDraft);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _onlineIncomeController.dispose();
    _offlineIncomeController.dispose();
    _mealsCountController.dispose();
    super.dispose();
  }

  void _autoSaveDraft() {
    // Cancel previous timer
    _autoSaveTimer?.cancel();

    // Set new timer for auto-save after 1 second of inactivity
    _autoSaveTimer = Timer(const Duration(seconds: 1), () async {
      setState(() => _isAutoSaving = true);

      final draftData = <String, String>{};

      if (_onlineIncomeController.text.isNotEmpty) {
        draftData['online_income'] = _onlineIncomeController.text;
      }
      if (_offlineIncomeController.text.isNotEmpty) {
        draftData['offline_income'] = _offlineIncomeController.text;
      }
      if (_mealsCountController.text.isNotEmpty) {
        draftData['meals_count'] = _mealsCountController.text;
      }

      if (draftData.isNotEmpty) {
        await _storageService.saveIncomeDraft(_selectedDate, draftData);
      }

      if (mounted) {
        setState(() => _isAutoSaving = false);
      }
    });
  }

  Future<void> _loadDraftData() async {
    final draftData = await _storageService.loadIncomeDraft(_selectedDate);

    if (draftData != null && draftData.isNotEmpty) {
      setState(() {
        if (draftData.containsKey('online_income')) {
          _onlineIncomeController.text = draftData['online_income']!;
        }
        if (draftData.containsKey('offline_income')) {
          _offlineIncomeController.text = draftData['offline_income']!;
        }
        if (draftData.containsKey('meals_count')) {
          _mealsCountController.text = draftData['meals_count']!;
        }
        _isDraftLoaded = true;
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
  }

  Future<void> _selectDate() async {
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
    }
  }

  Future<void> _saveIncome() async {
    if (_formKey.currentState!.validate()) {
      final onlineIncome = double.tryParse(_onlineIncomeController.text) ?? 0.0;
      final offlineIncome =
          double.tryParse(_offlineIncomeController.text) ?? 0.0;
      final mealsCount = int.tryParse(_mealsCountController.text) ?? 0;

      final income = Income(
        id: widget.existingIncome?.id ?? const Uuid().v4(),
        date: Formatters.normalizeDate(_selectedDate),
        context: 'hotel',
        onlineIncome: onlineIncome,
        offlineIncome: offlineIncome,
        mealsCount: mealsCount,
      );

      setState(() {
        _isLoading = true;
      });

      // Clear draft after saving
      _storageService.clearIncomeDraft(_selectedDate);

      // Save undo entry
      await UndoService.saveIncomeUndo(income);

      context.read<IncomeBloc>().add(UpsertIncome(income));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Auto-save before exiting
        _autoSaveTimer?.cancel();
        final onlineIncome =
            double.tryParse(_onlineIncomeController.text) ?? 0.0;
        final offlineIncome =
            double.tryParse(_offlineIncomeController.text) ?? 0.0;

        if (onlineIncome > 0 || offlineIncome > 0) {
          final draftData = <String, String>{};
          if (_onlineIncomeController.text.isNotEmpty) {
            draftData['online_income'] = _onlineIncomeController.text;
          }
          if (_offlineIncomeController.text.isNotEmpty) {
            draftData['offline_income'] = _offlineIncomeController.text;
          }
          if (_mealsCountController.text.isNotEmpty) {
            draftData['meals_count'] = _mealsCountController.text;
          }
          await _storageService.saveIncomeDraft(_selectedDate, draftData);
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              widget.existingIncome != null ? 'Edit Income' : 'Add Income'),
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
            else if (_isDraftLoaded && widget.existingIncome == null)
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
        body: BlocListener<IncomeBloc, IncomeState>(
          listener: (context, state) {
            if (state is IncomeOperationSuccess) {
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
            } else if (state is IncomeError) {
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
                  const SizedBox(height: 24),

                  // Online Income
                  Text(
                    'Online Income',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PhonePe, GooglePay, etc.',
                    style: AppTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),

                  // Quick Presets for Online Income
                  QuickAmountPresets(
                    onAmountSelected: (amount) {
                      final currentValue =
                          double.tryParse(_onlineIncomeController.text) ?? 0.0;
                      final newValue = currentValue + double.parse(amount);
                      _onlineIncomeController.text =
                          newValue.toStringAsFixed(0);
                    },
                    color: AppTheme.profitColor,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _onlineIncomeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      hintText: '0.00',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VoiceInputButton(
                            onResult: (value) {
                              _onlineIncomeController.text = value;
                            },
                            color: AppTheme.profitColor,
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.phone_android),
                        ],
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null; // Optional field
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
                  const SizedBox(height: 24),

                  // Offline Income
                  Text(
                    'Offline Income',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cash, Flutter Enhance, etc.',
                    style: AppTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),

                  // Quick Presets for Offline Income
                  QuickAmountPresets(
                    onAmountSelected: (amount) {
                      final currentValue =
                          double.tryParse(_offlineIncomeController.text) ?? 0.0;
                      final newValue = currentValue + double.parse(amount);
                      _offlineIncomeController.text =
                          newValue.toStringAsFixed(0);
                    },
                    color: AppTheme.profitColor,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _offlineIncomeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      hintText: '0.00',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VoiceInputButton(
                            onResult: (value) {
                              _offlineIncomeController.text = value;
                            },
                            color: AppTheme.profitColor,
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.money),
                        ],
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null; // Optional field
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
                  const SizedBox(height: 24),

                  // Meals Count
                  Text(
                    'Meals Count',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Number of meals served today',
                    style: AppTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _mealsCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0',
                      suffixIcon: Icon(Icons.restaurant_menu),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null; // Optional field
                      }
                      final parsed = int.tryParse(value);
                      if (parsed == null) {
                        return 'Please enter a valid number';
                      }
                      if (parsed < 0) {
                        return 'Value cannot be negative';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Total Preview
                  Card(
                    color: AppTheme.profitColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Income',
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.profitColor,
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(
                              (double.tryParse(_onlineIncomeController.text) ??
                                      0.0) +
                                  (double.tryParse(
                                          _offlineIncomeController.text) ??
                                      0.0),
                            ),
                            style: AppTheme.headingMedium.copyWith(
                              color: AppTheme.profitColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveIncome,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.profitColor,
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
                            widget.existingIncome != null
                                ? 'Update Income'
                                : 'Save Income',
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
