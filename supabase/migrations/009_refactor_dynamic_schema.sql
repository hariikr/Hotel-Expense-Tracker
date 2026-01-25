-- Migration: Refactor to Dynamic Schema (Revised)
-- Description: Unifies Expense/Income schema. Safely handles re-runs.

-- 1. Pre-flight: Handle Legacy Tables
-- Ensure they have user_id before we rename/migrate them
DO $$
BEGIN
    -- Add user_id to 'expense' if it exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'expense') THEN
        ALTER TABLE public.expense ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;

    -- Add user_id to 'income' if it exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'income') THEN
        ALTER TABLE public.income ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 2. Rename Old Tables (Idempotent)
DO $$
BEGIN
    -- Rename 'expense' -> 'expense_old' if 'expense' exists and 'expense_old' does NOT
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'expense') 
       AND NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'expense_old') THEN
        ALTER TABLE public.expense RENAME TO expense_old;
    END IF;

    -- Rename 'income' -> 'income_old'
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'income') 
       AND NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'income_old') THEN
        ALTER TABLE public.income RENAME TO income_old;
    END IF;
END $$;


-- 3. Create Categories Tables
CREATE TABLE IF NOT EXISTS public.expense_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, name)
);

CREATE TABLE IF NOT EXISTS public.income_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, name)
);

-- RLS for Categories
ALTER TABLE expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE income_categories ENABLE ROW LEVEL SECURITY;

-- Policies (Drop first for idempotency)
DROP POLICY IF EXISTS "Users can view own expense categories" ON expense_categories;
DROP POLICY IF EXISTS "Users can insert own expense categories" ON expense_categories;
DROP POLICY IF EXISTS "Users can update own expense categories" ON expense_categories;
DROP POLICY IF EXISTS "Users can delete own expense categories" ON expense_categories;

DROP POLICY IF EXISTS "Users can view own income categories" ON income_categories;
DROP POLICY IF EXISTS "Users can insert own income categories" ON income_categories;
DROP POLICY IF EXISTS "Users can update own income categories" ON income_categories;
DROP POLICY IF EXISTS "Users can delete own income categories" ON income_categories;

CREATE POLICY "Users can view own expense categories" ON expense_categories FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own expense categories" ON expense_categories FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own expense categories" ON expense_categories FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own expense categories" ON expense_categories FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own income categories" ON income_categories FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own income categories" ON income_categories FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own income categories" ON income_categories FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own income categories" ON income_categories FOR DELETE USING (auth.uid() = user_id);


-- 4. Create New Transactions Tables (Final Names: expenses, incomes)
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.expense_categories(id) ON DELETE SET NULL,
    amount NUMERIC NOT NULL CHECK (amount >= 0),
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    description TEXT,
    quantity TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.incomes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.income_categories(id) ON DELETE SET NULL,
    amount NUMERIC NOT NULL CHECK (amount >= 0),
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for Transactions
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE incomes ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Users can view own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can insert own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can update own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can delete own expenses" ON expenses;

DROP POLICY IF EXISTS "Users can view own incomes" ON incomes;
DROP POLICY IF EXISTS "Users can insert own incomes" ON incomes;
DROP POLICY IF EXISTS "Users can update own incomes" ON incomes;
DROP POLICY IF EXISTS "Users can delete own incomes" ON incomes;

CREATE POLICY "Users can view own expenses" ON expenses FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own expenses" ON expenses FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own expenses" ON expenses FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own expenses" ON expenses FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own incomes" ON incomes FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own incomes" ON incomes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own incomes" ON incomes FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own incomes" ON incomes FOR DELETE USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON expenses(user_id, date);
CREATE INDEX IF NOT EXISTS idx_incomes_user_date ON incomes(user_id, date);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_incomes_category ON incomes(category_id);


-- 5. Data Migration
-- Read from expense_old, income_old. Populate expenses, incomes.
DO $$
DECLARE
    r RECORD;
    cat_id UUID;
    curr_user_id UUID;
