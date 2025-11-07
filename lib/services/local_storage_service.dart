import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _expenseDraftKey = 'expense_draft_';
  static const String _lastSavedDateKey = 'expense_draft_date';

  // Save expense draft
  Future<void> saveExpenseDraft(
      DateTime date, Map<String, String> values) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = _getDateKey(date);
      final jsonString = jsonEncode(values);
      await prefs.setString('$_expenseDraftKey$dateKey', jsonString);
      await prefs.setString(_lastSavedDateKey, dateKey);
    } catch (e) {
      print('Error saving expense draft: $e');
    }
  }

  // Load expense draft
  Future<Map<String, String>?> loadExpenseDraft(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = _getDateKey(date);
      final jsonString = prefs.getString('$_expenseDraftKey$dateKey');

      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((key, value) => MapEntry(key, value.toString()));
      }
    } catch (e) {
      print('Error loading expense draft: $e');
    }
    return null;
  }

  // Clear expense draft
  Future<void> clearExpenseDraft(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = _getDateKey(date);
      await prefs.remove('$_expenseDraftKey$dateKey');
    } catch (e) {
      print('Error clearing expense draft: $e');
    }
  }

  // Clear all drafts older than 7 days
  Future<void> clearOldDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final now = DateTime.now();

      for (var key in keys) {
        if (key.startsWith(_expenseDraftKey)) {
          final dateStr = key.replaceFirst(_expenseDraftKey, '');
          final draftDate = DateTime.tryParse(dateStr);

          if (draftDate != null) {
            final difference = now.difference(draftDate).inDays;
            if (difference > 7) {
              await prefs.remove(key);
            }
          }
        }
      }
    } catch (e) {
      print('Error clearing old drafts: $e');
    }
  }

  // Check if draft exists
  Future<bool> hasDraft(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = _getDateKey(date);
      return prefs.containsKey('$_expenseDraftKey$dateKey');
    } catch (e) {
      print('Error checking draft: $e');
      return false;
    }
  }

  // Get date key for storage
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Auto-save single field
  Future<void> saveField(DateTime date, String fieldKey, String value) async {
    try {
      final currentDraft = await loadExpenseDraft(date) ?? {};
      currentDraft[fieldKey] = value;
      await saveExpenseDraft(date, currentDraft);
    } catch (e) {
      print('Error saving field: $e');
    }
  }
}
