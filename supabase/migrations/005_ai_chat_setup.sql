-- AI Chat Feature Setup
-- This migration creates tables and functions for the AI assistant

-- Chat Messages Table
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID DEFAULT NULL, -- NULL for no auth scenario
    message TEXT NOT NULL,
    response TEXT NOT NULL,
    language VARCHAR(5) DEFAULT 'en', -- 'en' or 'ml'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON chat_messages(user_id);

-- Enable Row Level Security
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Allow all operations (no auth requirement)
CREATE POLICY "Enable all operations for chat_messages" ON chat_messages
    FOR ALL USING (true);

-- Helper function to get daily summary for a specific date
CREATE OR REPLACE FUNCTION get_daily_data(target_date DATE)
RETURNS TABLE (
    date TIMESTAMPTZ,
    total_income NUMERIC,
    total_expense NUMERIC,
    profit NUMERIC,
    meals_count INTEGER,
    income_breakdown JSONB,
    expense_breakdown JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ds.date,
        ds.total_income,
        ds.total_expense,
        ds.profit,
        ds.meals_count,
        jsonb_build_object(
            'online', COALESCE(i.online_income, 0),
            'offline', COALESCE(i.offline_income, 0)
        ) as income_breakdown,
        jsonb_build_object(
            'fish', COALESCE(e.fish, 0),
            'meat', COALESCE(e.meat, 0),
            'chicken', COALESCE(e.chicken, 0),
            'milk', COALESCE(e.milk, 0),
            'parotta', COALESCE(e.parotta, 0),
            'pathiri', COALESCE(e.pathiri, 0),
            'dosa', COALESCE(e.dosa, 0),
            'appam', COALESCE(e.appam, 0),
            'coconut', COALESCE(e.coconut, 0),
            'vegetables', COALESCE(e.vegetables, 0),
            'rice', COALESCE(e.rice, 0),
            'labor_manisha', COALESCE(e.labor_manisha, 0),
            'labor_midhun', COALESCE(e.labor_midhun, 0),
            'others', COALESCE(e.others, 0)
        ) as expense_breakdown
    FROM daily_summary ds
    LEFT JOIN income i ON DATE(ds.date) = DATE(i.date)
    LEFT JOIN expense e ON DATE(ds.date) = DATE(e.date)
    WHERE DATE(ds.date) = target_date;
END;
$$ LANGUAGE plpgsql;

-- Function to get range summary
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
    total_meals NUMERIC
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

-- Function to get category total for expense categories
CREATE OR REPLACE FUNCTION get_category_total(
    category_name TEXT,
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    category TEXT,
    total_amount NUMERIC,
    transaction_count INTEGER,
    avg_per_day NUMERIC
) AS $$
DECLARE
    v_total NUMERIC;
    v_count INTEGER;
    v_avg NUMERIC;
BEGIN
    -- Count days in range
    SELECT COUNT(DISTINCT DATE(date)) INTO v_count
    FROM expense
    WHERE DATE(date) >= start_date AND DATE(date) <= end_date;

    -- Calculate based on category
    CASE LOWER(category_name)
        WHEN 'fish' THEN
            SELECT COALESCE(SUM(fish), 0), COUNT(*) FILTER (WHERE fish > 0), COALESCE(AVG(fish), 0)
            INTO v_total, v_count, v_avg FROM expense
            WHERE DATE(date) >= start_date AND DATE(date) <= end_date;
        WHEN 'meat' THEN
            SELECT COALESCE(SUM(meat), 0), COUNT(*) FILTER (WHERE meat > 0), COALESCE(AVG(meat), 0)
            INTO v_total, v_count, v_avg FROM expense
            WHERE DATE(date) >= start_date AND DATE(date) <= end_date;
        WHEN 'chicken' THEN
            SELECT COALESCE(SUM(chicken), 0), COUNT(*) FILTER (WHERE chicken > 0), COALESCE(AVG(chicken), 0)
            INTO v_total, v_count, v_avg FROM expense
            WHERE DATE(date) >= start_date AND DATE(date) <= end_date;
        WHEN 'milk' THEN
            SELECT COALESCE(SUM(milk), 0), COUNT(*) FILTER (WHERE milk > 0), COALESCE(AVG(milk), 0)
            INTO v_total, v_count, v_avg FROM expense
            WHERE DATE(date) >= start_date AND DATE(date) <= end_date;
        WHEN 'parotta' THEN
            SELECT COALESCE(SUM(parotta), 0), COUNT(*) FILTER (WHERE parotta > 0), COALESCE(AVG(parotta), 0)
            INTO v_total, v_count, v_avg FROM expense
            WHERE DATE(date) >= start_date AND DATE(date) <= end_date;
        WHEN 'pathiri' THEN
            SELECT COALESCE(SUM(pathiri), 0), COUNT(*) FILTER (WHERE pathiri > 0), COALESCE(AVG(pathiri), 0)
            INTO v_total, v_count, v_avg FROM expense
            WHERE DATE(date) >= start_date AND DATE(date) <= end_date;
        WHEN 'dosa' THEN
            SELECT COALESCE(SUM(dosa), 0), COUNT(*) FILTER (WHERE dosa > 0), COALESCE(AVG(dosa), 0)
            INTO v_total, v_count, v_avg FROM expense
            WHERE DATE(date) >= start_date AND DATE(date) <= end_date;
        WHEN 'appam' THEN
            SELECT COALESCE(SUM(appam), 0), COUNT(*) FILTER (WHERE appam > 0), COALESCE(AVG(appam), 0)
            INTO v_total, v_count, v_avg FROM expense
            WHERE DATE(date) >= start_date AND DATE(date) <= end_date;
        WHEN 'coconut' THEN
            SELECT COALESCE(SUM(coconut), 0), COUNT(*) FILTER (WHERE coconut > 0), COALESCE(AVG(coconut), 0)
            INTO v_total, v_count, v_avg FROM expense
            WHERE DATE(date) >= start_date AND DATE(date) <= end_date;
        WHEN 'vegetables' THEN
            SELECT COALESCE(SUM(vegetables), 0), COUNT(*) FILTER (WHERE vegetables > 0), COALESCE(AVG(vegetables), 0)
            INTO v_total, v_count, v_avg FROM expense
            WHERE DATE(date) >= start_date AND DATE(date) <= end_date;
        WHEN 'rice' THEN
            SELECT COALESCE(SUM(rice), 0), COUNT(*) FILTER (WHERE rice > 0), COALESCE(AVG(rice), 0)
            INTO v_total, v_count, v_avg FROM expense
            WHERE DATE(date) >= start_date AND DATE(date) <= end_date;
        WHEN 'labor_manisha', 'manisha' THEN
            SELECT COALESCE(SUM(labor_manisha), 0), COUNT(*) FILTER (WHERE labor_manisha > 0), COALESCE(AVG(labor_manisha), 0)
            INTO v_total, v_count, v_avg FROM expense
            WHERE DATE(date) >= start_date AND DATE(date) <= end_date;
        WHEN 'labor_midhun', 'midhun' THEN
            SELECT COALESCE(SUM(labor_midhun), 0), COUNT(*) FILTER (WHERE labor_midhun > 0), COALESCE(AVG(labor_midhun), 0)
            INTO v_total, v_count, v_avg FROM expense
            WHERE DATE(date) >= start_date AND DATE(date) <= end_date;
        WHEN 'others' THEN
            SELECT COALESCE(SUM(others), 0), COUNT(*) FILTER (WHERE others > 0), COALESCE(AVG(others), 0)
            INTO v_total, v_count, v_avg FROM expense
            WHERE DATE(date) >= start_date AND DATE(date) <= end_date;
        ELSE
            v_total := 0;
            v_count := 0;
            v_avg := 0;
    END CASE;

    RETURN QUERY SELECT category_name, v_total, v_count, v_avg;
END;
$$ LANGUAGE plpgsql;

-- Function to get top expense categories in a date range
CREATE OR REPLACE FUNCTION get_top_expense_categories(
    start_date DATE,
    end_date DATE,
    top_n INTEGER DEFAULT 5
)
RETURNS TABLE (
    category TEXT,
    total_amount NUMERIC,
    percentage NUMERIC
) AS $$
DECLARE
    v_total_expense NUMERIC;
BEGIN
    -- Get total expense
    SELECT COALESCE(SUM(total_expense), 0) INTO v_total_expense
    FROM daily_summary
    WHERE DATE(date) >= start_date AND DATE(date) <= end_date;

    RETURN QUERY
    WITH category_totals AS (
        SELECT 
            'Fish' as cat, COALESCE(SUM(fish), 0) as amt FROM expense WHERE DATE(date) >= start_date AND DATE(date) <= end_date
        UNION ALL
        SELECT 'Meat', COALESCE(SUM(meat), 0) FROM expense WHERE DATE(date) >= start_date AND DATE(date) <= end_date
        UNION ALL
        SELECT 'Chicken', COALESCE(SUM(chicken), 0) FROM expense WHERE DATE(date) >= start_date AND DATE(date) <= end_date
        UNION ALL
        SELECT 'Milk', COALESCE(SUM(milk), 0) FROM expense WHERE DATE(date) >= start_date AND DATE(date) <= end_date
        UNION ALL
        SELECT 'Parotta', COALESCE(SUM(parotta), 0) FROM expense WHERE DATE(date) >= start_date AND DATE(date) <= end_date
        UNION ALL
        SELECT 'Pathiri', COALESCE(SUM(pathiri), 0) FROM expense WHERE DATE(date) >= start_date AND DATE(date) <= end_date
        UNION ALL
        SELECT 'Dosa', COALESCE(SUM(dosa), 0) FROM expense WHERE DATE(date) >= start_date AND DATE(date) <= end_date
        UNION ALL
        SELECT 'Appam', COALESCE(SUM(appam), 0) FROM expense WHERE DATE(date) >= start_date AND DATE(date) <= end_date
        UNION ALL
        SELECT 'Coconut', COALESCE(SUM(coconut), 0) FROM expense WHERE DATE(date) >= start_date AND DATE(date) <= end_date
        UNION ALL
        SELECT 'Vegetables', COALESCE(SUM(vegetables), 0) FROM expense WHERE DATE(date) >= start_date AND DATE(date) <= end_date
        UNION ALL
        SELECT 'Rice', COALESCE(SUM(rice), 0) FROM expense WHERE DATE(date) >= start_date AND DATE(date) <= end_date
        UNION ALL
        SELECT 'Labor Manisha', COALESCE(SUM(labor_manisha), 0) FROM expense WHERE DATE(date) >= start_date AND DATE(date) <= end_date
        UNION ALL
        SELECT 'Labor Midhun', COALESCE(SUM(labor_midhun), 0) FROM expense WHERE DATE(date) >= start_date AND DATE(date) <= end_date
        UNION ALL
        SELECT 'Others', COALESCE(SUM(others), 0) FROM expense WHERE DATE(date) >= start_date AND DATE(date) <= end_date
    )
    SELECT 
        ct.cat as category,
        ct.amt as total_amount,
        CASE 
            WHEN v_total_expense > 0 THEN ROUND((ct.amt / v_total_expense * 100)::NUMERIC, 2)
            ELSE 0
        END as percentage
    FROM category_totals ct
    WHERE ct.amt > 0
    ORDER BY ct.amt DESC
    LIMIT top_n;
END;
$$ LANGUAGE plpgsql;

-- Function to get income breakdown for a date range
CREATE OR REPLACE FUNCTION get_income_breakdown(
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    online_total NUMERIC,
    offline_total NUMERIC,
    online_percentage NUMERIC,
    offline_percentage NUMERIC,
    total_income NUMERIC
) AS $$
DECLARE
    v_online NUMERIC;
    v_offline NUMERIC;
    v_total NUMERIC;
BEGIN
    SELECT 
        COALESCE(SUM(online_income), 0),
        COALESCE(SUM(offline_income), 0)
    INTO v_online, v_offline
    FROM income
    WHERE DATE(date) >= start_date AND DATE(date) <= end_date;

    v_total := v_online + v_offline;

    RETURN QUERY SELECT 
        v_online,
        v_offline,
        CASE WHEN v_total > 0 THEN ROUND((v_online / v_total * 100)::NUMERIC, 2) ELSE 0 END,
        CASE WHEN v_total > 0 THEN ROUND((v_offline / v_total * 100)::NUMERIC, 2) ELSE 0 END,
        v_total;
END;
$$ LANGUAGE plpgsql;

-- Function to get recent transactions (most recent days with data)
CREATE OR REPLACE FUNCTION get_recent_transactions(days_limit INTEGER DEFAULT 7)
RETURNS TABLE (
    date TIMESTAMPTZ,
    total_income NUMERIC,
    total_expense NUMERIC,
    profit NUMERIC,
    meals_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ds.date,
        ds.total_income,
        ds.total_expense,
        ds.profit,
        ds.meals_count
    FROM daily_summary ds
    ORDER BY ds.date DESC
    LIMIT days_limit;
END;
$$ LANGUAGE plpgsql;

-- Function to compare two date ranges
CREATE OR REPLACE FUNCTION compare_date_ranges(
    start_date1 DATE,
    end_date1 DATE,
    start_date2 DATE,
    end_date2 DATE
)
RETURNS TABLE (
    period1_income NUMERIC,
    period1_expense NUMERIC,
    period1_profit NUMERIC,
    period2_income NUMERIC,
    period2_expense NUMERIC,
    period2_profit NUMERIC,
    income_change_percent NUMERIC,
    expense_change_percent NUMERIC,
    profit_change_percent NUMERIC
) AS $$
DECLARE
    p1_inc NUMERIC; p1_exp NUMERIC; p1_prof NUMERIC;
    p2_inc NUMERIC; p2_exp NUMERIC; p2_prof NUMERIC;
BEGIN
    -- Period 1
    SELECT COALESCE(SUM(total_income), 0), COALESCE(SUM(total_expense), 0), COALESCE(SUM(profit), 0)
    INTO p1_inc, p1_exp, p1_prof
    FROM daily_summary
    WHERE DATE(date) >= start_date1 AND DATE(date) <= end_date1;

    -- Period 2
    SELECT COALESCE(SUM(total_income), 0), COALESCE(SUM(total_expense), 0), COALESCE(SUM(profit), 0)
    INTO p2_inc, p2_exp, p2_prof
    FROM daily_summary
    WHERE DATE(date) >= start_date2 AND DATE(date) <= end_date2;

    RETURN QUERY SELECT 
        p1_inc, p1_exp, p1_prof,
        p2_inc, p2_exp, p2_prof,
        CASE WHEN p2_inc > 0 THEN ROUND(((p1_inc - p2_inc) / p2_inc * 100)::NUMERIC, 2) ELSE 0 END,
        CASE WHEN p2_exp > 0 THEN ROUND(((p1_exp - p2_exp) / p2_exp * 100)::NUMERIC, 2) ELSE 0 END,
        CASE WHEN p2_prof > 0 THEN ROUND(((p1_prof - p2_prof) / p2_prof * 100)::NUMERIC, 2) ELSE 0 END;
END;
$$ LANGUAGE plpgsql;
