import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/income.dart';
import '../models/expense.dart';

enum EntryType { income, expense }

class UndoEntry {
  final String id;
  final EntryType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  UndoEntry({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type == EntryType.income ? 'income' : 'expense',
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };

  factory UndoEntry.fromJson(Map<String, dynamic> json) {
    return UndoEntry(
      id: json['id'] as String,
      type: json['type'] == 'income' ? EntryType.income : EntryType.expense,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class UndoService {
  static const String _undoKey = 'last_undo_entry';
  static const int _undoTimeoutMinutes = 5; // Undo expires after 5 minutes

  static Future<void> saveUndoEntry({
    required String id,
    required EntryType type,
    required Map<String, dynamic> data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final undoEntry = UndoEntry(
        id: id,
        type: type,
        data: data,
        timestamp: DateTime.now(),
      );

      await prefs.setString(_undoKey, jsonEncode(undoEntry.toJson()));
    } catch (e) {
      print('Error saving undo entry: $e');
    }
  }

  static Future<void> saveIncomeUndo(Income income) async {
    await saveUndoEntry(
      id: income.id,
      type: EntryType.income,
      data: income.toJson(),
    );
  }

  static Future<void> saveExpenseUndo(Expense expense) async {
    await saveUndoEntry(
      id: expense.id,
      type: EntryType.expense,
      data: expense.toJson(),
    );
  }

  static Future<UndoEntry?> getLastUndoEntry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final undoJson = prefs.getString(_undoKey);

      if (undoJson == null) return null;

      final undoEntry = UndoEntry.fromJson(jsonDecode(undoJson));

      // Check if undo has expired
      final timeSinceEntry = DateTime.now().difference(undoEntry.timestamp);
      if (timeSinceEntry.inMinutes > _undoTimeoutMinutes) {
        await clearUndo();
        return null;
      }

      return undoEntry;
    } catch (e) {
      print('Error getting undo entry: $e');
      return null;
    }
  }

  static Future<bool> hasValidUndo() async {
    final entry = await getLastUndoEntry();
    return entry != null;
  }

  static Future<void> clearUndo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_undoKey);
    } catch (e) {
      print('Error clearing undo: $e');
    }
  }

  static Future<String> getUndoMessage() async {
    final entry = await getLastUndoEntry();
    if (entry == null) return '';

    final type = entry.type == EntryType.income ? 'Income' : 'Expense';
    final amount = entry.data['amount'] ?? 0.0;
    final category = entry.data['category'] ?? 'Unknown';

    return 'Undo last $type: ₹$amount ($category)';
  }

  static Future<int> getRemainingUndoTime() async {
    final entry = await getLastUndoEntry();
    if (entry == null) return 0;

    final elapsed = DateTime.now().difference(entry.timestamp);
    final remaining = _undoTimeoutMinutes - elapsed.inMinutes;

    return remaining > 0 ? remaining : 0;
  }
}
