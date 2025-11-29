import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'notification_settings_service.dart';
import '../utils/formatters.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final NotificationSettingsService _settingsService =
      NotificationSettingsService();

  bool _initialized = false;

  // Notification IDs
  static const int _dailyReminderId = 1;
  static const int _weeklySummaryId = 2;
  static const int _lowProfitAlertId = 3;
  static const int _milestoneId = 4;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  Future<void> requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> scheduleDailyReminder() async {
    await initialize();

    final isEnabled = await _settingsService.isDailyReminderEnabled();
    if (!isEnabled) {
      await _notifications.cancel(_dailyReminderId);
      return;
    }

    // Cancel any existing daily reminder
    await _notifications.cancel(_dailyReminderId);

    // Get reminder time from settings
    final reminderHour = await _settingsService.getReminderTimeHour();

    // Schedule daily reminder
    await _notifications.zonedSchedule(
      _dailyReminderId,
      '📊 Daily Entry Reminder',
      'Don\'t forget to log today\'s income and expenses!',
      _nextInstanceOfTime(reminderHour, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminders',
          channelDescription: 'Daily reminder to add income and expenses',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Schedule weekly summary notification (Every Sunday at 8 PM)
  Future<void> scheduleWeeklySummary() async {
    await initialize();

    final isEnabled = await _settingsService.isWeeklySummaryEnabled();
    if (!isEnabled) {
      await _notifications.cancel(_weeklySummaryId);
      return;
    }

    await _notifications.cancel(_weeklySummaryId);

    // Schedule for Sunday at 8 PM
    await _notifications.zonedSchedule(
      _weeklySummaryId,
      '📈 Weekly Performance Summary',
      'Tap to see this week\'s performance report',
      _nextInstanceOfSunday(20, 0), // 8 PM Sunday
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_summary',
          'Weekly Summary',
          channelDescription: 'Weekly performance summaries',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_summary',
    );
  }

  tz.TZDateTime _nextInstanceOfSunday(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Add days until we reach Sunday (weekday 7)
    while (scheduledDate.weekday != DateTime.sunday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If this Sunday's time has already passed, schedule for next Sunday
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  /// Show low profit alert notification
  Future<void> showLowProfitAlert({
    required double todayProfit,
    required double threshold,
  }) async {
    final isEnabled = await _settingsService.isLowProfitAlertEnabled();
    if (!isEnabled) return;

    await showInstantNotification(
      id: _lowProfitAlertId,
      title: '⚠️ Low Profit Alert',
      body:
          'Today\'s profit (${Formatters.formatCurrency(todayProfit)}) is below your threshold (${Formatters.formatCurrency(threshold)})',
      payload: 'low_profit_alert',
    );
  }

  /// Show milestone celebration notification
  Future<void> showMilestoneCelebration({
    required int consecutiveProfitDays,
  }) async {
    final isEnabled = await _settingsService.isMilestoneEnabled();
    if (!isEnabled) return;

    String emoji = '🎉';
    String title = '';
    String body = '';

    if (consecutiveProfitDays == 7) {
      emoji = '🎉';
      title = 'Amazing! 7-Day Streak!';
      body = 'You\'ve made profit for 7 consecutive days! Keep it up!';
    } else if (consecutiveProfitDays == 10) {
      emoji = '🏆';
      title = 'Incredible! 10-Day Streak!';
      body = 'Outstanding performance! 10 days of continuous profit!';
    } else if (consecutiveProfitDays == 30) {
      emoji = '👑';
      title = 'Legendary! 30-Day Streak!';
      body = 'You\'re on fire! An entire month of profit!';
    } else if (consecutiveProfitDays % 5 == 0) {
      emoji = '✨';
      title = 'Great! ${consecutiveProfitDays}-Day Streak!';
      body =
          '$consecutiveProfitDays consecutive days of profit! Excellent work!';
    } else {
      return; // Only show notifications for milestones (5, 7, 10, 30, etc.)
    }

    await showInstantNotification(
      id: _milestoneId,
      title: '$emoji $title',
      body: body,
      payload: 'milestone_$consecutiveProfitDays',
    );
  }

  /// Show weekly summary with actual data
  Future<void> showWeeklySummaryWithData({
    required double totalIncome,
    required double totalExpense,
    required double totalProfit,
    required int profitableDays,
  }) async {
    final isEnabled = await _settingsService.isWeeklySummaryEnabled();
    if (!isEnabled) return;

    final isProfitable = totalProfit > 0;
    final emoji = isProfitable ? '📈' : '📉';
    final status = isProfitable ? 'Profit' : 'Loss';

    await showInstantNotification(
      id: _weeklySummaryId,
      title: '$emoji Weekly Performance',
      body:
          '$status: ${Formatters.formatCurrency(totalProfit.abs())}\nIncome: ${Formatters.formatCurrency(totalIncome)}\nExpense: ${Formatters.formatCurrency(totalExpense)}\nProfit Days: $profitableDays/7',
      payload: 'weekly_summary_data',
    );
  }

  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(_dailyReminderId);
  }

  Future<void> cancelWeeklySummary() async {
    await _notifications.cancel(_weeklySummaryId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> showInstantNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    final notificationId =
        id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _notifications.show(
      notificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notifications',
          'Instant Notifications',
          channelDescription: 'Instant notifications for app events',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<bool> isDailyReminderEnabled() async {
    final pendingNotifications =
        await _notifications.pendingNotificationRequests();
    return pendingNotifications
        .any((notification) => notification.id == _dailyReminderId);
  }

  Future<bool> isWeeklySummaryEnabled() async {
    final pendingNotifications =
        await _notifications.pendingNotificationRequests();
    return pendingNotifications
        .any((notification) => notification.id == _weeklySummaryId);
  }

  /// Initialize all notifications based on user settings
  Future<void> initializeAllNotifications() async {
    await initialize();
    await scheduleDailyReminder();
    await scheduleWeeklySummary();
  }

  /// Check if entry exists for today and send reminder if not
  Future<void> checkAndSendDailyReminder(bool hasEntryToday) async {
    if (!hasEntryToday) {
      final now = DateTime.now();
      // Only send if it's evening (after 6 PM)
      if (now.hour >= 18) {
        await showInstantNotification(
          title: '📝 Missing Entry',
          body: 'You haven\'t logged today\'s income and expenses yet!',
          payload: 'missing_entry',
        );
      }
    }
  }
}
