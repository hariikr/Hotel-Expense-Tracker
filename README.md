# Hotel Expense Tracker 🏨

A professional Flutter application for tracking hotel income and expenses with real-time analytics, built with Supabase backend.

## 📱 Features

### Core Functionality
- **Daily Income Tracking**: Record online (PhonePe, GooglePay) and offline (cash, Flutter Enhance) income
- **Comprehensive Expense Management**: Track 14 expense categories including food items, ingredients, and labor costs
- **Automated Profit Calculation**: Real-time profit/loss calculation using database triggers
- **Calendar View**: Visual representation of daily profits with color coding
  - 🟢 Green: Profitable days
  - 🔴 Red: Loss days
  - ⚫ Gray: Break-even days
- **Meals Counter**: Track number of meals served per day
- **Analytics Dashboard**: Weekly and monthly charts showing income, expense, and profit trends
- **Best Profit Day Highlight**: Automatic detection and display of your most profitable day

### Technical Features
- **Real-time Updates**: Supabase realtime subscriptions for instant data synchronization
- **BLoC State Management**: Clean architecture with separation of concerns
- **Offline Support**: Ready for offline data entry with online sync (expandable)
- **Responsive Design**: Optimized for both mobile and tablet devices
- **Professional UI**: Material Design 3 with custom theme and animations

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Supabase account ([Sign up here](https://supabase.com))
- Android Studio / VS Code with Flutter extensions

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd "Hotel Expense Tracker"
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Supabase**

   a. Create a new project on [Supabase Dashboard](https://app.supabase.com)
   
   b. Navigate to SQL Editor in your Supabase project
   
   c. Run the migration script located at `supabase/migrations/001_initial_schema.sql`
      - This creates all tables, triggers, and functions
      - Sets up Row Level Security (RLS) policies
   
   d. Get your project credentials:
      - Go to Project Settings > API
      - Copy your **Project URL**
      - Copy your **anon/public API key**

4. **Configure the app**

   Open `lib/utils/constants.dart` and update:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 📊 Database Schema

### Tables

#### `income`
- `id` (UUID): Primary key
- `date` (TIMESTAMPTZ): Date of income (unique)
- `online_income` (NUMERIC): Income from digital payments
- `offline_income` (NUMERIC): Cash and other offline income
- `created_at`, `updated_at` (TIMESTAMPTZ): Audit timestamps

#### `expense`
- `id` (UUID): Primary key
- `date` (TIMESTAMPTZ): Date of expense (unique)
- 14 expense category fields (all NUMERIC):
  - Food items: `fish`, `meat`, `chicken`, `milk`
  - Bread items: `parotta`, `dosa`, `appam`
  - Ingredients: `pathiri`, `coconut`, `vegetables`, `rice`
  - Labor: `labor_manisha`, `labor_midhun`
  - Other: `others`
- `created_at`, `updated_at` (TIMESTAMPTZ): Audit timestamps

#### `daily_summary`
- `id` (UUID): Primary key
- `date` (TIMESTAMPTZ): Summary date (unique)
- `total_income` (NUMERIC): Calculated total income
- `total_expense` (NUMERIC): Calculated total expense
- `profit` (NUMERIC): total_income - total_expense
- `meals_count` (INTEGER): Number of meals served
- `created_at`, `updated_at` (TIMESTAMPTZ): Audit timestamps

### Automatic Triggers

The database automatically:
1. Updates `daily_summary` when income or expense is added/modified
2. Calculates totals using database functions
3. Maintains audit timestamps
4. Enforces data integrity with check constraints

## 🏗️ Project Structure

```
lib/
├── blocs/                      # BLoC state management
│   ├── dashboard/             # Dashboard BLoC
│   ├── income/                # Income BLoC
│   └── expense/               # Expense BLoC
├── models/                    # Data models
│   ├── income.dart
│   ├── expense.dart
│   └── daily_summary.dart
├── screens/                   # UI screens
│   ├── dashboard/
│   │   ├── dashboard_screen.dart
│   │   ├── add_income_screen.dart
│   │   ├── add_expense_screen.dart
│   │   ├── calendar_screen.dart
│   │   └── analytics_screen.dart
│   └── widgets/               # Reusable widgets
│       ├── stat_card.dart
│       ├── best_profit_card.dart
│       └── quick_action_button.dart
├── services/                  # Business logic
│   └── supabase_service.dart  # Supabase API wrapper
├── utils/                     # Utilities
│   ├── app_theme.dart         # App theme and colors
│   ├── constants.dart         # App constants
│   └── formatters.dart        # Date and currency formatters
└── main.dart                  # App entry point
```

## 💡 Usage Guide

### Adding Daily Income
1. From Dashboard, tap "Add Income"
2. Select date
3. Enter online income (PhonePe, GooglePay, etc.)
4. Enter offline income (cash, Flutter Enhance, etc.)
5. Tap "Save Income"

### Adding Daily Expenses
1. From Dashboard, tap "Add Expense"
2. Select date
3. Fill in expense categories (only fill what applies)
4. View real-time total calculation at bottom
5. Tap "Save Expense"

### Viewing Calendar
1. Navigate to Calendar View
2. Days are color-coded by profit status
3. Tap any day to see detailed breakdown
4. Edit income/expense directly from day view

### Analytics
1. Navigate to Analytics
2. Switch between Weekly and Monthly tabs
3. View bar charts (weekly) and line charts (monthly)
4. Summary cards show totals for the period

## 🔒 Security

### Row Level Security (RLS)
The database includes RLS policies. Current setup allows:
- All operations for authenticated users
- Read/write access for development (remove in production)

### Production Recommendations
1. Enable Supabase Authentication
2. Update RLS policies to restrict access:
   ```sql
   -- Example: Restrict to authenticated users only
   CREATE POLICY "Users can only access their own data" ON income
     FOR ALL USING (auth.uid() = user_id);
   ```
3. Add user_id column to link data to specific users
4. Implement proper authentication flow in the app

## 🎨 Customization

### Changing Colors
Edit `lib/utils/app_theme.dart`:
```dart
static const Color primaryColor = Color(0xFF2563EB);
static const Color profitColor = Color(0xFF10B981);
static const Color lossColor = Color(0xFFEF4444);
```

### Adding Expense Categories
1. Add column to `expense` table in database
2. Update `Expense` model in `lib/models/expense.dart`
3. Update `calculate_total_expense` function in SQL
4. Add field to `_expenseFields` in `add_expense_screen.dart`

### Currency Symbol
Change in `lib/utils/constants.dart`:
```dart
static const String currencySymbol = '₹'; // Change to $, €, £, etc.
```

## 🧪 Testing

```bash
# Run tests (when implemented)
flutter test

# Run with coverage
flutter test --coverage
```

## 📦 Building for Production

### Android
```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🐛 Troubleshooting

### Supabase Connection Issues
- Verify URL and API key in `constants.dart`
- Check internet connection
- Ensure Supabase project is active
- Check API logs in Supabase Dashboard

### Database Errors
- Verify migration script ran successfully
- Check table structures in Supabase Table Editor
- Review database logs in Supabase

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

## 📚 Dependencies

- `supabase_flutter` - Supabase client for Flutter
- `flutter_bloc` - State management
- `equatable` - Value equality
- `table_calendar` - Calendar widget
- `fl_chart` - Charts and graphs
- `intl` - Internationalization and formatting
- `uuid` - UUID generation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👨‍💻 Author

Created with ❤️ for hotel management

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the excellent backend platform
- Community contributors

## 📞 Support

For issues and questions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review Supabase documentation

---

**Note**: Remember to update `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY` in `lib/utils/constants.dart` before running the app!
