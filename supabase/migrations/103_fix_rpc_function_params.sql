-- Fix RPC function parameter names to match edge function calls
-- Updates parameter names from target_user_id to p_user_id format

-- Drop old functions
DROP FUNCTION IF EXISTS get_expense_summary_by_category(UUID, DATE, DATE);
DROP FUNCTION IF EXISTS get_income_summary_by_category(UUID, DATE, DATE);
DROP FUNCTION IF EXISTS get_daily_trend(UUID, INTEGER);
DROP FUNCTION IF EXISTS get_month_summary(UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_top_spending_days(UUID, INTEGER);
DROP FUNCTION IF EXISTS get_savings_rate(UUID, DATE, DATE);

-- Function: Get expense summary by category
CREATE OR REPLACE FUNCTION get_expense_summary_by_category(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    category_name TEXT,
    total_amount NUMERIC,
    transaction_count BIGINT,
    percentage NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH category_totals AS (
        SELECT 
            ec.name,
            SUM(e.amount) as total,
            COUNT(e.id) as count
        FROM expenses e
        INNER JOIN expense_categories ec ON e.category_id = ec.id
        WHERE e.user_id = p_user_id
        AND e.date BETWEEN p_start_date AND p_end_date
        GROUP BY ec.name
    ),
    grand_total AS (
        SELECT SUM(total) as sum FROM category_totals
    )
    SELECT 
        ct.name,
        ct.total,
        ct.count,
        CASE 
            WHEN gt.sum > 0 THEN ROUND((ct.total / gt.sum * 100)::NUMERIC, 2)
            ELSE 0
        END as percentage
    FROM category_totals ct, grand_total gt
    ORDER BY ct.total DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get income summary by category
CREATE OR REPLACE FUNCTION get_income_summary_by_category(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    category_name TEXT,
    total_amount NUMERIC,
    transaction_count BIGINT,
    percentage NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH category_totals AS (
        SELECT 
            ic.name,
            SUM(i.amount) as total,
            COUNT(i.id) as count
        FROM incomes i
        INNER JOIN income_categories ic ON i.category_id = ic.id
        WHERE i.user_id = p_user_id
        AND i.date BETWEEN p_start_date AND p_end_date
        GROUP BY ic.name
    ),
    grand_total AS (
        SELECT SUM(total) as sum FROM category_totals
    )
    SELECT 
        ct.name,
        ct.total,
        ct.count,
        CASE 
            WHEN gt.sum > 0 THEN ROUND((ct.total / gt.sum * 100)::NUMERIC, 2)
            ELSE 0
        END as percentage
    FROM category_totals ct, grand_total gt
    ORDER BY ct.total DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get daily trend (last N days)
CREATE OR REPLACE FUNCTION get_daily_trend(
    p_user_id UUID,
    p_days_count INTEGER DEFAULT 7
)
RETURNS TABLE (
    date DATE,
    total_income NUMERIC,
    total_expense NUMERIC,
    profit NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH date_series AS (
        SELECT 
            CURRENT_DATE - (p_days_count - 1) + generate_series(0, p_days_count - 1) as day
    ),
    daily_incomes AS (
        SELECT 
            i.date,
            SUM(i.amount) as income
        FROM incomes i
        WHERE i.user_id = p_user_id
        AND i.date >= CURRENT_DATE - p_days_count
        GROUP BY i.date
    ),
    daily_expenses AS (
        SELECT 
            e.date,
            SUM(e.amount) as expense
        FROM expenses e
        WHERE e.user_id = p_user_id
        AND e.date >= CURRENT_DATE - p_days_count
        GROUP BY e.date
    )
    SELECT 
        ds.day::DATE,
        COALESCE(di.income, 0) as total_income,
        COALESCE(de.expense, 0) as total_expense,
        COALESCE(di.income, 0) - COALESCE(de.expense, 0) as profit
    FROM date_series ds
    LEFT JOIN daily_incomes di ON ds.day = di.date
    LEFT JOIN daily_expenses de ON ds.day = de.date
    ORDER BY ds.day DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get month summary
CREATE OR REPLACE FUNCTION get_month_summary(
    p_user_id UUID,
    p_year INTEGER,
    p_month INTEGER
)
RETURNS TABLE (
    total_income NUMERIC,
    total_expense NUMERIC,
    profit NUMERIC,
    profit_margin NUMERIC,
    avg_daily_income NUMERIC,
    avg_daily_expense NUMERIC,
    transaction_count BIGINT
) AS $$
DECLARE
    v_total_income NUMERIC := 0;
    v_total_expense NUMERIC := 0;
    v_profit NUMERIC := 0;
    v_days INTEGER;
    v_transaction_count BIGINT := 0;
BEGIN
    -- Get number of days in month
    v_days := DATE_PART('days', 
        DATE_TRUNC('month', MAKE_DATE(p_year, p_month, 1)) 
        + INTERVAL '1 month - 1 day'
    );

    -- Get total income
    SELECT COALESCE(SUM(amount), 0) INTO v_total_income
    FROM incomes
    WHERE user_id = p_user_id
    AND EXTRACT(YEAR FROM date) = p_year
    AND EXTRACT(MONTH FROM date) = p_month;

    -- Get total expense
    SELECT COALESCE(SUM(amount), 0) INTO v_total_expense
    FROM expenses
    WHERE user_id = p_user_id
    AND EXTRACT(YEAR FROM date) = p_year
    AND EXTRACT(MONTH FROM date) = p_month;

    -- Get transaction count
    SELECT COUNT(*) INTO v_transaction_count
    FROM (
        SELECT id FROM incomes WHERE user_id = p_user_id 
        AND EXTRACT(YEAR FROM date) = p_year AND EXTRACT(MONTH FROM date) = p_month
        UNION ALL
        SELECT id FROM expenses WHERE user_id = p_user_id
        AND EXTRACT(YEAR FROM date) = p_year AND EXTRACT(MONTH FROM date) = p_month
    ) as all_transactions;

    v_profit := v_total_income - v_total_expense;

    RETURN QUERY SELECT
        v_total_income,
        v_total_expense,
        v_profit,
        CASE WHEN v_total_income > 0 THEN ROUND((v_profit / v_total_income * 100)::NUMERIC, 2) ELSE 0 END,
        ROUND((v_total_income / v_days)::NUMERIC, 2),
        ROUND((v_total_expense / v_days)::NUMERIC, 2),
        v_transaction_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get top spending days
CREATE OR REPLACE FUNCTION get_top_spending_days(
    p_user_id UUID,
    p_days_limit INTEGER DEFAULT 5
)
RETURNS TABLE (
    date DATE,
    total_expense NUMERIC,
    top_category TEXT,
    top_category_amount NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH daily_expenses AS (
        SELECT 
            e.date,
            SUM(e.amount) as total
        FROM expenses e
        WHERE e.user_id = p_user_id
        GROUP BY e.date
        ORDER BY total DESC
        LIMIT p_days_limit
    ),
    top_categories AS (
        SELECT DISTINCT ON (e.date)
            e.date,
            ec.name as category,
            SUM(e.amount) as amount
        FROM expenses e
        INNER JOIN expense_categories ec ON e.category_id = ec.id
        WHERE e.user_id = p_user_id
        AND e.date IN (SELECT de.date FROM daily_expenses de)
        GROUP BY e.date, ec.name
        ORDER BY e.date, amount DESC
    )
    SELECT 
        de.date,
        de.total,
        tc.category,
        tc.amount
    FROM daily_expenses de
    LEFT JOIN top_categories tc ON de.date = tc.date
    ORDER BY de.total DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get savings rate
CREATE OR REPLACE FUNCTION get_savings_rate(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    total_income NUMERIC,
    total_expense NUMERIC,
    total_savings NUMERIC,
    savings_rate NUMERIC,
    daily_avg_savings NUMERIC
) AS $$
DECLARE
    v_income NUMERIC := 0;
    v_expense NUMERIC := 0;
    v_savings NUMERIC := 0;
    v_days INTEGER;
BEGIN
    -- Calculate days
    v_days := p_end_date - p_start_date + 1;

    -- Get totals
    SELECT COALESCE(SUM(amount), 0) INTO v_income
    FROM incomes WHERE user_id = p_user_id AND date BETWEEN p_start_date AND p_end_date;

    SELECT COALESCE(SUM(amount), 0) INTO v_expense
    FROM expenses WHERE user_id = p_user_id AND date BETWEEN p_start_date AND p_end_date;

    v_savings := v_income - v_expense;

    RETURN QUERY SELECT
        v_income,
        v_expense,
        v_savings,
        CASE WHEN v_income > 0 THEN ROUND((v_savings / v_income * 100)::NUMERIC, 2) ELSE 0 END,
        CASE WHEN v_days > 0 THEN ROUND((v_savings / v_days)::NUMERIC, 2) ELSE 0 END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_expense_summary_by_category TO authenticated;
GRANT EXECUTE ON FUNCTION get_income_summary_by_category TO authenticated;
GRANT EXECUTE ON FUNCTION get_daily_trend TO authenticated;
GRANT EXECUTE ON FUNCTION get_month_summary TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_spending_days TO authenticated;
GRANT EXECUTE ON FUNCTION get_savings_rate TO authenticated;
