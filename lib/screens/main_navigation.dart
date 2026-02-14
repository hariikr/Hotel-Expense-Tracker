import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/transactions/cubits/transaction_cubit.dart';
import '../utils/app_theme.dart';
import '../utils/translations.dart';
import '../services/language_service.dart';
import 'dashboard/dashboard_screen.dart';
import 'dashboard/calendar_screen.dart';
import 'dashboard/analytics_screen.dart';
import 'ai/ai_chat_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<CalendarScreenState> _calendarKey =
      GlobalKey<CalendarScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      CalendarScreen(key: _calendarKey),
      const AnalyticsScreen(),
      const AiChatScreen(),
    ];
  }

  String get _languageCode => LanguageService.getLanguageCode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            // Always refresh data when switching tabs
            if (index == 0) {
              context.read<TransactionCubit>().loadTransactions(DateTime.now());
            } else if (index == 1) {
              _calendarKey.currentState?.refresh();
            }
          },
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 0
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 0
                      ? Icons.dashboard
                      : Icons.dashboard_outlined,
                  size: 24,
                ),
              ),
              label: AppTranslations.get(
                AppTranslations.dashboard,
                _languageCode,
              ),
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 1
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 1
                      ? Icons.calendar_month
                      : Icons.calendar_month_outlined,
                  size: 24,
                ),
              ),
              label: AppTranslations.get(
                AppTranslations.calendar,
                _languageCode,
              ),
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 2
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 2
                      ? Icons.analytics
                      : Icons.analytics_outlined,
                  size: 24,
                ),
              ),
              label: AppTranslations.get(
                AppTranslations.analytics,
                _languageCode,
              ),
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 3
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 3
                      ? Icons.smart_toy
                      : Icons.smart_toy_outlined,
                  size: 24,
                ),
              ),
              label: AppTranslations.get(
                AppTranslations.ai,
                _languageCode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
