import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../blocs/income/income_bloc.dart';
import '../../blocs/income/income_event.dart';
import '../../blocs/expense/expense_bloc.dart';
import '../../blocs/expense/expense_event.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/translations.dart';
import '../../services/language_service.dart';
import '../../widgets/calculator_widget.dart';
import '../../services/smart_insights_service.dart'; // AI insights service
import '../widgets/best_profit_card.dart';
import '../../services/notification_service.dart';
import '../../services/notification_settings_service.dart';
import '../../services/share_service.dart';
import '../../services/undo_service.dart';
import 'add_income_screen.dart';
import 'add_expense_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isNotificationEnabled = false;
  bool _hasUndo = false;
  String _undoMessage = '';
  String _insightsPeriod = 'week'; // AI insights period selector

  String get _lang => LanguageService.getLanguageCode();

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const LoadDashboardData());
    _initializeServices();
    _checkUndoAvailability();
  }

  Future<void> _initializeServices() async {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();

    // Check if daily reminder is enabled from settings
    final settingsService = NotificationSettingsService();
    final enabled = await settingsService.isDailyReminderEnabled();

    if (mounted) {
      setState(() => _isNotificationEnabled = enabled);
    }

    // If enabled, make sure the notification is scheduled
    if (enabled) {
      await notificationService.scheduleDailyReminder();
    }
  }

  Future<void> _checkUndoAvailability() async {
    final hasUndo = await UndoService.hasValidUndo();
    final message = await UndoService.getUndoMessage();
    if (mounted) {
      setState(() {
        _hasUndo = hasUndo;
        _undoMessage = message;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final notificationService = NotificationService();
    final settingsService = NotificationSettingsService();

    // Save the setting first
    await settingsService.setDailyReminderEnabled(value);

    if (value) {
      await notificationService.scheduleDailyReminder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.get(
              {
                'en': 'Daily reminder enabled at 9 PM',
                'ml': 'രാത്രി 9 മണിക്ക് ഡെയ്‌ലി റിമൈൻഡർ സജ്ജമാക്കി'
              },
              _lang,
            )),
            backgroundColor: AppTheme.profitColor,
          ),
        );
      }
    } else {
      await notificationService.cancelDailyReminder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.get(
              {
                'en': 'Daily reminder disabled',
                'ml': 'ഡെയ്‌ലി റിമൈൻഡർ നിർജ്ജീവമാക്കി'
              },
              _lang,
            )),
          ),
        );
      }
    }
    setState(() => _isNotificationEnabled = value);
  }

  Future<void> _handleUndo() async {
    final undoEntry = await UndoService.getLastUndoEntry();
    if (undoEntry == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.get(
          {'en': 'Undo Last Entry', 'ml': 'അവസാന എൻട്രി പഴയപടിയാക്കുക'},
          _lang,
        )),
        content: Text(_undoMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppTranslations.get(AppTranslations.cancel, _lang)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppTranslations.get(
              {'en': 'Undo', 'ml': 'പഴയപടിയാക്കുക'},
              _lang,
            )),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (undoEntry.type == EntryType.income) {
        context.read<IncomeBloc>().add(DeleteIncome(undoEntry.id));
      } else {
        context.read<ExpenseBloc>().add(DeleteExpense(undoEntry.id));
      }
      await UndoService.clearUndo();
      await _checkUndoAvailability();
      context.read<DashboardBloc>().add(const RefreshDashboardData());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.get(
              {
                'en': 'Entry removed successfully',
                'ml': 'എൻട്രി വിജയകരമായി നീക്കം ചെയ്തു'
              },
              _lang,
            )),
          ),
        );
      }
    }
  }

  Future<void> _shareToday() async {
    await ShareService.shareDailySummary(
      date: DateTime.now(),
    );
  }

  Future<void> _testNotification() async {
    final notificationService = NotificationService();
    await notificationService.showInstantNotification(
      title: '🔔 Test Notification',
      body:
          'Notifications are working! You will receive daily reminders at 9 PM.',
      payload: 'test',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.get(
            {
              'en': 'Test notification sent!',
              'ml': 'ടെസ്റ്റ് നോട്ടിഫിക്കേഷൻ അയച്ചു!'
            },
            _lang,
          )),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(Icons.food_bank, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.get(
                    _lang == 'ml'
                        ? {'en': 'Hotel Expense', 'ml': 'ഹോട്ടൽ ചെലവ്'}
                        : {'en': 'Hotel Expense', 'ml': 'ഹോട്ടൽ ചെലവ്'},
                    _lang,
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  AppTranslations.get(AppTranslations.dashboard, _lang),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Share Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.share, size: 20),
            ),
            onPressed: _shareToday,
            tooltip: 'Share Today\'s Summary',
          ),
          // Notification Toggle
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isNotificationEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                size: 20,
              ),
            ),
            tooltip: 'Notification Settings',
            onSelected: (value) async {
              if (value == 'toggle') {
                await _toggleNotifications(!_isNotificationEnabled);
              } else if (value == 'test') {
                await _testNotification();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      _isNotificationEnabled
                          ? Icons.notifications_off
                          : Icons.notifications_active,
                    ),
                    const SizedBox(width: 8),
                    Text(_isNotificationEnabled
                        ? 'Disable Daily Reminder'
                        : 'Enable Daily Reminder (9 PM)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test',
                child: Row(
                  children: [
                    Icon(Icons.bug_report),
                    SizedBox(width: 8),
                    Text('Test Notification'),
                  ],
                ),
              ),
            ],
          ),
          // Refresh Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.refresh, size: 20),
            ),
            onPressed: () {
              context.read<DashboardBloc>().add(const RefreshDashboardData());
              _checkUndoAvailability();
            },
            tooltip: 'Refresh Data',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.lossColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading data',
                    style: AppTheme.headingSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<DashboardBloc>()
                          .add(const LoadDashboardData());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is DashboardLoaded) {
            return RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () async {
                context.read<DashboardBloc>().add(const RefreshDashboardData());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Gradient Section
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Summary Stats with improved design
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            child: _buildSummarySection(state),
                          ),
                        ],
                      ),
                    ),

                    // Main Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Actions - Top Priority
                          _buildSectionHeader('Quick Actions', Icons.flash_on),
                          const SizedBox(height: 12),
                          _buildQuickActions(context),
                          const SizedBox(height: 24),

                          // Best Profit Day - Second Priority
                          if (state.bestProfitDay != null) ...[
                            _buildSectionHeader(
                                'Best Performance', Icons.emoji_events),
                            const SizedBox(height: 12),
                            BestProfitCard(summary: state.bestProfitDay!),
                            const SizedBox(height: 24),
                          ],

                          // AI Smart Insights - Third Priority
                          if (state.allSummaries.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionHeader(
                                    'AI Smart Insights', Icons.psychology),
                                // Period Selector - Compact
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF667EEA)
                                            .withOpacity(0.15),
                                        const Color(0xFF764BA2)
                                            .withOpacity(0.15),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF667EEA)
                                          .withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _insightsPeriod,
                                      isDense: true,
                                      icon: const Icon(Icons.arrow_drop_down,
                                          color: Color(0xFF667EEA), size: 18),
                                      style: const TextStyle(
                                        color: Color(0xFF667EEA),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'today',
                                            child: Text('Today')),
                                        DropdownMenuItem(
                                            value: 'week', child: Text('Week')),
                                        DropdownMenuItem(
                                            value: 'month',
                                            child: Text('Month')),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(
                                              () => _insightsPeriod = value);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildAiSmartInsights(),
                            const SizedBox(height: 24),
                          ],

                          const SizedBox(height: 80), // Space for FAB
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const Center(
            child: Text('ഡാറ്റ ലഭ്യമല്ല'),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Undo Button (if available)
          if (_hasUndo) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleUndo,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.orange,
                          Colors.deepOrange,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.undo_rounded,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          AppTranslations.get(
                            {'en': 'Undo', 'ml': 'പഴയപടിയാക്കുക'},
                            _lang,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Calculator Button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => const CalculatorDialog(),
                );
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calculate_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              tooltip: AppTranslations.get(
                {'en': 'Calculator', 'ml': 'കാൽക്കുലേറ്റർ'},
                _lang,
              ),
              heroTag: 'calculator',
            ),
          ),
        ],
      ),
    );
  }

  // AI-powered Smart Insights Widget
  Widget _buildAiSmartInsights() {
    final insightsService = SmartInsightsService();

    return FutureBuilder<SmartInsightsResponse>(
      future: insightsService.getSmartInsights(period: _insightsPeriod),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF667EEA)),
                    SizedBox(height: 16),
                    Text(
                      'Generating AI insights...',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.insights.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.insights_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Insights Available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.data?.error ?? 'Not enough data for this period',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final response = snapshot.data!;

        return Column(
          children: [
            // Summary Card (if available)
            if (response.summary != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.summarize_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _insightsPeriod == 'today'
                                ? 'Today\'s Summary'
                                : _insightsPeriod == 'week'
                                    ? 'Weekly Summary'
                                    : 'Monthly Summary',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              'Profit',
                              '₹${response.summary!.profit.toStringAsFixed(0)}',
                              Icons.trending_up_rounded,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              'Margin',
                              '${response.summary!.profitMargin.toStringAsFixed(1)}%',
                              Icons.percent_rounded,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              'Days',
                              '${response.summary!.profitableDays}/${response.summary!.totalDays}',
                              Icons.calendar_today_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Insights List
            ...response.insights.map((insight) => _buildInsightCard(insight)),
          ],
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildInsightCard(SmartInsight insight) {
    final color = _getInsightColor(insight.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with gradient background
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  insight.icon,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          insight.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    insight.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    insight.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getInsightColor(String type) {
    switch (type) {
      case 'profit':
        return Colors.green;
      case 'expense':
        return Colors.orange;
      case 'income':
        return Colors.blue;
      case 'trend':
        return Colors.purple;
      case 'warning':
        return Colors.red;
      case 'suggestion':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTheme.headingSmall.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(DashboardLoaded state) {
    return Column(
      children: [
        // Income and Expense Row
        Row(
          children: [
            Expanded(
              child: _buildModernStatCard(
                title: 'Income',
                value: Formatters.formatCurrency(state.totalIncome),
                icon: Icons.arrow_upward_rounded,
                gradient: AppTheme.profitGradient,
                trend: '+12.5%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernStatCard(
                title: 'Expense',
                value: Formatters.formatCurrency(state.totalExpense),
                icon: Icons.arrow_downward_rounded,
                gradient: AppTheme.lossGradient,
                trend: '+8.3%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Net Profit Card - Larger
        _buildProfitCard(state),
      ],
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
    String? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCard(DashboardLoaded state) {
    final isProfit = state.totalProfit >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient:
                  isProfit ? AppTheme.profitGradient : AppTheme.lossGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isProfit
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Profit',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(state.totalProfit),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isProfit ? AppTheme.profitColor : AppTheme.lossColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isProfit ? AppTheme.profitColor : AppTheme.lossColor)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isProfit ? '+15.2%' : '-8.5%',
              style: TextStyle(
                color: isProfit ? AppTheme.profitColor : AppTheme.lossColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            label: 'Add Income',
            icon: Icons.add_circle_rounded,
            gradient: AppTheme.profitGradient,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddIncomeScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            context,
            label: 'Add Expense',
            icon: Icons.remove_circle_rounded,
            gradient: AppTheme.lossGradient,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddExpenseScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
