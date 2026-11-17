import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import '../../features/billing/cubits/bill_cubit.dart';
import '../../features/billing/models/bill_model.dart';
import '../../features/billing/repositories/bill_repository.dart';
import '../../features/transactions/cubits/transaction_cubit.dart';
import '../../features/settings/cubits/category_cubit.dart';
import '../../core/services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../services/bill_pdf_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CreateBillScreen extends StatefulWidget {
  const CreateBillScreen({super.key});

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  final List<_BillItemEntry> _itemEntries = [_BillItemEntry()];

  bool _isSaving = false;

  // Saved dishes & Customers for autocomplete
  List<Map<String, dynamic>> _savedDishes = [];
  List<Map<String, String>> _customerSuggestions = [];
  final BillRepository _billRepo = BillRepository();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadSavedDishes();
  }

  Future<void> _loadSavedDishes() async {
    try {
      final dishes = await _billRepo.getSavedDishes();
      final customers = await _billRepo.getAllDistinctCustomers();
      if (mounted) {
        setState(() {
          _savedDishes = dishes;
          _customerSuggestions = customers;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    for (final entry in _itemEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  double get _total {
    double total = 0;
    for (final item in _itemEntries) {
      total += item.lineTotal;
    }
    return total;
  }

  void _addItem() {
    setState(() {
      _itemEntries.add(_BillItemEntry());
    });
  }

  void _removeItem(int index) {
    if (_itemEntries.length > 1) {
      setState(() {
        _itemEntries[index].dispose();
        _itemEntries.removeAt(index);
      });
    }
  }

  /// Show saved dishes picker bottom sheet
  void _showSavedDishPicker(int index) {
    if (_savedDishes.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_menu,
                      color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('Select Saved Dish',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _savedDishes.length,
                itemBuilder: (_, i) {
                  final dish = _savedDishes[i];
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.fastfood,
                          size: 18, color: AppTheme.primaryColor),
                    ),
                    title: Text(dish['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text(
                      '₹${(dish['price'] as num).toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.profitColor,
                          fontSize: 15),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _itemEntries[index].nameController.text =
                            dish['name'] as String;
                        _itemEntries[index].priceController.text =
                            (dish['price'] as num).toString();
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) return;

    final validItems = _itemEntries
        .where((e) => e.nameController.text.isNotEmpty && e.lineTotal > 0)
        .toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = SupabaseService().currentUserId;
      if (userId == null) throw Exception('User not logged in');

      final bill = BillModel(
        id: const Uuid().v4(),
        userId: userId,
        billNumber: '',
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        billDate: _selectedDate,
        subtotal: _total,
        totalAmount: _total,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final items = validItems.map((e) {
        return BillItemModel(
          id: const Uuid().v4(),
          billId: '',
          itemName: e.nameController.text.trim(),
          quantity: int.tryParse(e.qtyController.text) ?? 1,
          unitPrice: double.tryParse(e.priceController.text) ?? 0,
          totalPrice: e.lineTotal,
        );
      }).toList();

      final createdBill = await context.read<BillCubit>().createBill(
            bill: bill,
            items: items,
            transactionCubit: context.read<TransactionCubit>(),
            categoryCubit: context.read<CategoryCubit>(),
          );

      if (createdBill != null && mounted) {
        await context.read<TransactionCubit>().loadTransactions(DateTime.now());

        // Generate PDF and show preview
        final pdfBytes = await BillPdfService.generateBillPdf(createdBill);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bill created & income added!'),
              backgroundColor: AppTheme.profitColor,
            ),
          );

          // Navigate to PDF preview (replaces current screen)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => _BillPreviewScreen(
                bill: createdBill,
                pdfBytes: pdfBytes,
              ),
            ),
          );
        }
      } else if (mounted) {
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Create Bill'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateSelector(),
              const SizedBox(height: 16),

              _buildSectionHeader('Customer Details', Icons.person),
              const SizedBox(height: 8),
              _buildCustomerFields(),

              const SizedBox(height: 20),

              // Items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('Bill Items', Icons.restaurant_menu),
                  if (_savedDishes.isNotEmpty)
                    TextButton.icon(
                      onPressed: () =>
                          _showSavedDishPicker(_itemEntries.length - 1),
                      icon: const Icon(Icons.bookmark,
                          size: 16, color: AppTheme.accentColor),
                      label: Text('Saved (${_savedDishes.length})',
                          style: const TextStyle(
                              color: AppTheme.accentColor, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ..._itemEntries.asMap().entries.map((entry) {
                return _buildItemRow(entry.key, entry.value);
              }),

              // Add item button
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add_circle_outline,
                    color: AppTheme.primaryColor),
                label: const Text('Add Item',
                    style: TextStyle(color: AppTheme.primaryColor)),
              ),

              const SizedBox(height: 16),

              // Total
              _buildTotalSummary(),

              const SizedBox(height: 16),

              // Notes
              _buildSectionHeader('Notes (Optional)', Icons.note),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Any additional notes...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveBill,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.receipt, color: Colors.white),
                  label: Text(
                    _isSaving ? 'Creating Bill...' : 'Save & Preview Bill',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
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
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bill Date',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  Formatters.formatDateFull(_selectedDate),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit_calendar, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Autocomplete<Map<String, String>>(
            displayStringForOption: (option) => option['name']!,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Map<String, String>>.empty();
              }
              return _customerSuggestions.where((option) {
                return option['name']!
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (Map<String, String> selection) {
              setState(() {
                _customerNameController.text = selection['name']!;
                _customerPhoneController.text = selection['phone']!;
              });
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              if (controller.text != _customerNameController.text) {
                controller.text = _customerNameController.text;
              }
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (val) => _customerNameController.text = val,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  prefixIcon: Icon(Icons.person_outline),
                  filled: false,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter customer name'
                    : null,
              );
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _customerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
              filled: false,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter phone number' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index, _BillItemEntry item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: item.nameController,
                  decoration: const InputDecoration(
                    hintText: 'Dish name',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              // Pick saved dish
              if (_savedDishes.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.bookmark_border,
                      size: 20, color: AppTheme.accentColor),
                  onPressed: () => _showSavedDishPicker(index),
                  tooltip: 'Pick saved dish',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              if (_itemEntries.length > 1)
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  onPressed: () => _removeItem(index),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: item.qtyController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: item.priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Price (₹)',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.profitColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹${item.lineTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.profitColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.05),
            AppTheme.profitColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('TOTAL',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppTheme.primaryColor)),
          Text(
            '₹${_total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppTheme.profitColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// PDF Preview screen shown after bill creation
class _BillPreviewScreen extends StatelessWidget {
  final BillModel bill;
  final List<int> pdfBytes;

  const _BillPreviewScreen({required this.bill, required this.pdfBytes});

  Future<void> _sharePdf(BuildContext context) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/bill_${bill.billNumber.replaceAll('-', '_')}.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Invoice ${bill.billNumber} - Priya Hotel',
        text:
            'Dear ${bill.customerName}, please find your invoice from Priya Hotel attached.\n\nBill No: ${bill.billNumber}\nTotal: ₹${bill.totalAmount.toStringAsFixed(2)}\n\nThank you for dining with us!',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${bill.billNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share via WhatsApp',
            onPressed: () => _sharePdf(context),
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) async => Uint8List.fromList(pdfBytes),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: 'bill_${bill.billNumber}.pdf',
      ),
    );
  }
}

/// Helper class to hold controllers for each bill item row
class _BillItemEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController(text: '1');
  final TextEditingController priceController = TextEditingController();

  double get lineTotal {
    final qty = int.tryParse(qtyController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;
    return qty * price;
  }

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
  }
}
