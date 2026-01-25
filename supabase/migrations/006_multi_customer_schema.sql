-- Migration: Multi-Customer Support & Security
-- Description: Adds profiles table, user_id columns, RLS policies, and updates functions

-- 1. Create Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    phone TEXT,
    avatar_url TEXT,
    preferred_language TEXT DEFAULT 'ml', -- Malayalam is default
    business_name TEXT,
    business_type TEXT DEFAULT 'hotel',
    timezone TEXT DEFAULT 'Asia/Kolkata',
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policies for profiles
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 2. Modify Income Table
ALTER TABLE income 
    ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_income_user_id ON income(user_id);

-- Update unique constraint to include user_id
ALTER TABLE income DROP CONSTRAINT IF EXISTS income_date_key; -- specific name might vary, dropping old constraint
ALTER TABLE income DROP CONSTRAINT IF EXISTS income_date_context_key;
-- Safe approach: try to drop likely constraint names or just add the new one.
-- Ideally we should know the exact constraint name. Assuming 'income_date_context_key' or similar.
-- Let's just add the new constraint. If user_id is null for existing rows, this might fail unless we populate it.
-- STRATEGY: We will allow NULL user_id initially for migration, then enforce NOT NULL later if needed.
-- But for the unique constraint, NULLs technically don't conflict in standard SQL, but for SaaS we want uniqueness.
-- We will handle existing data migration in a separate script/step or allow NULLs for now.
-- For now, let's ADD the constraint. 
-- NOTE: If multiple rows exist with same date/context and NULL user_id, this might be fine as NULL != NULL in unique index (usually).

ALTER TABLE income ADD CONSTRAINT income_user_date_context_key 
    UNIQUE (user_id, date, context);

-- RLS for Income
ALTER TABLE income ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON income;
DROP POLICY IF EXISTS "Enable read access for all" ON income;
DROP POLICY IF EXISTS "Enable insert for all" ON income;
DROP POLICY IF EXISTS "Enable update for all" ON income;
DROP POLICY IF EXISTS "Enable delete for all" ON income;

CREATE POLICY "Users can view own income" ON income
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own income" ON income
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own income" ON income
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own income" ON income
    FOR DELETE USING (auth.uid() = user_id);

-- 3. Modify Expense Table
ALTER TABLE expense 
    ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_expense_user_id ON expense(user_id);

ALTER TABLE expense DROP CONSTRAINT IF EXISTS expense_date_key;
ALTER TABLE expense DROP CONSTRAINT IF EXISTS expense_date_context_key;
ALTER TABLE expense ADD CONSTRAINT expense_user_date_context_key 
    UNIQUE (user_id, date, context);

-- RLS for Expense
ALTER TABLE expense ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON expense;
DROP POLICY IF EXISTS "Enable read access for all" ON expense;
DROP POLICY IF EXISTS "Enable insert for all" ON expense;
DROP POLICY IF EXISTS "Enable update for all" ON expense;
DROP POLICY IF EXISTS "Enable delete for all" ON expense;

CREATE POLICY "Users can view own expense" ON expense
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own expense" ON expense
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own expense" ON expense
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own expense" ON expense
    FOR DELETE USING (auth.uid() = user_id);

-- 4. Modify Daily Summary Table
ALTER TABLE daily_summary 
    ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_daily_summary_user_id ON daily_summary(user_id);

ALTER TABLE daily_summary DROP CONSTRAINT IF EXISTS daily_summary_date_key;
ALTER TABLE daily_summary ADD CONSTRAINT daily_summary_user_date_key 
    UNIQUE (user_id, date);

-- RLS for Daily Summary
ALTER TABLE daily_summary ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON daily_summary;

CREATE POLICY "Users can view own summary" ON daily_summary
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own summary" ON daily_summary
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own summary" ON daily_summary
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own summary" ON daily_summary
    FOR DELETE USING (auth.uid() = user_id);

-- 5. Modify Chat Messages Table
-- We allow NULL initially, but eventually should be NOT NULL.
-- Existing messages might be orphaned if we don't migrate them.
ALTER TABLE chat_messages 
    ADD CONSTRAINT chat_messages_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- RLS for Chat
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable all operations for chat_messages" ON chat_messages;

CREATE POLICY "Users can view own chat" ON chat_messages
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own chat" ON chat_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own chat" ON chat_messages
    FOR DELETE USING (auth.uid() = user_id);


