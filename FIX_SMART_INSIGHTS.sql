-- Fix for Smart Insights - Corrects get_range_data function type mismatch
-- Run this in Supabase SQL Editor
-- This only updates the function, doesn't touch policies or tables

DROP FUNCTION IF EXISTS get_range_data(DATE, DATE);

CREATE OR REPLACE FUNCTION get_range_data(start_date DATE, end_date DATE)
RETURNS TABLE (
    total_income NUMERIC,
    total_expense NUMERIC,
    profit NUMERIC,
    profit_margin NUMERIC,
    avg_daily_income NUMERIC,
    avg_daily_expense NUMERIC,
    avg_daily_profit NUMERIC,
    total_days INTEGER,
    profitable_days BIGINT,
    loss_days BIGINT,
    total_meals BIGINT
) AS $$
DECLARE
    v_days_count INTEGER;
    v_total_income NUMERIC;
    v_total_expense NUMERIC;
    v_profit NUMERIC;
    v_profit_margin NUMERIC;
BEGIN
    SELECT COUNT(DISTINCT DATE(date)) INTO v_days_count
    FROM daily_summary
    WHERE DATE(date) >= start_date AND DATE(date) <= end_date;

    SELECT 
        COALESCE(SUM(ds.total_income), 0),
        COALESCE(SUM(ds.total_expense), 0),
        COALESCE(SUM(ds.profit), 0)
    INTO v_total_income, v_total_expense, v_profit
    FROM daily_summary ds
    WHERE DATE(ds.date) >= start_date AND DATE(ds.date) <= end_date;

    -- Calculate profit margin
    IF v_total_income > 0 THEN
        v_profit_margin := (v_profit / v_total_income) * 100;
    ELSE
        v_profit_margin := 0;
    END IF;

    RETURN QUERY
    SELECT 
        v_total_income as total_income,
        v_total_expense as total_expense,
        v_profit as profit,
        v_profit_margin as profit_margin,
        COALESCE(AVG(ds.total_income), 0) as avg_daily_income,
        COALESCE(AVG(ds.total_expense), 0) as avg_daily_expense,
        COALESCE(AVG(ds.profit), 0) as avg_daily_profit,
        v_days_count as total_days,
        COUNT(*) FILTER (WHERE ds.profit > 0) as profitable_days,
        COUNT(*) FILTER (WHERE ds.profit < 0) as loss_days,
        COALESCE(SUM(ds.meals_count), 0) as total_meals
    FROM daily_summary ds
    WHERE DATE(ds.date) >= start_date AND DATE(ds.date) <= end_date;
END;
$$ LANGUAGE plpgsql;

-- Test the function (should return data if you have entries in the last 7 days)
SELECT * FROM get_range_data((CURRENT_DATE - INTERVAL '7 days')::DATE, CURRENT_DATE);

