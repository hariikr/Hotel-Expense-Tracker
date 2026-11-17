import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import '../../features/billing/cubits/bill_cubit.dart';
import '../../features/billing/models/bill_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../services/bill_pdf_service.dart';
import 'create_bill_screen.dart';
import 'customer_statement_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BillCubit>().loadBills();
  }

  /// Preview PDF in a full-screen dialog, then option to share
  Future<void> _viewBillPdf(BillModel bill) async {
    final pdfBytes = await BillPdfService.generateBillPdf(bill);
    final pdfUint8 = Uint8List.fromList(pdfBytes);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text('Invoice ${bill.billNumber}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share via WhatsApp',
                onPressed: () => _sharePdf(bill, pdfUint8),
              ),
            ],
          ),
          body: PdfPreview(
            build: (_) async => pdfUint8,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            pdfFileName: 'bill_${bill.billNumber}.pdf',
          ),
        ),
      ),
    );
  }

  /// Share PDF as file via WhatsApp / system share
  Future<void> _sharePdf(BillModel bill, [List<int>? existingBytes]) async {
    try {
      final pdfBytes =
          existingBytes ?? await BillPdfService.generateBillPdf(bill);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing PDF: $e')),
        );
      }
    }
  }

  void _deleteBill(BillModel bill) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bill'),
        content: Text(
            'Delete bill ${bill.billNumber}?\nThis will also remove the linked income entry.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BillCubit>().deleteBill(bill.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        toolbarHeight: 68,
        title: AppTheme.appBarTitle(
          'Billing',
          subtitle: 'Create & manage invoices',
          icon: Icons.receipt_long,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            tooltip: 'Customer Statement',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const CustomerStatementScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateBillScreen()),
          );
          if (mounted) {
            context.read<BillCubit>().loadBills();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Bill',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<BillCubit, BillState>(
        builder: (context, state) {
          if (state is BillLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BillError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<BillCubit>().loadBills(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is BillLoaded) {
            if (state.bills.isEmpty) {
              return _buildEmptyState();
            }
            return RefreshIndicator(
              onRefresh: () => context.read<BillCubit>().loadBills(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.bills.length,
                itemBuilder: (context, index) =>
                    _buildBillCard(state.bills[index]),
              ),
            );
          }

          return const Center(child: Text('Loading...'));
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Bills Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first bill by tapping\nthe "New Bill" button below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(BillModel bill) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _viewBillPdf(bill),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      bill.billNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  Text(
                    '₹${bill.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.profitColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    bill.customerName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary, // Ensure visible
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    bill.customerPhone,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.formatDateFull(bill.billDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.restaurant_menu,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${bill.items.length} items',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // View PDF
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf,
                            size: 20, color: AppTheme.primaryColor),
                        onPressed: () => _viewBillPdf(bill),
                        tooltip: 'View PDF',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      const SizedBox(width: 4),
                      // Share
                      IconButton(
                        icon: const Icon(Icons.share,
                            size: 20, color: AppTheme.secondaryColor),
                        onPressed: () => _sharePdf(bill),
                        tooltip: 'Share via WhatsApp',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      const SizedBox(width: 4),
                      // Delete
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: Colors.red),
                        onPressed: () => _deleteBill(bill),
                        tooltip: 'Delete',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
