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

  void _onDestinationSelected(int index) {
    setState(() => _currentIndex = index);
    // Always refresh data when switching tabs
    if (index == 0) {
      context.read<TransactionCubit>().loadTransactions(DateTime.now());
    } else if (index == 1) {
      _calendarKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.darkSurface)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.today_outlined),
              selectedIcon: const Icon(Icons.today),
              label: AppTranslations.get(AppTranslations.today, _languageCode),
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label:
                  AppTranslations.get(AppTranslations.calendar, _languageCode),
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights),
              label:
                  AppTranslations.get(AppTranslations.analytics, _languageCode),
            ),
            NavigationDestination(
              icon: const Icon(Icons.auto_awesome_outlined),
              selectedIcon: const Icon(Icons.auto_awesome),
              label: AppTranslations.get(AppTranslations.ai, _languageCode),
            ),
          ],
        ),
      ),
    );
  }
}
