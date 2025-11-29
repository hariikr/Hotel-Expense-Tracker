import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'blocs/dashboard/dashboard_bloc.dart';
import 'blocs/income/income_bloc.dart';
import 'blocs/expense/expense_bloc.dart';
import 'services/supabase_service.dart';
import 'services/language_service.dart';
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

  // Initialize Language Service
  await LanguageService.initialize();

  runApp(const HotelExpenseTrackerApp());
}

class HotelExpenseTrackerApp extends StatelessWidget {
  const HotelExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseClient = Supabase.instance.client;
    final supabaseService = SupabaseService(supabaseClient);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DashboardBloc(supabaseService),
        ),
        BlocProvider(
          create: (context) => IncomeBloc(supabaseService),
        ),
        BlocProvider(
          create: (context) => ExpenseBloc(supabaseService),
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
