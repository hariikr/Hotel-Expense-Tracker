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