-- 6. Update Database Functions to support user_id
-- We need to drop existing functions and recreate them with user_id parameter OR overload them.
-- Better to replace them to enforce user_id usage.

-- FUNCTION: get_daily_data
DROP FUNCTION IF EXISTS get_daily_data(date);
CREATE OR REPLACE FUNCTION get_daily_data(target_date DATE, target_user_id UUID)
RETURNS TABLE (
    date TIMESTAMPTZ,
    total_income NUMERIC,
    total_expense NUMERIC,
    profit NUMERIC,
    meals_count INTEGER,
    profit_margin NUMERIC,
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
        CASE 
            WHEN ds.total_income > 0 THEN ROUND((ds.profit / ds.total_income * 100), 2)
            ELSE 0 
        END as profit_margin,
        jsonb_build_object(
            'online', COALESCE(i.online_income, 0),
            'offline', COALESCE(i.offline_income, 0)
        ) as income_breakdown,
        jsonb_build_object(
            'fish', COALESCE(e.fish, 0),
            'meat', COALESCE(e.meat, 0),
            'chicken', COALESCE(e.chicken, 0),
            'milk', COALESCE(e.milk, 0),
            'provisions', COALESCE(e.parotta + e.pathiri + e.dosa + e.appam + e.rice + e.coconut + e.vegetables + e.others, 0),
            'labor', COALESCE(e.labor_manisha + e.labor_midhun, 0)
        ) as expense_breakdown
    FROM daily_summary ds
    LEFT JOIN income i ON DATE(ds.date) = DATE(i.date) AND i.user_id = target_user_id
    LEFT JOIN expense e ON DATE(ds.date) = DATE(e.date) AND e.user_id = target_user_id
    WHERE DATE(ds.date) = target_date AND ds.user_id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- FUNCTION: get_range_data
DROP FUNCTION IF EXISTS get_range_data(text, text);
CREATE OR REPLACE FUNCTION get_range_data(start_date TEXT, end_date TEXT, target_user_id UUID)
RETURNS TABLE (
    total_income NUMERIC,
    total_expense NUMERIC,
    profit NUMERIC,
    profit_margin NUMERIC,
    avg_daily_income NUMERIC,
    profitable_days INTEGER,
    total_days INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH range_stats AS (
        SELECT 
            COALESCE(SUM(ds.total_income), 0) as t_income,
            COALESCE(SUM(ds.total_expense), 0) as t_expense,
            COALESCE(SUM(ds.profit), 0) as t_profit,
            COUNT(*) as t_days,
            COUNT(CASE WHEN ds.profit > 0 THEN 1 END) as p_days
        FROM daily_summary ds
        WHERE ds.date >= start_date::DATE 
        AND ds.date <= end_date::DATE
        AND ds.user_id = target_user_id
    )
    SELECT 
        t_income as total_income,
        t_expense as total_expense,
        t_profit as profit,
        CASE 
            WHEN t_income > 0 THEN ROUND((t_profit / t_income * 100), 2)
            ELSE 0 
        END as profit_margin,
        CASE 
            WHEN t_days > 0 THEN ROUND((t_income / t_days), 2)
            ELSE 0 
        END as avg_daily_income,
        p_days::INTEGER as profitable_days,
        t_days::INTEGER as total_days
    FROM range_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- FUNCTION: get_top_expense_categories
DROP FUNCTION IF EXISTS get_top_expense_categories(text, text, integer);
CREATE OR REPLACE FUNCTION get_top_expense_categories(start_date TEXT, end_date TEXT, target_user_id UUID, top_n INTEGER DEFAULT 5)
RETURNS TABLE (
    category TEXT,
    total_amount NUMERIC,
    percentage NUMERIC
) AS $$
DECLARE
    total_exp NUMERIC;
BEGIN
    -- Get total expense for period
    SELECT COALESCE(SUM(total_expense), 0) INTO total_exp
    FROM daily_summary
    WHERE date >= start_date::DATE AND date <= end_date::DATE AND user_id = target_user_id;

    IF total_exp = 0 THEN
        RETURN;
    END IF;

    RETURN QUERY
    WITH category_sums AS (
        SELECT 
            SUM(fish) as fish, SUM(meat) as meat, SUM(chicken) as chicken, 
            SUM(milk) as milk, SUM(parotta) as parotta, SUM(pathiri) as pathiri, 
            SUM(dosa) as dosa, SUM(appam) as appam, SUM(coconut) as coconut, 
            SUM(vegetables) as vegetables, SUM(rice) as rice, 
            SUM(labor_manisha) as labor_manisha, SUM(labor_midhun) as labor_midhun, 
            SUM(others) as others
        FROM expense
        WHERE date >= start_date::DATE AND date <= end_date::DATE AND user_id = target_user_id
    )
    SELECT * FROM (
        SELECT 'fish' as category, fish as total_amount, ROUND((fish/total_exp*100), 1) as percentage FROM category_sums
        UNION ALL SELECT 'meat', meat, ROUND((meat/total_exp*100), 1) FROM category_sums
        UNION ALL SELECT 'chicken', chicken, ROUND((chicken/total_exp*100), 1) FROM category_sums
        UNION ALL SELECT 'milk', milk, ROUND((milk/total_exp*100), 1) FROM category_sums
        UNION ALL SELECT 'parotta', parotta, ROUND((parotta/total_exp*100), 1) FROM category_sums
        UNION ALL SELECT 'pathiri', pathiri, ROUND((pathiri/total_exp*100), 1) FROM category_sums
        UNION ALL SELECT 'dosa', dosa, ROUND((dosa/total_exp*100), 1) FROM category_sums
        UNION ALL SELECT 'appam', appam, ROUND((appam/total_exp*100), 1) FROM category_sums
        UNION ALL SELECT 'coconut', coconut, ROUND((coconut/total_exp*100), 1) FROM category_sums
        UNION ALL SELECT 'vegetables', vegetables, ROUND((vegetables/total_exp*100), 1) FROM category_sums
        UNION ALL SELECT 'rice', rice, ROUND((rice/total_exp*100), 1) FROM category_sums
        UNION ALL SELECT 'labor_manisha', labor_manisha, ROUND((labor_manisha/total_exp*100), 1) FROM category_sums
        UNION ALL SELECT 'labor_midhun', labor_midhun, ROUND((labor_midhun/total_exp*100), 1) FROM category_sums
        UNION ALL SELECT 'others', others, ROUND((others/total_exp*100), 1) FROM category_sums
    ) as results
    WHERE total_amount > 0
    ORDER BY total_amount DESC
    LIMIT top_n;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- FUNCTION: get_income_breakdown
DROP FUNCTION IF EXISTS get_income_breakdown(text, text);
CREATE OR REPLACE FUNCTION get_income_breakdown(start_date TEXT, end_date TEXT, target_user_id UUID)
RETURNS TABLE (
    online_income NUMERIC,
    online_percentage NUMERIC,
    offline_income NUMERIC,
    offline_percentage NUMERIC,
    total_income NUMERIC
) AS $$
DECLARE
    t_income NUMERIC;
    t_online NUMERIC;
    t_offline NUMERIC;
BEGIN
    SELECT 
        COALESCE(SUM(online_income), 0),
        COALESCE(SUM(offline_income), 0),
        COALESCE(SUM(online_income + offline_income), 0)
    INTO t_online, t_offline, t_income
    FROM income
    WHERE date >= start_date::DATE AND date <= end_date::DATE AND user_id = target_user_id;

    IF t_income = 0 THEN
        RETURN QUERY SELECT 0::NUMERIC, 0::NUMERIC, 0::NUMERIC, 0::NUMERIC, 0::NUMERIC;
    ELSE
        RETURN QUERY SELECT 
            t_online, 
            ROUND((t_online/t_income*100), 1),
            t_offline,
            ROUND((t_offline/t_income*100), 1),
            t_income;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- FUNCTION: get_recent_transactions
DROP FUNCTION IF EXISTS get_recent_transactions(integer);
CREATE OR REPLACE FUNCTION get_recent_transactions(days_limit INTEGER, target_user_id UUID)
RETURNS TABLE (
    date TEXT,
    total_income NUMERIC,
    total_expense NUMERIC,
    profit NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        to_char(ds.date, 'YYYY-MM-DD'),
        ds.total_income,
        ds.total_expense,
        ds.profit
    FROM daily_summary ds
    WHERE ds.user_id = target_user_id
    ORDER BY ds.date DESC
    LIMIT days_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile after signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, business_name)
  VALUES (
    new.id, 
    new.email, 
    new.raw_user_meta_data->>'full_name', 
    new.raw_user_meta_data->>'business_name'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