BEGIN
    -- --- EXPENSE MIGRATION ---
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'expense_old') THEN
        FOR r IN SELECT * FROM public.expense_old LOOP
            curr_user_id := r.user_id;
            
            IF curr_user_id IS NOT NULL THEN
                -- Fish
                IF r.fish > 0 THEN
                    INSERT INTO public.expense_categories (user_id, name) VALUES (curr_user_id, 'Fish') ON CONFLICT (user_id, name) DO NOTHING;
                    SELECT id INTO cat_id FROM public.expense_categories WHERE user_id = curr_user_id AND name = 'Fish';
                    INSERT INTO public.expenses (user_id, category_id, amount, date, description)
                    VALUES (curr_user_id, cat_id, r.fish, r.date, 'Migrated Fish');
                END IF;
                -- Meat
                IF r.meat > 0 THEN
                    INSERT INTO public.expense_categories (user_id, name) VALUES (curr_user_id, 'Meat') ON CONFLICT (user_id, name) DO NOTHING;
                    SELECT id INTO cat_id FROM public.expense_categories WHERE user_id = curr_user_id AND name = 'Meat';
                    INSERT INTO public.expenses (user_id, category_id, amount, date, description)
                    VALUES (curr_user_id, cat_id, r.meat, r.date, 'Migrated Meat');
                END IF;
                -- Chicken
                IF r.chicken > 0 THEN
                    INSERT INTO public.expense_categories (user_id, name) VALUES (curr_user_id, 'Chicken') ON CONFLICT (user_id, name) DO NOTHING;
                    SELECT id INTO cat_id FROM public.expense_categories WHERE user_id = curr_user_id AND name = 'Chicken';
                    INSERT INTO public.expenses (user_id, category_id, amount, date, description)
                    VALUES (curr_user_id, cat_id, r.chicken, r.date, 'Migrated Chicken');
                END IF;
                -- Milk
                IF r.milk > 0 THEN
                    INSERT INTO public.expense_categories (user_id, name) VALUES (curr_user_id, 'Milk') ON CONFLICT (user_id, name) DO NOTHING;
                    SELECT id INTO cat_id FROM public.expense_categories WHERE user_id = curr_user_id AND name = 'Milk';
                    INSERT INTO public.expenses (user_id, category_id, amount, date, description)
                    VALUES (curr_user_id, cat_id, r.milk, r.date, 'Migrated Milk');
                END IF;
                -- Provisions (Grouped)
                -- Actually let's do them individually as per original script for accuracy
                -- Parotta
                IF r.parotta > 0 THEN
                    INSERT INTO public.expense_categories (user_id, name) VALUES (curr_user_id, 'Parotta') ON CONFLICT (user_id, name) DO NOTHING;
                    SELECT id INTO cat_id FROM public.expense_categories WHERE user_id = curr_user_id AND name = 'Parotta';
                    INSERT INTO public.expenses (user_id, category_id, amount, date, description) VALUES (curr_user_id, cat_id, r.parotta, r.date, 'Migrated Parotta');
                END IF;
                IF r.pathiri > 0 THEN
                    INSERT INTO public.expense_categories (user_id, name) VALUES (curr_user_id, 'Pathiri') ON CONFLICT (user_id, name) DO NOTHING;
                    SELECT id INTO cat_id FROM public.expense_categories WHERE user_id = curr_user_id AND name = 'Pathiri';
                    INSERT INTO public.expenses (user_id, category_id, amount, date, description) VALUES (curr_user_id, cat_id, r.pathiri, r.date, 'Migrated Pathiri');
                END IF;
                IF r.dosa > 0 THEN
                    INSERT INTO public.expense_categories (user_id, name) VALUES (curr_user_id, 'Dosa') ON CONFLICT (user_id, name) DO NOTHING;
                    SELECT id INTO cat_id FROM public.expense_categories WHERE user_id = curr_user_id AND name = 'Dosa';
                    INSERT INTO public.expenses (user_id, category_id, amount, date, description) VALUES (curr_user_id, cat_id, r.dosa, r.date, 'Migrated Dosa');
                END IF;
                IF r.appam > 0 THEN
                    INSERT INTO public.expense_categories (user_id, name) VALUES (curr_user_id, 'Appam') ON CONFLICT (user_id, name) DO NOTHING;
                    SELECT id INTO cat_id FROM public.expense_categories WHERE user_id = curr_user_id AND name = 'Appam';
                    INSERT INTO public.expenses (user_id, category_id, amount, date, description) VALUES (curr_user_id, cat_id, r.appam, r.date, 'Migrated Appam');
                END IF;
                IF r.coconut > 0 THEN
                    INSERT INTO public.expense_categories (user_id, name) VALUES (curr_user_id, 'Coconut') ON CONFLICT (user_id, name) DO NOTHING;
                    SELECT id INTO cat_id FROM public.expense_categories WHERE user_id = curr_user_id AND name = 'Coconut';
                    INSERT INTO public.expenses (user_id, category_id, amount, date, description) VALUES (curr_user_id, cat_id, r.coconut, r.date, 'Migrated Coconut');
                END IF;
                IF r.vegetables > 0 THEN
                    INSERT INTO public.expense_categories (user_id, name) VALUES (curr_user_id, 'Vegetables') ON CONFLICT (user_id, name) DO NOTHING;
                    SELECT id INTO cat_id FROM public.expense_categories WHERE user_id = curr_user_id AND name = 'Vegetables';
                    INSERT INTO public.expenses (user_id, category_id, amount, date, description) VALUES (curr_user_id, cat_id, r.vegetables, r.date, 'Migrated Vegetables');
                END IF;
                IF r.rice > 0 THEN
                    INSERT INTO public.expense_categories (user_id, name) VALUES (curr_user_id, 'Rice') ON CONFLICT (user_id, name) DO NOTHING;
                    SELECT id INTO cat_id FROM public.expense_categories WHERE user_id = curr_user_id AND name = 'Rice';
                    INSERT INTO public.expenses (user_id, category_id, amount, date, description) VALUES (curr_user_id, cat_id, r.rice, r.date, 'Migrated Rice');
                END IF;
                 -- Labor
                IF r.labor_manisha > 0 THEN
                    INSERT INTO public.expense_categories (user_id, name) VALUES (curr_user_id, 'Labor (Manisha)') ON CONFLICT (user_id, name) DO NOTHING;
                    SELECT id INTO cat_id FROM public.expense_categories WHERE user_id = curr_user_id AND name = 'Labor (Manisha)';
                    INSERT INTO public.expenses (user_id, category_id, amount, date, description) VALUES (curr_user_id, cat_id, r.labor_manisha, r.date, 'Migrated Labor');
                END IF;
                IF r.labor_midhun > 0 THEN
                    INSERT INTO public.expense_categories (user_id, name) VALUES (curr_user_id, 'Labor (Midhun)') ON CONFLICT (user_id, name) DO NOTHING;
                    SELECT id INTO cat_id FROM public.expense_categories WHERE user_id = curr_user_id AND name = 'Labor (Midhun)';
                    INSERT INTO public.expenses (user_id, category_id, amount, date, description) VALUES (curr_user_id, cat_id, r.labor_midhun, r.date, 'Migrated Labor');
                END IF;
                -- Others
                IF r.others > 0 THEN
                     INSERT INTO public.expense_categories (user_id, name) VALUES (curr_user_id, 'Others') ON CONFLICT (user_id, name) DO NOTHING;
                    SELECT id INTO cat_id FROM public.expense_categories WHERE user_id = curr_user_id AND name = 'Others';
                    INSERT INTO public.expenses (user_id, category_id, amount, date, description) VALUES (curr_user_id, cat_id, r.others, r.date, 'Migrated Others');
                END IF;

            END IF;
        END LOOP;
    END IF;

    -- --- INCOME MIGRATION ---
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'income_old') THEN
        FOR r IN SELECT * FROM public.income_old LOOP
            curr_user_id := r.user_id;
            
            IF curr_user_id IS NOT NULL THEN
                 -- Online
                IF r.online_income > 0 THEN
                    INSERT INTO public.income_categories (user_id, name) VALUES (curr_user_id, 'Online') ON CONFLICT (user_id, name) DO NOTHING;
                    SELECT id INTO cat_id FROM public.income_categories WHERE user_id = curr_user_id AND name = 'Online';
                    INSERT INTO public.incomes (user_id, category_id, amount, date, description) VALUES (curr_user_id, cat_id, r.online_income, r.date, 'Migrated Online Income');
                END IF;
                 -- Offline
                IF r.offline_income > 0 THEN
                    INSERT INTO public.income_categories (user_id, name) VALUES (curr_user_id, 'Offline') ON CONFLICT (user_id, name) DO NOTHING;
                    SELECT id INTO cat_id FROM public.income_categories WHERE user_id = curr_user_id AND name = 'Offline';
                    INSERT INTO public.incomes (user_id, category_id, amount, date, description) VALUES (curr_user_id, cat_id, r.offline_income, r.date, 'Migrated Offline Income');
                END IF;
            END IF;
        END LOOP;
    END IF;
