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
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.profitColor,
                  AppTheme.profitColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.trending_up, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.existingIncome != null
                        ? 'Edit Income'
                        : 'Add Income',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    Formatters.formatDateFull(_selectedDate),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            if (_isAutoSaving)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text('Saving...',
                          style: TextStyle(fontSize: 11, color: Colors.white)),
                    ],
                  ),
                ),
              )
            else if (_isDraftLoaded && widget.existingIncome == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.restore, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Draft',
                          style: TextStyle(fontSize: 11, color: Colors.white)),
                    ],
                  ),
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
                  // Date Selector Card - Modern Design
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.profitColor.withOpacity(0.1),
                          AppTheme.profitColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.profitColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.profitColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_rounded,
                                  color: AppTheme.profitColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Income Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Formatters.formatDateFull(_selectedDate),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: AppTheme.profitColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Online Income Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.profitColor.withOpacity(0.2),
                                      AppTheme.profitColor.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.phone_android_rounded,
                                  color: AppTheme.profitColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ONLINE INCOME',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'PhonePe, GooglePay, etc.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Quick Presets for Online Income
                          QuickAmountPresets(
                            onAmountSelected: (amount) {
                              final currentValue = double.tryParse(
                                      _onlineIncomeController.text) ??
                                  0.0;
                              final newValue =
                                  currentValue + double.parse(amount);
                              _onlineIncomeController.text =
                                  newValue.toStringAsFixed(0);
                            },
                            color: AppTheme.profitColor,
                          ),
                          const SizedBox(height: 16),

                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.profitColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.profitColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: TextFormField(
                              controller: _onlineIncomeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.profitColor,
                              ),
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                prefixStyle: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.profitColor,
                                ),
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  color: AppTheme.profitColor.withOpacity(0.3),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
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
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Offline Income Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.profitColor.withOpacity(0.2),
                                      AppTheme.profitColor.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.payments_rounded,
                                  color: AppTheme.profitColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'OFFLINE INCOME',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Cash, Flutter Enhance, etc.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Quick Presets for Offline Income
                          QuickAmountPresets(
                            onAmountSelected: (amount) {
                              final currentValue = double.tryParse(
                                      _offlineIncomeController.text) ??
                                  0.0;
                              final newValue =
                                  currentValue + double.parse(amount);
                              _offlineIncomeController.text =
                                  newValue.toStringAsFixed(0);
                            },
                            color: AppTheme.profitColor,
                          ),
                          const SizedBox(height: 16),

                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.profitColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.profitColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: TextFormField(
                              controller: _offlineIncomeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.profitColor,
                              ),
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                prefixStyle: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.profitColor,
                                ),
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  color: AppTheme.profitColor.withOpacity(0.3),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
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
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Meals Count Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.profitColor.withOpacity(0.2),
                                      AppTheme.profitColor.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.restaurant_menu_rounded,
                                  color: AppTheme.profitColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'MEALS COUNT',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Number of meals served today',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.profitColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.profitColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: TextFormField(
                              controller: _mealsCountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.profitColor,
                              ),
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(
                                  color: AppTheme.profitColor.withOpacity(0.3),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                suffixIcon: const Icon(
                                  Icons.people_alt_rounded,
                                  color: AppTheme.profitColor,
                                ),
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
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Total Preview - Modern Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.profitColor,
                          AppTheme.profitColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.profitColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Income',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Formatters.formatCurrency(
                                    (double.tryParse(
                                                _onlineIncomeController.text) ??
                                            0.0) +
                                        (double.tryParse(
                                                _offlineIncomeController
                                                    .text) ??
                                            0.0),
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.trending_up_rounded,
                            color: Colors.white70,
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 120), // Space for bottom button
                ],
              ),
            ),
          ),
        ),
        // Bottom Navigation Bar with Save Button
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoading
                        ? [Colors.grey.shade400, Colors.grey.shade500]
                        : [
                            AppTheme.profitColor,
                            AppTheme.profitColor.withOpacity(0.8),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: AppTheme.profitColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _saveIncome,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.save_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.existingIncome != null
                                      ? 'Update Income'
                                      : 'Save Income',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
