import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/translations.dart';
import '../services/language_service.dart';
import '../widgets/language_toggle.dart';
import 'dashboard/dashboard_screen.dart';
import 'dashboard/calendar_screen.dart';
import 'dashboard/analytics_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    CalendarScreen(),
    AnalyticsScreen(),
  ];

  String get _languageCode => LanguageService.getLanguageCode();

  void _onLanguageChanged() {
    setState(() {});
  }

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Language Toggle Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Center(
                child: LanguageToggle(
                  onLanguageChanged: _onLanguageChanged,
                ),
              ),
            ),
            // Bottom Navigation
            BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
