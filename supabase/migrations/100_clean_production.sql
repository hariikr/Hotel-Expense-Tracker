-- CLEAN PRODUCTION SCHEMA
-- Removes old tables and ensures new schema is ready
-- Run this in Supabase SQL Editor

-- Drop old tables and dependencies
DROP FUNCTION IF EXISTS calculate_total_expense(expense_old) CASCADE;
DROP FUNCTION IF EXISTS calculate_total_income(income_old) CASCADE;
DROP TABLE IF EXISTS expense_old CASCADE;
DROP TABLE IF EXISTS income_old CASCADE;

-- Ensure new tables have correct structure
-- expenses table (already exists)
-- incomes table (create if not exists)
CREATE TABLE IF NOT EXISTS incomes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES income_categories(id) ON DELETE RESTRICT,
    amount DECIMAL(12, 2) NOT NULL CHECK (amount >= 0),
    date DATE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT incomes_user_date_unique UNIQUE (user_id, date, category_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_incomes_user_date ON incomes(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_incomes_category ON incomes(category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_user_date_v2 ON expenses(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_category_v2 ON expenses(category_id);

-- Enable RLS
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE incomes ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE income_categories ENABLE ROW LEVEL SECURITY;

-- Drop old policies if they exist
DROP POLICY IF EXISTS "Users can view own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can insert own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can update own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can delete own expenses" ON expenses;

DROP POLICY IF EXISTS "Users can view own incomes" ON incomes;
DROP POLICY IF EXISTS "Users can insert own incomes" ON incomes;
DROP POLICY IF EXISTS "Users can update own incomes" ON incomes;
DROP POLICY IF EXISTS "Users can delete own incomes" ON incomes;

DROP POLICY IF EXISTS "Users can view own expense categories" ON expense_categories;
DROP POLICY IF EXISTS "Users can manage own expense categories" ON expense_categories;

DROP POLICY IF EXISTS "Users can view own income categories" ON income_categories;
DROP POLICY IF EXISTS "Users can manage own income categories" ON income_categories;

-- Create RLS policies for expenses
CREATE POLICY "Users can view own expenses" ON expenses
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own expenses" ON expenses
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own expenses" ON expenses
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own expenses" ON expenses
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for incomes
CREATE POLICY "Users can view own incomes" ON incomes
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own incomes" ON incomes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own incomes" ON incomes
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own incomes" ON incomes
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for categories
CREATE POLICY "Users can view own expense categories" ON expense_categories
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own expense categories" ON expense_categories
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own income categories" ON income_categories
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own income categories" ON income_categories
    FOR ALL USING (auth.uid() = user_id);

-- Update triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_expenses_updated_at ON expenses;
CREATE TRIGGER update_expenses_updated_at
    BEFORE UPDATE ON expenses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_incomes_updated_at ON incomes;
CREATE TRIGGER update_incomes_updated_at
    BEFORE UPDATE ON incomes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Verify schema
SELECT 'PRODUCTION SCHEMA READY' as status;
SELECT 'Expenses' as table_name, COUNT(*) as count FROM expenses;
SELECT 'Incomes' as table_name, COUNT(*) as count FROM incomes;
SELECT 'Expense Categories' as table_name, COUNT(*) as count FROM expense_categories;
SELECT 'Income Categories' as table_name, COUNT(*) as count FROM income_categories;
