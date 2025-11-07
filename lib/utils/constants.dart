class AppConstants {
  // App Info
  static const String appName = 'Hotel Expense Tracker';
  static const String appVersion = '1.0.0';

  // Supabase Configuration
  // TODO: Replace with your Supabase project URL and anon key
  static const String supabaseUrl = 'https://khpeuremcbkpdmombtkg.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtocGV1cmVtY2JrcGRtb21idGtnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0ODYyMDQsImV4cCI6MjA3NzA2MjIwNH0.PBFteAldiRWOR2t74QajvwqTLEfs2D32oWawakweaN4';

  // Date Formats
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String fullDateFormat = 'MMMM dd, yyyy';
  static const String shortDateFormat = 'dd/MM/yyyy';
  static const String monthYearFormat = 'MMMM yyyy';

  // Currency
  static const String currencySymbol = '₹';
  static const String currencyFormat = '₹ #,##0.00';

  // Expense Categories
  static const List<String> expenseCategories = [
    'Fish',
    'Meat',
    'Chicken',
    'Milk',
    'Parotta',
    'pathiri',
    'Dosa',
    'Appam',
    'Coconut',
    'Vegetables',
    'Rice',
    'Labor - Manisha',
    'Labor - midhun',
    'Others',
  ];

  // Income Categories
  static const List<String> incomeCategories = [
    'Online Income',
    'Offline Income',
  ];

  // Validation Messages
  static const String requiredFieldError = 'This field is required';
  static const String invalidNumberError = 'Please enter a valid number';
  static const String negativeNumberError = 'Value cannot be negative';

  // Success Messages
  static const String incomeSavedSuccess = 'Income saved successfully';
  static const String expenseSavedSuccess = 'Expense saved successfully';
  static const String dataDeletedSuccess = 'Data deleted successfully';

  // Error Messages
  static const String genericError = 'An error occurred. Please try again.';
  static const String networkError =
      'Network error. Please check your connection.';
  static const String dataFetchError = 'Failed to fetch data';

  // Navigation
  static const String dashboardRoute = '/';
  static const String calendarRoute = '/calendar';
  static const String analyticsRoute = '/analytics';
  static const String addIncomeRoute = '/add-income';
  static const String addExpenseRoute = '/add-expense';

  // Defaults
  static const int defaultMealsCount = 0;
  static const double defaultAmount = 0.0;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Chart Settings
  static const int maxChartBars = 7; // for weekly view
  static const int maxMonthlyBars = 31; // for monthly view
  static const double chartBarWidth = 20.0;
  static const double chartSpacing = 8.0;
}
