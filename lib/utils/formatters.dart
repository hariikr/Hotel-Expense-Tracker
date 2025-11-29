import 'package:intl/intl.dart';
import 'constants.dart';

class Formatters {
  // Currency Formatter
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_IN');
    return '${AppConstants.currencySymbol}${formatter.format(amount)}';
  }

  // Compact Currency Formatter (for large numbers)
  static String formatCurrencyCompact(double amount) {
    if (amount >= 100000) {
      return '${AppConstants.currencySymbol}${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${AppConstants.currencySymbol}${(amount / 1000).toStringAsFixed(2)}K';
    }
    return formatCurrency(amount);
  }

  // Date Formatters
  static String formatDate(DateTime date, {String? format}) {
    final formatter = DateFormat(format ?? AppConstants.displayDateFormat);
    return formatter.format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat(AppConstants.shortDateFormat).format(date);
  }

  static String formatDateFull(DateTime date) {
    return DateFormat(AppConstants.fullDateFormat).format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat(AppConstants.monthYearFormat).format(date);
  }

  static String formatMonth(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String formatDayOfWeek(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  // Number Formatters
  static String formatNumber(double number) {
    final formatter = NumberFormat('#,##0.00', 'en_IN');
    return formatter.format(number);
  }

  static String formatInteger(int number) {
    final formatter = NumberFormat('#,##0', 'en_IN');
    return formatter.format(number);
  }

  // Percentage Formatter
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  // Parse String to Double
  static double? parseDouble(String value) {
    return double.tryParse(value.replaceAll(',', ''));
  }

  // Parse String to Int
  static int? parseInt(String value) {
    return int.tryParse(value.replaceAll(',', ''));
  }

  // Relative Date Formatter
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else if (dateToCheck.isAfter(today.subtract(const Duration(days: 7)))) {
      return formatDayOfWeek(date);
    } else {
      return formatDate(date);
    }
  }

  // Get Date Range String
  static String formatDateRange(DateTime start, DateTime end) {
    return '${formatDate(start)} - ${formatDate(end)}';
  }

  // Normalize Date (remove time component)
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Get Week Start Date (Monday)
  static DateTime getWeekStart(DateTime date) {
    final weekday = date.weekday;
    final weekStart = date.subtract(Duration(days: weekday - 1));
    return normalizeDate(weekStart);
  }

  // Get Week End Date (Sunday)
  static DateTime getWeekEnd(DateTime date) {
    final weekday = date.weekday;
    final weekEnd = date.add(Duration(days: 7 - weekday));
    return normalizeDate(weekEnd);
  }

  // Get Month Start Date
  static DateTime getMonthStart(DateTime date) {
    return normalizeDate(DateTime(date.year, date.month, 1));
  }

  // Get Month End Date
  static DateTime getMonthEnd(DateTime date) {
    return normalizeDate(DateTime(date.year, date.month + 1, 0));
  }
}
