import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'blocs/dashboard/dashboard_bloc.dart';
import 'blocs/income/income_bloc.dart';
import 'blocs/expense/expense_bloc.dart';
import 'services/supabase_service.dart';
import 'services/offline_first_service.dart';
import 'services/network_service.dart';
import 'services/language_service.dart';
import 'services/notification_service.dart';
import 'screens/main_navigation.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialize Network Service for offline detection
  await NetworkService().initialize();

  // Initialize Language Service
  await LanguageService.initialize();

  // Initialize Notification Service
  await NotificationService().initialize();
  await NotificationService().requestPermissions();

  runApp(const HotelExpenseTrackerApp());
}

class HotelExpenseTrackerApp extends StatelessWidget {
  const HotelExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseClient = Supabase.instance.client;
    final supabaseService = SupabaseService(supabaseClient);
    final offlineFirstService = OfflineFirstService(supabaseService);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DashboardBloc(offlineFirstService),
        ),
        BlocProvider(
          create: (context) => IncomeBloc(offlineFirstService),
        ),
        BlocProvider(
          create: (context) => ExpenseBloc(offlineFirstService),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainNavigation(),
      ),
    );
  }
}
