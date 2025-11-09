-- Migration to separate hotel and house data properly
-- This allows different expenses and incomes for hotel and house on the same date

-- Step 1: Add context column to income table (if not exists)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='income' AND column_name='context') THEN
        ALTER TABLE income ADD COLUMN context VARCHAR(10) DEFAULT 'hotel' CHECK (context IN ('hotel', 'house'));
    END IF;
END $$;

-- Step 2: Add context column to expense table (if not exists)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='expense' AND column_name='context') THEN
        ALTER TABLE expense ADD COLUMN context VARCHAR(10) DEFAULT 'hotel' CHECK (context IN ('hotel', 'house'));
    END IF;
END $$;

-- Step 3: Add context column to daily_summary table (if not exists)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='daily_summary' AND column_name='context') THEN
        ALTER TABLE daily_summary ADD COLUMN context VARCHAR(10) DEFAULT 'hotel' CHECK (context IN ('hotel', 'house'));
    END IF;
END $$;

-- Step 4: Update existing data to have 'hotel' context (if NULL)
UPDATE income SET context = 'hotel' WHERE context IS NULL;
UPDATE expense SET context = 'hotel' WHERE context IS NULL;
UPDATE daily_summary SET context = 'hotel' WHERE context IS NULL;

-- Step 5: Drop old unique constraints on date only
ALTER TABLE income DROP CONSTRAINT IF EXISTS income_date_key;
ALTER TABLE expense DROP CONSTRAINT IF EXISTS expense_date_key;
ALTER TABLE daily_summary DROP CONSTRAINT IF EXISTS daily_summary_date_key;

-- Step 6: Create new composite unique constraints on (date, context)
ALTER TABLE income DROP CONSTRAINT IF EXISTS income_date_context_key;
ALTER TABLE income ADD CONSTRAINT income_date_context_key UNIQUE (date, context);

ALTER TABLE expense DROP CONSTRAINT IF EXISTS expense_date_context_key;
ALTER TABLE expense ADD CONSTRAINT expense_date_context_key UNIQUE (date, context);

ALTER TABLE daily_summary DROP CONSTRAINT IF EXISTS daily_summary_date_context_key;
ALTER TABLE daily_summary ADD CONSTRAINT daily_summary_date_context_key UNIQUE (date, context);

-- Step 7: Drop and recreate indexes with context
DROP INDEX IF EXISTS idx_income_date;
DROP INDEX IF EXISTS idx_expense_date;
DROP INDEX IF EXISTS idx_daily_summary_date;

CREATE INDEX idx_income_date_context ON income(date DESC, context);
CREATE INDEX idx_expense_date_context ON expense(date DESC, context);
CREATE INDEX idx_daily_summary_date_context ON daily_summary(date DESC, context);

-- Step 8: Update the update_daily_summary function to handle context
CREATE OR REPLACE FUNCTION update_daily_summary(summary_date TIMESTAMPTZ, summary_context VARCHAR(10) DEFAULT 'hotel')
RETURNS VOID AS $$
DECLARE
    v_total_income NUMERIC := 0;
    v_total_expense NUMERIC := 0;
    v_profit NUMERIC := 0;
    v_meals_count INTEGER := 0;
    v_income_record income;
    v_expense_record expense;
BEGIN
    -- Get income for the date and context
    SELECT * INTO v_income_record FROM income WHERE date = summary_date AND context = summary_context;
    IF FOUND THEN
        v_total_income := calculate_total_income(v_income_record);
        v_meals_count := COALESCE(v_income_record.meals_count, 0);
    END IF;

    -- Get expense for the date and context
    SELECT * INTO v_expense_record FROM expense WHERE date = summary_date AND context = summary_context;
    IF FOUND THEN
        v_total_expense := calculate_total_expense(v_expense_record);
    END IF;

    -- Calculate profit
    v_profit := v_total_income - v_total_expense;

    -- Insert or update daily_summary
    INSERT INTO daily_summary (date, context, total_income, total_expense, profit, meals_count)
    VALUES (summary_date, summary_context, v_total_income, v_total_expense, v_profit, v_meals_count)
    ON CONFLICT (date, context) 
    DO UPDATE SET
        total_income = EXCLUDED.total_income,
        total_expense = EXCLUDED.total_expense,
        profit = EXCLUDED.profit,
        meals_count = EXCLUDED.meals_count,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Step 9: Update trigger functions to pass context
CREATE OR REPLACE FUNCTION trigger_update_summary_on_income()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM update_daily_summary(NEW.date, NEW.context);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trigger_update_summary_on_expense()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM update_daily_summary(NEW.date, NEW.context);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 10: Recreate triggers (drop first to avoid conflicts)
DROP TRIGGER IF EXISTS income_update_summary ON income;
CREATE TRIGGER income_update_summary
    AFTER INSERT OR UPDATE ON income
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_summary_on_income();

DROP TRIGGER IF EXISTS expense_update_summary ON expense;
CREATE TRIGGER expense_update_summary
    AFTER INSERT OR UPDATE ON expense
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_summary_on_expense();

-- Step 11: Handle deletion triggers to clean up summaries
CREATE OR REPLACE FUNCTION trigger_delete_summary_on_income()
RETURNS TRIGGER AS $$
BEGIN
    -- Recalculate summary after deletion (might result in zero values)
    PERFORM update_daily_summary(OLD.date, OLD.context);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trigger_delete_summary_on_expense()
RETURNS TRIGGER AS $$
BEGIN
    -- Recalculate summary after deletion (might result in zero values)
    PERFORM update_daily_summary(OLD.date, OLD.context);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS income_delete_summary ON income;
CREATE TRIGGER income_delete_summary
    AFTER DELETE ON income
    FOR EACH ROW
    EXECUTE FUNCTION trigger_delete_summary_on_income();

DROP TRIGGER IF EXISTS expense_delete_summary ON expense;
CREATE TRIGGER expense_delete_summary
    AFTER DELETE ON expense
    FOR EACH ROW
    EXECUTE FUNCTION trigger_delete_summary_on_expense();

-- Step 12: Make context column NOT NULL (now that we have default values set)
ALTER TABLE income ALTER COLUMN context SET NOT NULL;
ALTER TABLE expense ALTER COLUMN context SET NOT NULL;
ALTER TABLE daily_summary ALTER COLUMN context SET NOT NULL;
