# Export Feature Guide

## Overview
The Hotel Expense Tracker now includes a comprehensive data export system that allows users to export their financial data in multiple formats for reporting, backup, and analysis purposes.

## Features Added

### 1. **Export Service** (`lib/services/export_service.dart`)
A dedicated service for handling all export operations with two main export methods:

#### CSV Export
- **Purpose**: Export raw transaction data for spreadsheet analysis
- **File Format**: `.csv` (Comma-Separated Values)
- **Includes**:
  - Transaction date
  - Transaction type (Expense/Income)
  - Category name
  - Amount
  - Description
  - Quantity (for expenses)

#### Summary Report Export
- **Purpose**: Generate comprehensive financial analysis report
- **File Format**: `.txt` (Plain Text)
- **Includes**:
  - Period overview with date range
  - Total income, expense, and profit/loss
  - Savings rate percentage
  - Expense breakdown by category with percentages
  - Income breakdown by category with percentages
  - Smart recommendations based on financial performance

### 2. **Analytics Screen Integration**
- **Location**: [analytics_screen.dart](lib/screens/dashboard/analytics_screen.dart)
- **New Button**: Download icon button in app bar
- **Dialog Interface**: Clean selection dialog for choosing export type

### 3. **User Experience Features**
- **Loading Indicators**: Shows progress during export
- **Success Notifications**: Green snackbar confirms successful export
- **Error Handling**: Red snackbar displays error messages
- **Native Sharing**: Uses device share sheet for file distribution

## How to Use

### Exporting Data

1. **Navigate to Analytics Screen**
   - Open the app
   - Tap on "Analytics & Insights" from the dashboard

2. **Select Time Period**
   - Use the dropdown to select:
     - This Week
     - This Month
     - This Year

3. **Initiate Export**
   - Tap the download icon (📥) in the app bar
   - Choose your export type:
     - **Export CSV**: For raw data analysis
     - **Export Summary**: For formatted reports

4. **Share or Save**
   - The system share sheet will appear
   - Choose where to save or how to share:
     - Email
     - WhatsApp
     - Drive
     - Save to Files
     - Any other sharing option on your device

## File Naming Convention

### CSV Files
```
transactions_DD-MM-YYYY_to_DD-MM-YYYY.csv
```
Example: `transactions_01-01-2024_to_31-01-2024.csv`

### Summary Reports
```
summary_DD-MM-YYYY_to_DD-MM-YYYY.txt
```
Example: `summary_01-01-2024_to_31-01-2024.txt`

## Sample Outputs

### CSV Export Sample
```csv
Date,Type,Category,Amount,Description,Quantity
01/01/2024,Expense,Food,500.00,Groceries,
02/01/2024,Income,Salary,50000.00,Monthly Salary,
03/01/2024,Expense,Transport,200.00,Fuel,2
```

### Summary Report Sample
```
FINANCIAL SUMMARY REPORT
========================

Period: 01/01/2024 to 31/01/2024
Generated: January 31, 2024 11:30 PM

OVERVIEW
--------
Total Income:    ₹50000.00
Total Expense:   ₹15000.00
Net Profit:      ₹35000.00
Savings Rate:    70.00%

EXPENSE BREAKDOWN
-----------------
Food                 ₹5000.00     (33.3%)
Transport            ₹4000.00     (26.7%)
Utilities            ₹3000.00     (20.0%)
Entertainment        ₹3000.00     (20.0%)

INCOME BREAKDOWN
-----------------
Salary               ₹50000.00    (100.0%)

RECOMMENDATIONS
---------------
✓ Great job! You're in profit this period.
✓ Good expense management.

========================
End of Report
```

## Technical Details

### Dependencies
- **csv**: `^6.0.0` - For CSV file generation
- **path_provider**: `^2.1.2` - For accessing device storage
- **share_plus**: `^7.2.2` - For native sharing functionality

### Storage Location
Files are temporarily stored in the app's documents directory and shared via the native share sheet. Users can choose permanent storage location during sharing.

### Error Handling
The service includes comprehensive error handling for:
- Permission issues
- Storage unavailable
- Export failures
- Network issues (if cloud storage is selected)

## Benefits

1. **Backup**: Create regular backups of transaction data
2. **Analysis**: Use CSV files in Excel, Google Sheets, or other tools
3. **Tax Preparation**: Export yearly data for tax filing
4. **Reporting**: Generate professional reports for stakeholders
5. **Sharing**: Easily share financial summaries with accountants or partners

## Future Enhancements (Potential)

- PDF export with charts and visualizations
- Scheduled automatic exports
- Cloud storage integration (Google Drive, Dropbox)
- Custom date range selector
- Excel format (.xlsx) export
- Email integration for automatic report sending
- Template customization for reports

## Troubleshooting

### Export Button Not Showing
- Ensure you're on the Analytics screen
- Check that you have transactions for the selected period

### Share Sheet Not Appearing
- Grant storage permissions to the app
- Check device storage availability
- Restart the app if issue persists

### File Not Found After Export
- Files are shared directly via share sheet
- Choose "Save to Files" or similar option to keep a permanent copy
- Files are in the app's documents directory

## Code Structure

```
lib/
├── services/
│   └── export_service.dart          # Main export logic
├── screens/
│   └── dashboard/
│       └── analytics_screen.dart    # Export UI integration
└── widgets/
    └── empty_state_widget.dart      # Empty state components
```

## API Reference

### ExportService.exportToCSV()
```dart
Future<void> exportToCSV({
  required List<ExpenseModel> expenses,
  required List<IncomeModel> incomes,
  required DateTime startDate,
  required DateTime endDate,
})
```

### ExportService.exportSummaryReport()
```dart
Future<void> exportSummaryReport({
  required double totalIncome,
  required double totalExpense,
  required double profit,
  required DateTime startDate,
  required DateTime endDate,
  required Map<String, double> expenseByCategory,
  required Map<String, double> incomeByCategory,
})
```

## Security & Privacy

- All exports happen locally on the device
- No data is sent to external servers during export
- Users control where exported files are saved/shared
- Files are stored in app-specific directories
- Exports respect user's data privacy

---

**Last Updated**: December 2024
**Version**: 1.0.1
