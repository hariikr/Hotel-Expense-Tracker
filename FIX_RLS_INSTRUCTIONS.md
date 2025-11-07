# Fix Row Level Security (RLS) Policy Issue

## Problem
Your app is failing to insert expenses and income due to Row Level Security policy conflicts. The database has conflicting policies - some require authenticated users while others allow anonymous access.

## Solution
Apply the new migration to fix the RLS policies.

## Steps to Fix

### Option 1: Using Supabase Dashboard (Recommended)

1. Go to your Supabase project: https://khpeuremcbkpdmombtkg.supabase.co
2. Navigate to **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy the entire content of `supabase/migrations/002_fix_rls_policies.sql`
5. Paste it into the SQL editor
6. Click **Run** or press `Ctrl+Enter`
7. You should see a success message

### Option 2: Using Supabase CLI (If you have it installed)

```bash
supabase db push
```

## What This Fix Does

The migration will:
1. **Drop all conflicting policies** - Removes the old policies that were blocking inserts
2. **Create unified policies** - Creates new policies that allow all operations for both authenticated and anonymous users
3. **Enable full access** - Uses `USING (true)` and `WITH CHECK (true)` to allow all operations

## Verify the Fix

After applying the migration:

1. Open your Flutter app
2. Try adding a new expense or income entry
3. The insert should now work without Row Level Security errors

## Security Note

⚠️ **Important for Production**: The current policies allow anonymous access for development/testing. For production, you should:

1. Implement proper authentication in your Flutter app
2. Update the policies to require authenticated users:
   ```sql
   CREATE POLICY "Authenticated only" ON income
       FOR ALL 
       USING (auth.role() = 'authenticated')
       WITH CHECK (auth.role() = 'authenticated');
   ```

## Troubleshooting

If you still see errors after applying the migration:

1. **Check if RLS is still enabled**: Run this in SQL Editor:
   ```sql
   SELECT tablename, rowsecurity 
   FROM pg_tables 
   WHERE schemaname = 'public' 
   AND tablename IN ('income', 'expense', 'daily_summary');
   ```
   All should show `rowsecurity = true`

2. **Check active policies**: Run this in SQL Editor:
   ```sql
   SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
   FROM pg_policies
   WHERE tablename IN ('income', 'expense', 'daily_summary');
   ```
   You should see only the new "Allow all operations" policies

3. **Test the policies directly**: Run these test queries in SQL Editor:
   ```sql
   -- Test insert
   INSERT INTO income (date, online_income, offline_income) 
   VALUES (NOW(), 100.00, 50.00);
   
   -- Test insert
   INSERT INTO expense (date, fish, meat) 
   VALUES (NOW(), 200.00, 150.00);
   ```

## Alternative: Disable RLS (Not Recommended for Production)

If you want to completely disable RLS for testing:

```sql
ALTER TABLE income DISABLE ROW LEVEL SECURITY;
ALTER TABLE expense DISABLE ROW LEVEL SECURITY;
ALTER TABLE daily_summary DISABLE ROW LEVEL SECURITY;
```

**Warning**: Only do this in development. Never disable RLS in production!
