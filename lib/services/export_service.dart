import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../features/transactions/models/expense_model.dart';
import '../features/transactions/models/income_model.dart';
import '../utils/formatters.dart';

class ExportService {
  /// Export transactions to CSV format
  static Future<void> exportToCSV({
    required List<ExpenseModel> expenses,
    required List<IncomeModel> incomes,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Prepare CSV data
      List<List<dynamic>> csvData = [
        // Header
        ['Date', 'Type', 'Category', 'Amount', 'Description', 'Quantity'],
      ];

      // Add expenses
      for (var expense in expenses) {
        csvData.add([
          Formatters.formatDate(expense.date),
          'Expense',
          expense.categoryName ?? 'Unknown',
          expense.amount.toStringAsFixed(2),
          expense.description ?? '',
          expense.quantity ?? '',
        ]);
      }

      // Add incomes
      for (var income in incomes) {
        csvData.add([
          Formatters.formatDate(income.date),
          'Income',
          income.categoryName ?? 'Unknown',
          income.amount.toStringAsFixed(2),
          income.description ?? '',
          '',
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'transactions_${Formatters.formatDate(startDate).replaceAll('/', '-')}_to_${Formatters.formatDate(endDate).replaceAll('/', '-')}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Transaction Export - $fileName',
        text:
            'Exported transactions from ${Formatters.formatDate(startDate)} to ${Formatters.formatDate(endDate)}',
      );
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Export summary report
  static Future<void> exportSummaryReport({
    required double totalIncome,
    required double totalExpense,
    required double profit,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, double> expenseByCategory,
    required Map<String, double> incomeByCategory,
  }) async {
    try {
      final savingsRate = totalIncome > 0
          ? ((profit / totalIncome) * 100).toStringAsFixed(2)
          : '0.00';

      // Create summary report
      String report = '''
FINANCIAL SUMMARY REPORT
========================

Period: ${Formatters.formatDate(startDate)} to ${Formatters.formatDate(endDate)}
Generated: ${Formatters.formatDateFull(DateTime.now())}

OVERVIEW
--------
Total Income:    ₹${totalIncome.toStringAsFixed(2)}
Total Expense:   ₹${totalExpense.toStringAsFixed(2)}
Net Profit:      ₹${profit.toStringAsFixed(2)}
Savings Rate:    $savingsRate%

EXPENSE BREAKDOWN
-----------------
''';

      expenseByCategory.forEach((category, amount) {
        final percentage = totalExpense > 0
            ? (amount / totalExpense * 100).toStringAsFixed(1)
            : '0.0';
        report +=
            '${category.padRight(20)} ₹${amount.toStringAsFixed(2).padLeft(12)} ($percentage%)\n';
      });

      report += '\nINCOME BREAKDOWN\n-----------------\n';

      incomeByCategory.forEach((category, amount) {
        final percentage = totalIncome > 0
            ? (amount / totalIncome * 100).toStringAsFixed(1)
            : '0.0';
        report +=
            '${category.padRight(20)} ₹${amount.toStringAsFixed(2).padLeft(12)} ($percentage%)\n';
      });

      report += '''

RECOMMENDATIONS
---------------
${profit >= 0 ? '✓ Great job! You\'re in profit this period.' : '⚠ You\'re in loss. Consider reducing expenses.'}
${totalExpense > totalIncome * 0.8 ? '⚠ High expense ratio. Try to save more.' : '✓ Good expense management.'}

========================
End of Report
''';

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'summary_${Formatters.formatDate(startDate).replaceAll('/', '-')}_to_${Formatters.formatDate(endDate).replaceAll('/', '-')}.txt';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(report);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Financial Summary Report',
        text: 'Your financial summary report is attached.',
      );
    } catch (e) {
      throw Exception('Failed to export summary: $e');
    }
  }
}
