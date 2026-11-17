import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../features/billing/cubits/bill_cubit.dart';
import '../../services/bill_pdf_service.dart';

class CustomerStatementScreen extends StatefulWidget {
  const CustomerStatementScreen({super.key});

  @override
  State<CustomerStatementScreen> createState() =>
      _CustomerStatementScreenState();
}

class _CustomerStatementScreenState extends State<CustomerStatementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController =
      TextEditingController(text: '0');
  final TextEditingController _advanceController =
      TextEditingController(text: '0');
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 10));
  DateTime _endDate = DateTime.now();
  List<Map<String, String>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final suggestions = await context.read<BillCubit>().getDistinctCustomers();
    setState(() {
      _suggestions = suggestions;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _generateReport() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a customer name or phone')),
      );
      return;
    }

    context.read<BillCubit>().getCustomerStatement(
          query: query,
          startDate: _startDate,
          endDate: _endDate,
        );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Statement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Input
            Autocomplete<Map<String, String>>(
              displayStringForOption: (option) => option['name']!,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Map<String, String>>.empty();
                }
                return _suggestions.where((option) {
                  return option['name']!
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()) ||
                      option['phone']!.contains(textEditingValue.text);
                });
              },
              onSelected: (Map<String, String> selection) {
                _searchController.text = selection['name']!;
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                _searchController.text = controller.text; // Sync
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Search Customer (Name or Phone)',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Date Selection
            InkWell(
              onTap: () => _selectDateRange(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 20, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date Range',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Discount Input
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Statement Discount (Rs.)',
                prefixIcon: const Icon(Icons.loyalty),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
                helperText:
                    'This discount applies to the total statement amount',
              ),
            ),
            const SizedBox(height: 16),

            // Advance Input
            TextField(
              controller: _advanceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Advance Amount (Rs.)',
                prefixIcon: const Icon(Icons.payment),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
                helperText: 'Any advance payment received from the customer',
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _generateReport,
              icon: const Icon(Icons.summarize),
              label: const Text('GENERATE STATEMENT'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),

            // Results / Preview Area
            Expanded(
              child: BlocBuilder<BillCubit, BillState>(
                builder: (context, state) {
                  if (state is BillLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is BillStatementLoaded) {
                    if (state.bills.isEmpty) {
                      return const Center(
                        child: Text(
                            'No orders found for this customer in the selected range.'),
                      );
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: state.bills.length,
                            itemBuilder: (context, index) {
                              final bill = state.bills[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(bill.billNumber),
                                  subtitle:
                                      Text(dateFormat.format(bill.billDate)),
                                  trailing: Text(
                                    'Rs. ${bill.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showPdfPreview(state),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('VIEW PDF STATEMENT'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else if (state is BillError) {
                    return Center(
                        child: Text('Error: ${state.message}',
                            style: const TextStyle(color: Colors.red)));
                  }
                  return const Center(
                    child:
                        Text('Enter a customer name and date range to begin.'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPdfPreview(BillStatementLoaded state) {
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final advance = double.tryParse(_advanceController.text) ?? 0.0;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('Statement - ${state.customerName}')),
          body: PdfPreview(
            build: (format) => BillPdfService.generateStatementPdf(
              customerName: state.customerName,
              bills: state.bills,
              startDate: state.startDate,
              endDate: state.endDate,
              discountAmount: discount,
              advanceAmount: advance,
            ),
            canChangeOrientation: false,
            canChangePageFormat: false,
          ),
        ),
      ),
    );
  }
}
