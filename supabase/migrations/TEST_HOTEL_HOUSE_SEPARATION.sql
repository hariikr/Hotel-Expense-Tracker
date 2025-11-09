-- Test queries to verify the hotel/house separation is working correctly

-- ========================================
-- 1. VERIFY MIGRATION APPLIED CORRECTLY
-- ========================================

-- Check that context column exists in all tables
SELECT 
    table_name, 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name IN ('income', 'expense', 'daily_summary') 
  AND column_name = 'context'
ORDER BY table_name;

-- Check the unique constraints are on (date, context)
SELECT 
    conrelid::regclass AS table_name,
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint 
WHERE conrelid IN ('income'::regclass, 'expense'::regclass, 'daily_summary'::regclass)
  AND contype = 'u'
ORDER BY table_name;

-- ========================================
-- 2. INSERT TEST DATA
-- ========================================

-- Insert test expenses for both hotel and house on the same date
INSERT INTO expense (date, context, fish, meat, vegetables) 
VALUES 
    ('2025-11-08', 'hotel', 500, 400, 200),
    ('2025-11-08', 'house', 100, 150, 50)
ON CONFLICT (date, context) DO UPDATE SET
    fish = EXCLUDED.fish,
    meat = EXCLUDED.meat,
    vegetables = EXCLUDED.vegetables;

-- Insert test income for both hotel and house on the same date
INSERT INTO income (date, context, online_income, offline_income, meals_count) 
VALUES 
    ('2025-11-08', 'hotel', 2000, 1500, 45),
    ('2025-11-08', 'house', 500, 300, 0)
ON CONFLICT (date, context) DO UPDATE SET
    online_income = EXCLUDED.online_income,
    offline_income = EXCLUDED.offline_income,
    meals_count = EXCLUDED.meals_count;

-- ========================================
-- 3. VERIFY DATA SEPARATION
-- ========================================

-- Check that we have separate entries for hotel and house
SELECT 
    date,
    context,
    fish,
    meat,
    vegetables,
    fish + meat + vegetables AS total_expense
FROM expense 
WHERE date = '2025-11-08'
ORDER BY context;

SELECT 
    date,
    context,
    online_income,
    offline_income,
    online_income + offline_income AS total_income
FROM income 
WHERE date = '2025-11-08'
ORDER BY context;

-- ========================================
-- 4. VERIFY DAILY SUMMARY CALCULATIONS
-- ========================================

-- Check that daily summaries are calculated separately
SELECT 
    date,
    context,
    total_income,
    total_expense,
    profit,
    meals_count
FROM daily_summary 
WHERE date = '2025-11-08'
ORDER BY context;

-- Expected results:
-- Hotel: profit = (2000 + 1500) - (500 + 400 + 200) = 3500 - 1100 = 2400
-- House: profit = (500 + 300) - (100 + 150 + 50) = 800 - 300 = 500

-- ========================================
-- 5. TEST QUERIES BY CONTEXT
-- ========================================

-- Get all hotel expenses
SELECT 
    date,
    fish,
    meat,
    vegetables,
    fish + meat + vegetables AS total
FROM expense 
WHERE context = 'hotel'
ORDER BY date DESC
LIMIT 10;

-- Get all house expenses
SELECT 
    date,
    fish,
    meat,
    vegetables,
    fish + meat + vegetables AS total
FROM expense 
WHERE context = 'house'
ORDER BY date DESC
LIMIT 10;

-- ========================================
-- 6. MONTHLY SUMMARY BY CONTEXT
-- ========================================

-- Hotel monthly summary
SELECT 
    DATE_TRUNC('month', date) AS month,
    SUM(total_income) AS total_income,
    SUM(total_expense) AS total_expense,
    SUM(profit) AS total_profit
FROM daily_summary 
WHERE context = 'hotel'
  AND date >= DATE_TRUNC('month', CURRENT_DATE)
  AND date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
GROUP BY DATE_TRUNC('month', date);

-- House monthly summary
SELECT 
    DATE_TRUNC('month', date) AS month,
    SUM(total_income) AS total_income,
    SUM(total_expense) AS total_expense,
    SUM(profit) AS total_profit
FROM daily_summary 
WHERE context = 'house'
  AND date >= DATE_TRUNC('month', CURRENT_DATE)
  AND date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
GROUP BY DATE_TRUNC('month', date);

-- ========================================
-- 7. VERIFY NO DATA MIXING
-- ========================================

-- This should return 0 rows (no entries without context)
SELECT COUNT(*) AS entries_without_context
FROM expense 
WHERE context IS NULL;

SELECT COUNT(*) AS entries_without_context
FROM income 
WHERE context IS NULL;

SELECT COUNT(*) AS entries_without_context
FROM daily_summary 
WHERE context IS NULL;

-- ========================================
-- 8. TEST UPDATE OPERATIONS
-- ========================================

-- Update hotel expense (should not affect house)
UPDATE expense 
SET fish = 600 
WHERE date = '2025-11-08' AND context = 'hotel';

-- Verify only hotel was updated
SELECT 
    context,
    fish,
    date
FROM expense 
WHERE date = '2025-11-08'
ORDER BY context;

-- ========================================
-- 9. TEST DELETE OPERATIONS
-- ========================================

-- Delete test data (cleanup)
-- DELETE FROM expense WHERE date = '2025-11-08';
-- DELETE FROM income WHERE date = '2025-11-08';
-- DELETE FROM daily_summary WHERE date = '2025-11-08';

-- ========================================
-- 10. COMPREHENSIVE DATA CHECK
-- ========================================

-- Count entries by context
SELECT 
    'expense' AS table_name,
    context,
    COUNT(*) AS count
FROM expense
GROUP BY context
UNION ALL
SELECT 
    'income' AS table_name,
    context,
    COUNT(*) AS count
FROM income
GROUP BY context
UNION ALL
SELECT 
    'daily_summary' AS table_name,
    context,
    COUNT(*) AS count
FROM daily_summary
GROUP BY context
ORDER BY table_name, context;

-- Check for any date conflicts (should return 0)
SELECT 
    'expense' AS table_name,
    date,
    COUNT(*) AS count
FROM expense
GROUP BY date
HAVING COUNT(*) > 2  -- More than 2 means error (should only be hotel + house)
UNION ALL
SELECT 
    'income' AS table_name,
    date,
    COUNT(*) AS count
FROM income
GROUP BY date
HAVING COUNT(*) > 2
UNION ALL
SELECT 
    'daily_summary' AS table_name,
    date,
    COUNT(*) AS count
FROM daily_summary
GROUP BY date
HAVING COUNT(*) > 2;
