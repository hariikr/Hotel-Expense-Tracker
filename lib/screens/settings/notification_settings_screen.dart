import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/notification_settings_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../services/language_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final NotificationSettingsService _settingsService =
      NotificationSettingsService();

  bool _dailyReminderEnabled = true;
  bool _lowProfitAlertEnabled = true;
  bool _weeklySummaryEnabled = true;
  bool _milestoneEnabled = true;
  double _lowProfitThreshold = 1000.0;
  int _reminderTimeHour = 21;

  bool _isLoading = true;

  String get _lang => LanguageService.getLanguageCode();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final settings = await _settingsService.getAllSettings();
    setState(() {
      _dailyReminderEnabled = settings['dailyReminder'];
      _lowProfitAlertEnabled = settings['lowProfitAlert'];
      _weeklySummaryEnabled = settings['weeklySummary'];
      _milestoneEnabled = settings['milestone'];
      _lowProfitThreshold = settings['lowProfitThreshold'];
      _reminderTimeHour = settings['reminderTimeHour'];
      _isLoading = false;
    });
  }

  Future<void> _saveDailyReminder(bool value) async {
    await _settingsService.setDailyReminderEnabled(value);
    if (value) {
      await _notificationService.scheduleDailyReminder();
    } else {
      await _notificationService.cancelDailyReminder();
    }
    setState(() => _dailyReminderEnabled = value);
    _showSavedSnackbar();
  }

  Future<void> _saveLowProfitAlert(bool value) async {
    await _settingsService.setLowProfitAlertEnabled(value);
    setState(() => _lowProfitAlertEnabled = value);
    _showSavedSnackbar();
  }

  Future<void> _saveWeeklySummary(bool value) async {
    await _settingsService.setWeeklySummaryEnabled(value);
    if (value) {
      await _notificationService.scheduleWeeklySummary();
    } else {
      await _notificationService.cancelWeeklySummary();
    }
    setState(() => _weeklySummaryEnabled = value);
    _showSavedSnackbar();
  }

  Future<void> _saveMilestone(bool value) async {
    await _settingsService.setMilestoneEnabled(value);
    setState(() => _milestoneEnabled = value);
    _showSavedSnackbar();
  }

  Future<void> _saveLowProfitThreshold(double value) async {
    await _settingsService.setLowProfitThreshold(value);
    setState(() => _lowProfitThreshold = value);
    _showSavedSnackbar();
  }

  Future<void> _saveReminderTime(int hour) async {
    await _settingsService.setReminderTimeHour(hour);
    await _notificationService.scheduleDailyReminder();
    setState(() => _reminderTimeHour = hour);
    _showSavedSnackbar();
  }

  void _showSavedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(T.get(T.savedSuccessfully, _lang)),
        backgroundColor: AppTheme.profitColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _testDailyReminder() async {
    await _notificationService.showInstantNotification(
      title: T.get(T.dailyEntryReminder, _lang),
      body: T.get(T.dontForgetLog, _lang),
    );
  }

  Future<void> _testWeeklySummary() async {
    await _notificationService.showWeeklySummaryWithData(
      totalIncome: 45000,
      totalExpense: 30000,
      totalProfit: 15000,
      profitableDays: 6,
    );
  }

  Future<void> _testLowProfitAlert() async {
    await _notificationService.showLowProfitAlert(
      todayProfit: 500,
      threshold: _lowProfitThreshold,
    );
  }

  Future<void> _testMilestone() async {
    await _notificationService.showMilestoneCelebration(
      consecutiveProfitDays: 7,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification Settings'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Notification Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Daily Entry Reminder
          _buildNotificationCard(
            icon: Icons.access_time,
            iconColor: AppTheme.primaryColor,
            title: T.get(T.dailyEntryReminder, _lang),
            description: _lang == 'ml'
                ? 'സായാഹ്നം വരുമാനവും ചെലവും രേഖപ്പെടുത്താൻ ഓർമ്മപ്പെടുത്തൽ'
                : 'Remind in the evening to log income and expenses',
            enabled: _dailyReminderEnabled,
            onChanged: _saveDailyReminder,
            child: _dailyReminderEnabled
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        _lang == 'ml'
                            ? 'ഓർമ്മപ്പെടുത്തൽ സമയം'
                            : 'Reminder Time',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTimeSelector(),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _testDailyReminder,
                        icon: const Icon(Icons.send, size: 18),
                        label: Text(
                            _lang == 'ml' ? 'ടെസ്റ്റ്' : 'Test Notification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  )
                : null,
          ),

          const SizedBox(height: 16),

          // Low Profit Alert
          _buildNotificationCard(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
            title: T.get(T.lowProfitAlert, _lang),
            description: _lang == 'ml'
                ? 'ലാഭം പരിധിക്ക് താഴെയാകുമ്പോൾ അറിയിക്കുക'
                : 'Alert when daily profit drops below threshold',
            enabled: _lowProfitAlertEnabled,
            onChanged: _saveLowProfitAlert,
            child: _lowProfitAlertEnabled
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        _lang == 'ml'
                            ? 'ഏറ്റവും കുറഞ്ഞ ലാഭ പരിധി'
                            : 'Minimum Profit Threshold',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildThresholdSelector(),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _testLowProfitAlert,
                        icon: const Icon(Icons.send, size: 18),
                        label: Text(
                            _lang == 'ml' ? 'ടെസ്റ്റ്' : 'Test Notification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  )
                : null,
          ),

          const SizedBox(height: 16),

          // Weekly Summary
          _buildNotificationCard(
            icon: Icons.calendar_today,
            iconColor: AppTheme.profitColor,
            title: T.get(T.weeklyPerformanceSummary, _lang),
            description: _lang == 'ml'
                ? 'എല്ലാ ഞായറാഴ്ചയും സായാഹ്നം ആഴ്ചയുടെ സംഗ്രഹം'
                : 'Every Sunday evening, show week\'s performance',
            enabled: _weeklySummaryEnabled,
            onChanged: _saveWeeklySummary,
            child: _weeklySummaryEnabled
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        _lang == 'ml'
                            ? 'എല്ലാ ഞായർ രാത്രി 8 PM-ന്'
                            : 'Every Sunday at 8 PM',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _testWeeklySummary,
                        icon: const Icon(Icons.send, size: 18),
                        label: Text(
                            _lang == 'ml' ? 'ടെസ്റ്റ്' : 'Test Notification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.profitColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  )
                : null,
          ),

          const SizedBox(height: 16),

          // Milestone Celebrations
          _buildNotificationCard(
            icon: Icons.celebration,
            iconColor: Colors.purple,
            title: _lang == 'ml'
                ? 'മൈൽസ്റ്റോൺ ആഘോഷങ്ങൾ'
                : 'Milestone Celebrations',
            description: _lang == 'ml'
                ? '7, 10, 30 ദിവസത്തെ ലാഭ പരമ്പരയ്ക്കുള്ള സന്തോഷ സന്ദേശം'
                : '🎉 Celebrate 7, 10, 30 day profit streaks!',
            enabled: _milestoneEnabled,
            onChanged: _saveMilestone,
            child: _milestoneEnabled
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        _lang == 'ml'
                            ? '5, 7, 10, 15, 20, 30+ ദിവസത്തെ തുടർച്ചയായ ലാഭത്തിന് അറിയിപ്പുകൾ ലഭിക്കും'
                            : 'Get notified for 5, 7, 10, 15, 20, 30+ days of continuous profit',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _testMilestone,
                        icon: const Icon(Icons.send, size: 18),
                        label: Text(
                            _lang == 'ml' ? 'ടെസ്റ്റ്' : 'Test Notification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  )
                : null,
          ),

          const SizedBox(height: 24),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _lang == 'ml'
                        ? 'എല്ലാ അറിയിപ്പുകളും ഉപകരണത്തിൽ സൂക്ഷിക്കുന്നു. നിങ്ങളുടെ ഡാറ്റ സ്വകാര്യമാണ്.'
                        : 'All notifications are stored on your device. Your data is private.',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool enabled,
    required Function(bool) onChanged,
    Widget? child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onChanged,
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
            if (child != null && enabled) child,
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int hour in [18, 19, 20, 21, 22])
          ChoiceChip(
            label: Text(
              '${hour > 12 ? hour - 12 : hour} ${hour >= 12 ? 'PM' : 'AM'}',
            ),
            selected: _reminderTimeHour == hour,
            onSelected: (selected) {
              if (selected) {
                _saveReminderTime(hour);
              }
            },
            selectedColor: AppTheme.primaryColor,
            labelStyle: TextStyle(
              color: _reminderTimeHour == hour ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildThresholdSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _lowProfitThreshold,
                min: 0,
                max: 10000,
                divisions: 20,
                activeColor: Colors.orange,
                label: '₹${_lowProfitThreshold.toInt()}',
                onChanged: (value) {
                  setState(() => _lowProfitThreshold = value);
                },
                onChangeEnd: _saveLowProfitThreshold,
              ),
            ),
          ],
        ),
        Center(
          child: Text(
            '₹${_lowProfitThreshold.toInt()}',
            style: AppTheme.headingMedium.copyWith(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
