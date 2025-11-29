import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsService {
  static const String _dailyReminderKey = 'notification_daily_reminder';
  static const String _lowProfitAlertKey = 'notification_low_profit_alert';
  static const String _weeklySummaryKey = 'notification_weekly_summary';
  static const String _milestoneKey = 'notification_milestone';
  static const String _lowProfitThresholdKey = 'low_profit_threshold';
  static const String _reminderTimeKey = 'reminder_time_hour';

  // Get daily reminder enabled status
  Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dailyReminderKey) ?? true; // Default enabled
  }

  // Set daily reminder enabled status
  Future<void> setDailyReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderKey, enabled);
  }

  // Get low profit alert enabled status
  Future<bool> isLowProfitAlertEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lowProfitAlertKey) ?? true; // Default enabled
  }

  // Set low profit alert enabled status
  Future<void> setLowProfitAlertEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lowProfitAlertKey, enabled);
  }

  // Get weekly summary enabled status
  Future<bool> isWeeklySummaryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_weeklySummaryKey) ?? true; // Default enabled
  }

  // Set weekly summary enabled status
  Future<void> setWeeklySummaryEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weeklySummaryKey, enabled);
  }

  // Get milestone celebration enabled status
  Future<bool> isMilestoneEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_milestoneKey) ?? true; // Default enabled
  }

  // Set milestone celebration enabled status
  Future<void> setMilestoneEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_milestoneKey, enabled);
  }

  // Get low profit threshold
  Future<double> getLowProfitThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_lowProfitThresholdKey) ?? 1000.0; // Default ₹1000
  }

  // Set low profit threshold
  Future<void> setLowProfitThreshold(double threshold) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lowProfitThresholdKey, threshold);
  }

  // Get reminder time (hour in 24-hour format)
  Future<int> getReminderTimeHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_reminderTimeKey) ?? 21; // Default 9 PM
  }

  // Set reminder time (hour in 24-hour format)
  Future<void> setReminderTimeHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderTimeKey, hour);
  }

  // Get all settings
  Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'dailyReminder': await isDailyReminderEnabled(),
      'lowProfitAlert': await isLowProfitAlertEnabled(),
      'weeklySummary': await isWeeklySummaryEnabled(),
      'milestone': await isMilestoneEnabled(),
      'lowProfitThreshold': await getLowProfitThreshold(),
      'reminderTimeHour': await getReminderTimeHour(),
    };
  }
}
