# Apply Migration Script

## To apply the meals_count migration to your Supabase database:

### Method 1: Using Supabase Dashboard (Recommended)
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `supabase/migrations/003_add_meals_count_to_income.sql`
4. Click **Run** to execute the migration

### Method 2: Using Supabase CLI
If you have Supabase CLI installed:
```bash
supabase db push
```

### Method 3: Manual SQL Execution
Run this SQL in your Supabase SQL Editor:

```sql
-- Add meals_count to income table
ALTER TABLE income ADD COLUMN IF NOT EXISTS meals_count INTEGER DEFAULT 0 CHECK (meals_count >= 0);

-- Update the daily_summary trigger to include meals_count from income
CREATE OR REPLACE FUNCTION update_daily_summary(summary_date TIMESTAMPTZ)
RETURNS VOID AS $$
DECLARE
    v_total_income NUMERIC := 0;
    v_total_expense NUMERIC := 0;
    v_profit NUMERIC := 0;
    v_meals_count INTEGER := 0;
    v_income_record income;
    v_expense_record expense;
BEGIN
    -- Get income for the date
    SELECT * INTO v_income_record FROM income WHERE date = summary_date;
    IF FOUND THEN
        v_total_income := calculate_total_income(v_income_record);
        v_meals_count := COALESCE(v_income_record.meals_count, 0);
    END IF;

    -- Get expense for the date
    SELECT * INTO v_expense_record FROM expense WHERE date = summary_date;
    IF FOUND THEN
        v_total_expense := calculate_total_expense(v_expense_record);
    END IF;

    -- Calculate profit
    v_profit := v_total_income - v_total_expense;

    -- Insert or update daily_summary
    INSERT INTO daily_summary (date, total_income, total_expense, profit, meals_count)
    VALUES (summary_date, v_total_income, v_total_expense, v_profit, v_meals_count)
    ON CONFLICT (date) 
    DO UPDATE SET
        total_income = EXCLUDED.total_income,
        total_expense = EXCLUDED.total_expense,
        profit = EXCLUDED.profit,
        meals_count = EXCLUDED.meals_count,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;
```

## After Migration:
The app will now store and display meals count for each day!

## To add context support for hotel/house switching:

Run this SQL in your Supabase SQL Editor:

```sql
-- Add context to income table
ALTER TABLE income ADD COLUMN IF NOT EXISTS context TEXT DEFAULT 'hotel' CHECK (context IN ('hotel', 'house'));

-- Add context to expense table
ALTER TABLE expense ADD COLUMN IF NOT EXISTS context TEXT DEFAULT 'hotel' CHECK (context IN ('hotel', 'house'));

-- Update existing records to have 'hotel' context
UPDATE income SET context = 'hotel' WHERE context IS NULL;
UPDATE expense SET context = 'hotel' WHERE context IS NULL;

-- Make context NOT NULL
ALTER TABLE income ALTER COLUMN context SET NOT NULL;
ALTER TABLE expense ALTER COLUMN context SET NOT NULL;
```

## After Context Migration:
The app now supports switching between hotel and house expense tracking!
