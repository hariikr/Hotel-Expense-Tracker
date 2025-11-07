# 🚀 Quick Start Guide - Hotel Expense Tracker

## Step-by-Step Setup (5 minutes)

### 1. Supabase Setup ⚡

1. **Create Supabase Project**
   - Go to [supabase.com](https://supabase.com)
   - Click "Start your project"
   - Create a new organization and project
   - Wait for project to be provisioned (~2 minutes)

2. **Run Database Migration**
   - In Supabase Dashboard, go to **SQL Editor**
   - Click "New Query"
   - Copy the entire contents of `supabase/migrations/001_initial_schema.sql`
   - Paste into the SQL Editor
   - Click **RUN** (bottom right)
   - You should see "Success. No rows returned"

3. **Get Your Credentials**
   - Go to **Settings** > **API**
   - Copy your **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - Copy your **anon public** key (long string starting with `eyJ...`)

### 2. Configure Flutter App 📱

1. **Open the project**
   ```bash
   cd "Hotel Expense Tracker"
   ```

2. **Update Supabase credentials**
   - Open `lib/utils/constants.dart`
   - Replace `YOUR_SUPABASE_URL` with your Project URL
   - Replace `YOUR_SUPABASE_ANON_KEY` with your anon key

   ```dart
   static const String supabaseUrl = 'https://xxxxx.supabase.co';
   static const String supabaseAnonKey = 'eyJhbGc...your-actual-key';
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

### 3. Run the App 🎉

```bash
flutter run
```

Select your device (Android emulator, iOS simulator, or physical device)

## First Use

### Adding Your First Income
1. Tap **"Add Income"** on dashboard
2. Select today's date
3. Enter online income: `5000`
4. Enter offline income: `3000`
5. Tap **"Save Income"**

### Adding Your First Expense
1. Tap **"Add Expense"** on dashboard
2. Select today's date
3. Fill in some expenses:
   - Fish: `500`
   - Rice: `300`
   - Vegetables: `200`
   - Labor Manisha: `1000`
4. See total updating live at bottom
5. Tap **"Save Expense"**

### View Your Data
- **Dashboard**: See total income, expense, and profit
- **Calendar View**: See today colored green (profit) or red (loss)
- **Analytics**: View weekly and monthly trends

## Verify Everything Works

✅ **Check Database** (Optional)
- In Supabase Dashboard, go to **Table Editor**
- You should see three tables: `income`, `expense`, `daily_summary`
- Click on `daily_summary` - you should see today's entry with calculated profit!

✅ **Test Realtime Updates**
- Keep the app open
- In Supabase Dashboard, edit a value in `income` table
- Watch the app update automatically (no refresh needed!)

## Common Issues & Fixes

### ❌ "Failed to fetch data"
**Fix**: Check your internet connection and verify Supabase credentials in `constants.dart`

### ❌ "Table does not exist"
**Fix**: Run the SQL migration script again in Supabase SQL Editor

### ❌ Build errors
```bash
flutter clean
flutter pub get
flutter run
```

### ❌ "Invalid API key"
**Fix**: Make sure you copied the **anon/public** key, not the service_role key

## Next Steps

### Customize for Your Hotel
1. **Change Currency**: Edit `currencySymbol` in `lib/utils/constants.dart`
2. **Add/Remove Expense Categories**: 
   - Update database schema
   - Modify `Expense` model
   - Update form in `add_expense_screen.dart`
3. **Change Colors**: Edit `app_theme.dart`

### Add Authentication (Production)
1. Enable Email Auth in Supabase Dashboard
2. Update RLS policies to restrict data by user
3. Implement login screen in Flutter

### Deploy to Play Store/App Store
1. Update app icons and splash screen
2. Build release APK/IPA
3. Follow platform-specific submission guidelines

## Support

- 📖 Full documentation in `README.md`
- 🐛 Check existing issues on GitHub
- 💬 Supabase docs: [supabase.com/docs](https://supabase.com/docs)
- 📱 Flutter docs: [flutter.dev/docs](https://flutter.dev/docs)

## Testing Sample Data

Want to populate with sample data for testing? Run this in Supabase SQL Editor:

```sql
-- Sample income for last 7 days
INSERT INTO income (date, online_income, offline_income)
SELECT 
  CURRENT_DATE - (n || ' days')::INTERVAL,
  (RANDOM() * 5000 + 3000)::NUMERIC(10,2),
  (RANDOM() * 3000 + 2000)::NUMERIC(10,2)
FROM generate_series(0, 6) n;

-- Sample expenses for last 7 days
INSERT INTO expense (date, fish, meat, chicken, vegetables, rice, labor_manisha)
SELECT 
  CURRENT_DATE - (n || ' days')::INTERVAL,
  (RANDOM() * 800 + 200)::NUMERIC(10,2),
  (RANDOM() * 600 + 100)::NUMERIC(10,2),
  (RANDOM() * 500 + 100)::NUMERIC(10,2),
  (RANDOM() * 300 + 100)::NUMERIC(10,2),
  (RANDOM() * 400 + 100)::NUMERIC(10,2),
  1000.00
FROM generate_series(0, 6) n;
```

Now you have a week of data to explore the analytics!

---

**🎊 Congratulations!** Your Hotel Expense Tracker is ready to use. Happy tracking! 📊
