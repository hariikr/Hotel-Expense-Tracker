-- Migration: Fix Missing Functions for Multi-Tenancy
-- Description: Updates get_category_total and compare_date_ranges to support user_id

-- FUNCTION: get_category_total
DROP FUNCTION IF EXISTS get_category_total(text, text, text);
CREATE OR REPLACE FUNCTION get_category_total(category_name TEXT, start_date TEXT, end_date TEXT, target_user_id UUID)
RETURNS TABLE (
    category TEXT,
    total_amount NUMERIC
) AS $$
DECLARE
    col_name TEXT;
    query TEXT;
BEGIN
    -- Validate category name to prevent SQL injection (basic check)
    -- Allowed: fish, meat, chicken, milk, parotta, pathiri, dosa, appam, coconut, vegetables, rice, labor_manisha, labor_midhun, others
    -- We'll just map/validate against known columns or use strict equality in dynamic query if needed.
    -- Better: Construct query dynamically but safely.
    
    -- Map input category to column name
    CASE category_name
        WHEN 'fish' THEN col_name := 'fish';
        WHEN 'meat' THEN col_name := 'meat';
        WHEN 'chicken' THEN col_name := 'chicken';
        WHEN 'milk' THEN col_name := 'milk';
        WHEN 'parotta' THEN col_name := 'parotta';
        WHEN 'pathiri' THEN col_name := 'pathiri';
        WHEN 'dosa' THEN col_name := 'dosa';
        WHEN 'appam' THEN col_name := 'appam';
        WHEN 'coconut' THEN col_name := 'coconut';
        WHEN 'vegetables' THEN col_name := 'vegetables';
        WHEN 'rice' THEN col_name := 'rice';
        WHEN 'labor_manisha' THEN col_name := 'labor_manisha';
        WHEN 'labor_midhun' THEN col_name := 'labor_midhun';
        WHEN 'others' THEN col_name := 'others';
        ELSE col_name := NULL;
    END CASE;

    IF col_name IS NULL THEN
        RETURN;
    END IF;

    query := format('SELECT %L, COALESCE(SUM(%I), 0) FROM expense WHERE date >= %L::DATE AND date <= %L::DATE AND user_id = %L', category_name, col_name, start_date, end_date, target_user_id);
    
    RETURN QUERY EXECUTE query;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- FUNCTION: compare_date_ranges
DROP FUNCTION IF EXISTS compare_date_ranges(text, text, text, text);
CREATE OR REPLACE FUNCTION compare_date_ranges(
    start_date1 TEXT, end_date1 TEXT, 
    start_date2 TEXT, end_date2 TEXT,
    target_user_id UUID
)
RETURNS TABLE (
    period1_income NUMERIC,
    period1_expense NUMERIC,
    period1_profit NUMERIC,
    period2_income NUMERIC,
    period2_expense NUMERIC,
    period2_profit NUMERIC,
    income_growth NUMERIC,
    expense_growth NUMERIC,
    profit_growth NUMERIC
) AS $$
DECLARE
    p1_income NUMERIC := 0;
    p1_expense NUMERIC := 0;
    p1_profit NUMERIC := 0;
    p2_income NUMERIC := 0;
    p2_expense NUMERIC := 0;
    p2_profit NUMERIC := 0;
    inc_growth NUMERIC := 0;
    exp_growth NUMERIC := 0;
    prof_growth NUMERIC := 0;
BEGIN
    -- Period 1
    SELECT 
        COALESCE(SUM(total_income), 0),
        COALESCE(SUM(total_expense), 0),
        COALESCE(SUM(profit), 0)
    INTO p1_income, p1_expense, p1_profit
    FROM daily_summary
    WHERE date >= start_date1::DATE AND date <= end_date1::DATE AND user_id = target_user_id;

    -- Period 2
    SELECT 
        COALESCE(SUM(total_income), 0),
        COALESCE(SUM(total_expense), 0),
        COALESCE(SUM(profit), 0)
    INTO p2_income, p2_expense, p2_profit
    FROM daily_summary
    WHERE date >= start_date2::DATE AND date <= end_date2::DATE AND user_id = target_user_id;

    -- Calculate Growth (Percentage)
    IF p1_income > 0 THEN
        inc_growth := ROUND(((p2_income - p1_income) / p1_income * 100), 1);
    ELSE
        IF p2_income > 0 THEN inc_growth := 100; ELSE inc_growth := 0; END IF;
    END IF;

    IF p1_expense > 0 THEN
        exp_growth := ROUND(((p2_expense - p1_expense) / p1_expense * 100), 1);
    ELSE
        IF p2_expense > 0 THEN exp_growth := 100; ELSE exp_growth := 0; END IF;
    END IF;

    IF p1_profit > 0 THEN
        prof_growth := ROUND(((p2_profit - p1_profit) / p1_profit * 100), 1);
    ELSE
        IF p2_profit > 0 THEN prof_growth := 100; ELSE prof_growth := 0; END IF;
    END IF;

    RETURN QUERY SELECT 
        p1_income, p1_expense, p1_profit,
        p2_income, p2_expense, p2_profit,
        inc_growth, exp_growth, prof_growth;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