END $$;


-- 6. Update Functions (Simplified)

-- Force drop all possible old signatures to avoid "function is not unique" errors
DROP FUNCTION IF EXISTS get_daily_data(DATE);
DROP FUNCTION IF EXISTS get_daily_data(DATE, UUID);

DROP FUNCTION IF EXISTS get_category_total(TEXT, DATE, DATE);
DROP FUNCTION IF EXISTS get_category_total(TEXT, TEXT, TEXT, UUID);
DROP FUNCTION IF EXISTS get_category_total(TEXT, DATE, DATE, UUID, BOOLEAN);

DROP FUNCTION IF EXISTS get_top_expense_categories(DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS get_top_expense_categories(TEXT, TEXT, UUID, INTEGER);

DROP FUNCTION IF EXISTS get_range_data(DATE, DATE);
DROP FUNCTION IF EXISTS get_range_data(TEXT, TEXT, UUID);

DROP FUNCTION IF EXISTS get_income_breakdown(DATE, DATE);
DROP FUNCTION IF EXISTS get_income_breakdown(TEXT, TEXT, UUID);

DROP FUNCTION IF EXISTS get_recent_transactions(INTEGER);
DROP FUNCTION IF EXISTS get_recent_transactions(INTEGER, UUID);


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
DECLARE
    d_total_income NUMERIC;
    d_total_expense NUMERIC;
    d_profit NUMERIC;
    d_meals_count INTEGER;
BEGIN
    SELECT COALESCE(SUM(amount), 0) INTO d_total_income FROM incomes WHERE date = target_date AND user_id = target_user_id;
    SELECT COALESCE(SUM(amount), 0) INTO d_total_expense FROM expenses WHERE date = target_date AND user_id = target_user_id;
    d_profit := d_total_income - d_total_expense;
    
    -- Try to fetch meals_count from daily_summary if exists
    d_meals_count := 0;
    BEGIN
        SELECT meals_count INTO d_meals_count FROM daily_summary WHERE date = target_date AND user_id = target_user_id;
    EXCEPTION WHEN OTHERS THEN
        d_meals_count := 0;
    END;
    
    RETURN QUERY
    SELECT 
        target_date::TIMESTAMPTZ,
        d_total_income,
        d_total_expense,
        d_profit,
        COALESCE(d_meals_count, 0),
        CASE WHEN d_total_income > 0 THEN ROUND((d_profit / d_total_income * 100), 2) ELSE 0 END,
        (SELECT jsonb_object_agg(c.name, COALESCE(sum_amount, 0)) FROM income_categories c LEFT JOIN (SELECT category_id, SUM(amount) as sum_amount FROM incomes WHERE date = target_date AND user_id = target_user_id GROUP BY category_id) i ON c.id = i.category_id WHERE c.user_id = target_user_id),
        (SELECT jsonb_object_agg(c.name, COALESCE(sum_amount, 0)) FROM expense_categories c LEFT JOIN (SELECT category_id, SUM(amount) as sum_amount FROM expenses WHERE date = target_date AND user_id = target_user_id GROUP BY category_id) e ON c.id = e.category_id WHERE c.user_id = target_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE OR REPLACE FUNCTION get_category_total(category_name TEXT, start_date DATE, end_date DATE, target_user_id UUID, is_expense BOOLEAN DEFAULT true)
RETURNS NUMERIC AS $$
DECLARE
    total NUMERIC;
BEGIN
    IF is_expense THEN
        SELECT COALESCE(SUM(e.amount), 0) INTO total
        FROM expenses e
        JOIN expense_categories c ON e.category_id = c.id
        WHERE c.name = category_name AND e.date >= start_date AND e.date <= end_date AND e.user_id = target_user_id;
    ELSE
         SELECT COALESCE(SUM(i.amount), 0) INTO total
        FROM incomes i
        JOIN income_categories c ON i.category_id = c.id
        WHERE c.name = category_name AND i.date >= start_date AND i.date <= end_date AND i.user_id = target_user_id;
    END IF;
    RETURN total;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE OR REPLACE FUNCTION get_top_expense_categories(start_date TEXT, end_date TEXT, target_user_id UUID, top_n INTEGER DEFAULT 5)
RETURNS TABLE (category TEXT, total_amount NUMERIC, percentage NUMERIC) AS $$
DECLARE
    total_exp NUMERIC;
BEGIN
    SELECT COALESCE(SUM(amount), 0) INTO total_exp FROM expenses WHERE date >= start_date::DATE AND date <= end_date::DATE AND user_id = target_user_id;
    IF total_exp = 0 THEN RETURN; END IF;

    RETURN QUERY
    SELECT 
        c.name as category,
        SUM(e.amount) as total_amount,
        ROUND((SUM(e.amount) / total_exp * 100), 1) as percentage
    FROM expenses e
    JOIN expense_categories c ON e.category_id = c.id
    WHERE e.date >= start_date::DATE AND e.date <= end_date::DATE AND e.user_id = target_user_id
    GROUP BY c.name
    ORDER BY total_amount DESC
    LIMIT top_n;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
