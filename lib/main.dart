import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/supabase_service.dart';
import 'features/settings/cubits/category_cubit.dart';
import 'features/settings/repositories/category_repository.dart';
import 'features/transactions/cubits/transaction_cubit.dart';
import 'features/transactions/repositories/transaction_repository.dart';
import 'blocs/auth/auth_bloc.dart';
import 'services/auth_service.dart';
import 'screens/auth/auth_wrapper.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

// Services - (Keeping old ones if needed for other parts, but SupabaseService is replaced)
import 'services/network_service.dart';
import 'services/language_service.dart';
import 'services/notification_service.dart';

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
    // Core Services
    // Note: SupabaseService is a singleton in core/services/supabase_service.dart
    final supabaseService = SupabaseService();

    // Repositories
    final categoryRepository =
        CategoryRepository(supabaseService: supabaseService);
    final transactionRepository =
        TransactionRepository(supabaseService: supabaseService);
    final authService = AuthService();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(authService: authService),
        ),
        BlocProvider(
          create: (context) =>
              CategoryCubit(repository: categoryRepository)..loadCategories(),
        ),
        BlocProvider(
          create: (context) =>
              TransactionCubit(repository: transactionRepository)
                ..loadTransactions(DateTime.now()),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}
