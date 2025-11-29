import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_summary.dart';
import 'notification_service.dart';
import 'notification_settings_service.dart';

class ProfitTrackerService {
  static const String _lastLowProfitCheckKey = 'last_low_profit_check';
  static const String _lastMilestoneKey = 'last_milestone_day';

  final NotificationService _notificationService = NotificationService();
  final NotificationSettingsService _settingsService =
      NotificationSettingsService();

  /// Calculate consecutive profit days from summaries
  int calculateConsecutiveProfitDays(List<DailySummary> summaries) {
    if (summaries.isEmpty) return 0;

    // Sort by date descending (most recent first)
    final sorted = List<DailySummary>.from(summaries)
      ..sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    final today = DateTime.now();

    for (var summary in sorted) {
      // Check if this is a recent day
      final daysDiff = today.difference(summary.date).inDays;
      if (daysDiff > streak) break; // Gap in dates

      if (summary.profit > 0) {
        streak++;
      } else {
        break; // Streak broken
      }
    }

    return streak;
  }

  /// Check and notify about profit milestones
  Future<void> checkAndNotifyMilestone(List<DailySummary> summaries) async {
    final currentStreak = calculateConsecutiveProfitDays(summaries);

    if (currentStreak == 0) return;

    final prefs = await SharedPreferences.getInstance();
    final lastMilestoneDay = prefs.getInt(_lastMilestoneKey) ?? 0;

    // Check for milestones (5, 7, 10, 15, 20, 30, etc.)
    bool isMilestone = false;
    if (currentStreak == 7 ||
        currentStreak == 10 ||
        currentStreak == 30 ||
        (currentStreak >= 5 && currentStreak % 5 == 0)) {
      isMilestone = true;
    }

    // Only notify if this is a new milestone (not already notified for this day count)
    if (isMilestone && currentStreak > lastMilestoneDay) {
      await _notificationService.showMilestoneCelebration(
        consecutiveProfitDays: currentStreak,
      );
      await prefs.setInt(_lastMilestoneKey, currentStreak);
    }
  }

  /// Check and notify about low profit
  Future<void> checkAndNotifyLowProfit(double todayProfit) async {
    final threshold = await _settingsService.getLowProfitThreshold();
    final isEnabled = await _settingsService.isLowProfitAlertEnabled();

    if (!isEnabled) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final lastCheckKey = '$_lastLowProfitCheckKey$dateKey';
    final alreadyNotified = prefs.getBool(lastCheckKey) ?? false;

    // Only notify once per day and if profit is below threshold
    if (!alreadyNotified && todayProfit > 0 && todayProfit < threshold) {
      await _notificationService.showLowProfitAlert(
        todayProfit: todayProfit,
        threshold: threshold,
      );
      await prefs.setBool(lastCheckKey, true);
    }
  }

  /// Calculate weekly stats for summary notification
  Future<Map<String, dynamic>> calculateWeeklyStats(
      List<DailySummary> allSummaries) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final weekEnd = weekStart.add(const Duration(days: 6));

    double totalIncome = 0;
    double totalExpense = 0;
    int profitableDays = 0;

    for (var summary in allSummaries) {
      if (summary.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          summary.date.isBefore(weekEnd.add(const Duration(days: 1)))) {
        totalIncome += summary.totalIncome;
        totalExpense += summary.totalExpense;
        if (summary.profit > 0) profitableDays++;
      }
    }

    final totalProfit = totalIncome - totalExpense;

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'totalProfit': totalProfit,
      'profitableDays': profitableDays,
    };
  }

  /// Send weekly summary notification
  Future<void> sendWeeklySummary(List<DailySummary> summaries) async {
    final stats = await calculateWeeklyStats(summaries);
    await _notificationService.showWeeklySummaryWithData(
      totalIncome: stats['totalIncome'],
      totalExpense: stats['totalExpense'],
      totalProfit: stats['totalProfit'],
      profitableDays: stats['profitableDays'],
    );
  }

  /// Check if entry exists for today
  bool hasEntryForToday(List<DailySummary> summaries) {
    final today = DateTime.now();
    return summaries.any((s) =>
        s.date.year == today.year &&
        s.date.month == today.month &&
        s.date.day == today.day &&
        (s.totalIncome > 0 || s.totalExpense > 0));
  }

  /// Reset streak (call when user starts a new session or on app startup)
  Future<void> resetMilestoneTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastMilestoneKey);
  }
}
