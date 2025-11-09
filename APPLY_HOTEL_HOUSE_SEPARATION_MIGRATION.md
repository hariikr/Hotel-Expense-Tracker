# Hotel and House Data Separation Migration Guide

## Problem Description
Previously, the database used a single unique constraint on the `date` field for both income and expense tables. This meant you could only have ONE expense or income entry per date, regardless of whether it was for the hotel or house context. This caused:

1. House expenses overwriting hotel expenses (or vice versa) on the same date
2. Incorrect profit calculations mixing hotel and house data
3. Data loss when switching between contexts

## Solution
The new migration (`004_separate_hotel_house_context.sql`) changes the unique constraint from just `date` to a composite key of `(date, context)`. This allows:

1. **Separate entries** for hotel and house on the same date
2. **Correct calculations** - hotel profit = hotel income - hotel expenses
3. **No data mixing** - house data stays separate from hotel data

## Migration Steps

### Step 1: Apply the Database Migration

You need to run the migration file on your Supabase database. There are two ways to do this:

#### Option A: Using Supabase CLI (Recommended)
```bash
# Make sure you're in the project directory
cd "c:\Users\harik\Desktop\Hotel Expense Tracker"

# Link to your Supabase project (if not already linked)
supabase link --project-ref YOUR_PROJECT_REF

# Apply the migration
supabase db push
```

#### Option B: Using Supabase Dashboard
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Open the file: `supabase/migrations/004_separate_hotel_house_context.sql`
4. Copy the entire contents
5. Paste into the SQL Editor
6. Click **Run** to execute the migration

### Step 2: Verify the Migration

After running the migration, verify it was successful:

```sql
-- Check that context column exists
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name IN ('income', 'expense', 'daily_summary') 
  AND column_name = 'context';

-- Check the unique constraints
SELECT conname, contype, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid IN ('income'::regclass, 'expense'::regclass, 'daily_summary'::regclass)
  AND contype = 'u';

-- Verify you can now insert different contexts on same date
-- (This should succeed without errors)
INSERT INTO expense (date, context, fish) 
VALUES (NOW()::date, 'hotel', 100), (NOW()::date, 'house', 50)
ON CONFLICT (date, context) DO NOTHING;
```

### Step 3: Update Your Flutter App

The Flutter code has already been updated to support the new structure. Make sure you have the latest changes:

**Modified Files:**
- `lib/services/supabase_service.dart` - Updated to use `(date, context)` for upsert operations
- `lib/blocs/income/income_event.dart` - Added context parameter
- `lib/blocs/expense/expense_event.dart` - Added context parameter
- `lib/blocs/income/income_bloc.dart` - Pass context to service calls
- `lib/blocs/expense/expense_bloc.dart` - Pass context to service calls
- `lib/screens/dashboard/add_expense_screen.dart` - Load expense with correct context

### Step 4: Test the Changes

1. **Clear app data** (optional but recommended):
   - Uninstall and reinstall the app, OR
   - Clear app data from device settings

2. **Test hotel expenses:**
   - Switch to Hotel context
   - Add an expense for today
   - Add income for today
   - Verify the profit calculation is correct

3. **Test house expenses:**
   - Switch to House context
   - Add an expense for the SAME date as above
   - Add income for the SAME date
   - Verify house profit is calculated separately

4. **Verify separation:**
   - Switch back to Hotel - you should see hotel data only
   - Switch to House - you should see house data only
   - The data should NOT mix or overwrite each other

## What Changed in the Database

### Before (Incorrect):
```sql
-- Old constraint: only ONE entry per date (total)
UNIQUE (date)

-- This failed when trying to insert:
INSERT INTO expense (date, context, fish) VALUES ('2025-01-01', 'hotel', 100);
INSERT INTO expense (date, context, fish) VALUES ('2025-01-01', 'house', 50);
-- ❌ ERROR: duplicate key value violates unique constraint "expense_date_key"
```

### After (Correct):
```sql
-- New constraint: ONE entry per date PER context
UNIQUE (date, context)

-- This now works perfectly:
INSERT INTO expense (date, context, fish) VALUES ('2025-01-01', 'hotel', 100);
INSERT INTO expense (date, context, fish) VALUES ('2025-01-01', 'house', 50);
-- ✅ SUCCESS: Both rows inserted (different contexts)
```

## Rollback (If Needed)

If you need to rollback this migration:

```sql
-- Remove composite constraints
ALTER TABLE income DROP CONSTRAINT IF EXISTS income_date_context_key;
ALTER TABLE expense DROP CONSTRAINT IF EXISTS expense_date_context_key;
ALTER TABLE daily_summary DROP CONSTRAINT IF EXISTS daily_summary_date_context_key;

-- Restore single date constraints (WARNING: This will fail if you have duplicate dates)
ALTER TABLE income ADD CONSTRAINT income_date_key UNIQUE (date);
ALTER TABLE expense ADD CONSTRAINT expense_date_key UNIQUE (date);
ALTER TABLE daily_summary ADD CONSTRAINT daily_summary_date_key UNIQUE (date);

-- Remove context column (WARNING: This will lose context information)
ALTER TABLE income DROP COLUMN context;
ALTER TABLE expense DROP COLUMN context;
ALTER TABLE daily_summary DROP COLUMN context;
```

## Troubleshooting

### Issue: Migration fails with "duplicate key" error
**Solution:** You have existing data with duplicate dates. You need to either:
1. Delete duplicate entries manually before running migration
2. Update one of the duplicates to a different date
3. Run this query to see duplicates:
```sql
SELECT date, COUNT(*) 
FROM expense 
GROUP BY date 
HAVING COUNT(*) > 1;
```

### Issue: Context column already exists
**Solution:** The migration handles this with `IF NOT EXISTS` checks. It's safe to run again.

### Issue: App shows no data after migration
**Solution:** 
1. Check that existing data has context='hotel' set (default)
2. Verify you're filtering by the correct context in your queries
3. Clear app cache and restart

### Issue: Profit calculations still wrong
**Solution:**
1. Ensure the migration completed successfully
2. Check that triggers are working:
```sql
SELECT tgname, tgenabled FROM pg_trigger WHERE tgrelid IN ('income'::regclass, 'expense'::regclass);
```
3. Manually recalculate summaries:
```sql
-- For hotel
SELECT update_daily_summary(date, 'hotel') FROM income WHERE context = 'hotel';
SELECT update_daily_summary(date, 'hotel') FROM expense WHERE context = 'hotel';

-- For house
SELECT update_daily_summary(date, 'house') FROM income WHERE context = 'house';
SELECT update_daily_summary(date, 'house') FROM expense WHERE context = 'house';
```

## Support

If you encounter any issues:
1. Check the error logs in Supabase Dashboard
2. Verify the migration file executed completely
3. Test with the verification queries above
4. Check that all modified Flutter files are saved and compiled

## Summary

After this migration:
- ✅ Hotel and house data are completely separated
- ✅ You can add expenses/income for both contexts on the same date
- ✅ Profit calculations are accurate per context
- ✅ No more data overwriting or mixing between hotel and house
