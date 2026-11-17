import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../features/billing/models/bill_model.dart';

class BillPdfService {
  static const String _hotelName = 'Priya Hotel';
  static const String _addressLine1 = 'Near Old Bridge';
  static const String _addressLine2 = 'Kuthithode';
  static const String _phone1 = '8157934209';
  static const String _phone2 = '6282228990';

  static Future<Uint8List> generateBillPdf(BillModel bill) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );

    final currencyFormat = NumberFormat('#,##0.00', 'en_IN');
    final dateFormat = DateFormat('dd MMM yyyy');

    final int totalLines = bill.items.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 60),
        theme: theme,
        header: (context) => _buildHeader(),
        footer: (context) => _buildFooter(),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 15),

            // Minimalist Bill Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn('DATE', dateFormat.format(bill.billDate)),
                _buildInfoColumn('BILL NO.', bill.billNumber, alignRight: true),
              ],
            ),

            pw.SizedBox(height: 35),

            // Clean Customer Section
            pw.Text('CUSTOMER',
                style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0)),
            pw.SizedBox(height: 6),
            pw.Text(bill.customerName.toUpperCase(),
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text('Ph: ${bill.customerPhone}',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),

            pw.SizedBox(height: 40),

            // Ultra-Clean Table
            _buildMinimalTable(bill, currencyFormat),

            pw.SizedBox(height: 30),

            // Totals and Summary
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('TOTAL ITEMS: $totalLines',
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey500)),
                _buildGrandTotal(bill, currencyFormat),
              ],
            ),

            if (bill.notes != null && bill.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 50),
              pw.Text('NOTES',
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.0)),
              pw.SizedBox(height: 4),
              pw.Text(bill.notes!,
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600)),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _hotelName.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 2.5,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text('$_addressLine1, $_addressLine2',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.Text('$_phone1, $_phone2',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 10),
        pw.Container(height: 1.5, color: PdfColors.black),
      ],
    );
  }

  static pw.Widget _buildInfoColumn(String label, String value,
      {bool alignRight = false}) {
    return pw.Column(
      crossAxisAlignment:
          alignRight ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 7,
                color: PdfColors.grey500,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.0)),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildMinimalTable(
      BillModel bill, NumberFormat currencyFormat) {
    return pw.Table(
      border: null,
      columnWidths: {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(50),
        3: const pw.FixedColumnWidth(80),
        4: const pw.FixedColumnWidth(90),
      },
      children: [
        // Modern Minimal Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.5))),
          children: [
            _th('#'),
            _th('DESCRIPTION'),
            _th('QTY'),
            _th('PRICE'),
            _th('TOTAL', alignRight: true),
          ],
        ),
        // Rows with very subtle dividers
        ...bill.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            decoration: const pw.BoxDecoration(
                border: pw.Border(
                    bottom:
                        pw.BorderSide(color: PdfColors.grey200, width: 0.3))),
            children: [
              _td('${index + 1}'),
              _td(item.itemName.toUpperCase()),
              _td('${item.quantity}'),
              _td('Rs. ${currencyFormat.format(item.unitPrice)}'),
              _td('Rs. ${currencyFormat.format(item.totalPrice)}',
                  alignRight: true),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _th(String text, {bool alignRight = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 6, top: 2),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black),
      ),
    );
  }

  static pw.Widget _td(String text, {bool alignRight = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: const pw.TextStyle(fontSize: 9.5),
      ),
    );
  }

  static pw.Widget _buildGrandTotal(
      BillModel bill, NumberFormat currencyFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Container(
          width: 200,
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.black, width: 1.0))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL AMOUNT',
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                'Rs. ${currencyFormat.format(bill.totalAmount)}',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Text(
        'THANK YOU',
        style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 5.0,
            color: PdfColors.grey500),
      ),
    );
  }

  // ===== STATEMENTS =====

  static Future<Uint8List> generateStatementPdf({
    required String customerName,
    required List<BillModel> bills,
    required DateTime startDate,
    required DateTime endDate,
    double discountAmount = 0.0,
    double advanceAmount = 0.0,
  }) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

    final currencyFormat = NumberFormat('#,##0.00', 'en_IN');
    final dateFormat = DateFormat('dd MMM yyyy');

    final subtotal = bills.fold<double>(0, (sum, b) => sum + b.totalAmount);
    final grandTotal = subtotal - discountAmount - advanceAmount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 60),
        theme: theme,
        header: (context) => pw.SizedBox(),
        footer: (context) => context.pageNumber == context.pagesCount
            ? _buildFooter()
            : pw.SizedBox(),
        build: (pw.Context context) {
          // Group bills by date for cleaner organization
          final Map<DateTime, List<BillModel>> groupedBills = {};
          for (var bill in bills) {
            final date = DateTime(
                bill.billDate.year, bill.billDate.month, bill.billDate.day);
            groupedBills.putIfAbsent(date, () => []).add(bill);
          }
          final sortedDates = groupedBills.keys.toList()..sort();

          return [
            _buildHeader(), // Only on the first page
            pw.SizedBox(height: 20),
            pw.Text('CUSTOMER: ${customerName.toUpperCase()}',
                style:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),

            _buildStatementTable(bills, currencyFormat, dateFormat),

            pw.SizedBox(height: 25),

            // Summary Totals
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 200,
                  child: pw.Column(
                    children: [
                      _buildTotalRow('SUBTOTAL', subtotal, currencyFormat),
                      if (discountAmount > 0)
                        _buildTotalRow(
                            'DISCOUNT', discountAmount, currencyFormat,
                            isNegative: true),
                      if (advanceAmount > 0)
                        _buildTotalRow(
                            'ADVANCE PAID', advanceAmount, currencyFormat,
                            isNegative: true),
                      pw.Divider(color: PdfColors.black, thickness: 1),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                                (discountAmount > 0 || advanceAmount > 0)
                                    ? 'BALANCE DUE'
                                    : 'GRAND TOTAL',
                                style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text('Rs. ${currencyFormat.format(grandTotal)}',
                                style: pw.TextStyle(
                                    fontSize: 15,
                                    fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Detailed Bills Section Header
            pw.SizedBox(height: 40),
            pw.Divider(color: PdfColors.grey400, thickness: 0.5),
            pw.SizedBox(height: 10),
            pw.Text('DETAILED ORDER BREAKDOWN',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0,
                    color: PdfColors.grey700)),
            pw.SizedBox(height: 20),

            // Loop through each date group and render details together
            ...sortedDates.map((date) {
              final dayBills = groupedBills[date]!;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border(
                          left:
                              pw.BorderSide(color: PdfColors.black, width: 3)),
                    ),
                    child: pw.Text(
                      dateFormat.format(date).toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  ...dayBills.map((bill) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 20),
                        child: _buildBillDetailInStatement(
                            bill, currencyFormat, dateFormat),
                      )),
                  pw.SizedBox(height: 10),
                ],
              );
            }),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTotalRow(
      String label, double amount, NumberFormat format,
      {bool isNegative = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Text(
            '${isNegative ? "- " : ""}Rs. ${format.format(amount)}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBillDetailInStatement(
      BillModel bill, NumberFormat currencyFormat, DateFormat dateFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Text('ORDER: ${bill.billNumber}',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800)),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FixedColumnWidth(40),
            2: const pw.FixedColumnWidth(60),
            3: const pw.FixedColumnWidth(70),
          },
          children: [
            // Header for breakdown table
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom:
                          pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
              children: [
                pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text('ITEM',
                        style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700))),
                pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text('QTY',
                        style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700))),
                pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text('PRICE',
                        style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700))),
                pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text('TOTAL',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700))),
              ],
            ),
            ...bill.items.map((item) => pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 5),
                        child: pw.Text(item.itemName.toUpperCase(),
                            style: const pw.TextStyle(fontSize: 8.5))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 5),
                        child: pw.Text('${item.quantity}',
                            style: const pw.TextStyle(fontSize: 8.5))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 5),
                        child: pw.Text(
                            'Rs.${currencyFormat.format(item.unitPrice)}',
                            style: const pw.TextStyle(fontSize: 8.5))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 5),
                        child: pw.Text(
                            'Rs.${currencyFormat.format(item.totalPrice)}',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  ],
                )),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: PdfColors.grey200, thickness: 0.3),
      ],
    );
  }

  static pw.Widget _buildStatementTable(List<BillModel> bills,
      NumberFormat currencyFormat, DateFormat dateFormat) {
    return pw.Table(
      border: null,
      columnWidths: {
        0: const pw.FixedColumnWidth(80),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FixedColumnWidth(100),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.5))),
          children: [
            _th('DATE'),
            _th('BILL NUMBER'),
            _th('AMOUNT', alignRight: true),
          ],
        ),
        ...bills.map((bill) => pw.TableRow(
              decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom:
                          pw.BorderSide(color: PdfColors.grey200, width: 0.3))),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10),
                  child: pw.Text(dateFormat.format(bill.billDate).toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
                _td(bill.billNumber),
                _td('Rs. ${currencyFormat.format(bill.totalAmount)}',
                    alignRight: true),
              ],
            )),
      ],
    );
  }
}
