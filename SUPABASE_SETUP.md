# Supabase Setup Guide for Hotel Expense Tracker

## Overview
This document provides detailed instructions for setting up the Supabase backend for your Hotel Expense Tracker application.

## Prerequisites
- A Supabase account (free tier works fine)
- Basic understanding of SQL (helpful but not required)

## Step 1: Create Supabase Project

1. Visit [https://supabase.com](https://supabase.com)
2. Click **"Start your project"** or **"New Project"**
3. Create an organization if you haven't already
4. Create a new project:
   - **Name**: Hotel Expense Tracker
   - **Database Password**: Create a strong password (save it securely!)
   - **Region**: Choose closest to your location
   - **Pricing Plan**: Free tier is sufficient for small-medium hotels
5. Wait 2-3 minutes for project provisioning

## Step 2: Run Database Migration

### Option A: Using SQL Editor (Recommended)

1. In your Supabase Dashboard, navigate to **SQL Editor** (left sidebar)
2. Click **"New Query"**
3. Open the file `supabase/migrations/001_initial_schema.sql` from this project
4. Copy the entire contents
5. Paste into the Supabase SQL Editor
6. Click **"RUN"** (bottom right corner)
7. You should see: **"Success. No rows returned"**

### Option B: Using Supabase CLI

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Run migrations
supabase db push
```

## Step 3: Verify Database Setup

1. Go to **Table Editor** in Supabase Dashboard
2. You should see three tables:
   - ✅ `income`
   - ✅ `expense`
   - ✅ `daily_summary`

3. Click on each table to verify columns exist

### Expected Table Structures

**income table:**
- id, date, online_income, offline_income, created_at, updated_at

**expense table:**
- id, date, fish, meat, chicken, milk, parotta, pathiri, dosa, appam, coconut, vegetables, rice, labor_manisha, labor_midhun, others, created_at, updated_at

**daily_summary table:**
- id, date, total_income, total_expense, profit, meals_count, created_at, updated_at

## Step 4: Get API Credentials

1. Navigate to **Settings** > **API** in your Supabase Dashboard
2. Find your credentials:

```
Project URL: https://xxxxxxxxxxxxx.supabase.co
anon public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxxxx...
```

3. **IMPORTANT**: Use the **anon public** key, NOT the service_role key!

## Step 5: Configure Flutter App

1. Open `lib/utils/constants.dart` in your Flutter project
2. Update these lines:

```dart
static const String supabaseUrl = 'https://xxxxxxxxxxxxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI...your-actual-key';
```

3. Save the file

## Step 6: Test the Connection

1. Run your Flutter app:
```bash
flutter run
```

2. Try adding an income entry
3. Check Supabase Dashboard > Table Editor > income table
4. You should see your entry!

## Row Level Security (RLS) Configuration

### Current Setup (Development/Testing)
The migration script sets up permissive policies that allow all operations. This is fine for development and single-user apps.

### Production Setup (Recommended)

If you want to add user authentication and multi-user support:

1. **Enable Authentication**
   - Go to **Authentication** > **Settings**
   - Enable Email provider (or others like Google, GitHub)

2. **Add user_id column to tables**
```sql
ALTER TABLE income ADD COLUMN user_id UUID REFERENCES auth.users(id);
ALTER TABLE expense ADD COLUMN user_id UUID REFERENCES auth.users(id);
ALTER TABLE daily_summary ADD COLUMN user_id UUID REFERENCES auth.users(id);
```

3. **Update RLS Policies**
```sql
-- Drop existing permissive policies
DROP POLICY IF EXISTS "Enable read access for all" ON income;
DROP POLICY IF EXISTS "Enable insert for all" ON income;
-- ... (drop all)

-- Create user-specific policies
CREATE POLICY "Users can view own income" ON income
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own income" ON income
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own income" ON income
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own income" ON income
  FOR DELETE USING (auth.uid() = user_id);

-- Repeat for expense and daily_summary tables
```

4. **Update Flutter app to handle authentication**

## Realtime Subscriptions

The app uses Supabase Realtime to automatically update when data changes. This is enabled by default, but verify:

1. Go to **Database** > **Replication**
2. Ensure `income`, `expense`, and `daily_summary` tables have replication enabled
3. If not, toggle them on

## Database Functions & Triggers

The migration script creates several automatic functions:

1. **update_updated_at_column()**: Automatically updates the `updated_at` timestamp
2. **calculate_total_income()**: Calculates sum of online and offline income
3. **calculate_total_expense()**: Calculates sum of all expense items
4. **update_daily_summary()**: Auto-creates/updates summary when income/expense changes

These run automatically - no manual intervention needed!

## Backup Strategy

### Manual Backup
1. Go to **Settings** > **Database**
2. Download database backup

### Automated Backups
- Free tier: Daily backups retained for 7 days
- Pro tier: Point-in-time recovery available

## Monitoring & Debugging

### Check Database Logs
1. Go to **Database** > **Query Performance**
2. View slow queries and errors

### API Logs
1. Go to **Logs** > **API Logs**
2. See all API requests and responses

### Realtime Logs
1. Go to **Logs** > **Realtime Logs**
2. Monitor realtime connections

## Troubleshooting

### Problem: "relation does not exist"
**Solution**: Run the migration script again

### Problem: "permission denied"
**Solution**: Check RLS policies are correctly configured

### Problem: No realtime updates
**Solution**: 
1. Check replication is enabled
2. Verify subscription code in Flutter app
3. Check browser/device internet connection

### Problem: Data not saving
**Solution**:
1. Check API credentials in constants.dart
2. View API logs in Supabase
3. Ensure RLS policies allow insert

## Performance Optimization

### Indexes
The migration script includes indexes on date columns. For better performance with large datasets:

```sql
CREATE INDEX idx_income_user_date ON income(user_id, date DESC);
CREATE INDEX idx_expense_user_date ON expense(user_id, date DESC);
```

### Query Optimization
- Limit date ranges when querying large datasets
- Use pagination for large result sets
- Consider materialized views for complex analytics

## Scaling Considerations

### Free Tier Limits
- 500MB database
- 2GB bandwidth
- 50MB file storage
- Sufficient for ~5,000 daily entries

### When to Upgrade
- Approaching 500MB database size
- Need more than 7-day backups
- Require point-in-time recovery
- Need additional team members

## Security Best Practices

1. ✅ Use environment variables for credentials (never commit to git)
2. ✅ Enable RLS on all tables
3. ✅ Use anon key for client-side (never service_role key)
4. ✅ Implement proper authentication before production
5. ✅ Regularly update Supabase client library
6. ✅ Monitor API logs for suspicious activity
7. ✅ Use HTTPS only (enforced by Supabase)
8. ✅ Set up database backups

## Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Realtime Guide](https://supabase.com/docs/guides/realtime)
- [Flutter Supabase Guide](https://supabase.com/docs/guides/with-flutter)

## Support

- Supabase Discord: [discord.supabase.com](https://discord.supabase.com)
- GitHub Issues: Check project repository
- Stack Overflow: Tag with `supabase` and `flutter`

---

**Next Steps**: After completing this setup, return to the [QUICKSTART.md](QUICKSTART.md) to run your Flutter app!
