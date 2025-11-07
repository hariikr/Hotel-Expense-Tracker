-- Hotel Expense Tracker Database Schema
-- This migration creates the core tables and triggers for the application

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Income Table
CREATE TABLE IF NOT EXISTS income (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date TIMESTAMPTZ NOT NULL UNIQUE,
    online_income NUMERIC(10, 2) DEFAULT 0.00 CHECK (online_income >= 0),
    offline_income NUMERIC(10, 2) DEFAULT 0.00 CHECK (offline_income >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Expense Table
CREATE TABLE IF NOT EXISTS expense (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date TIMESTAMPTZ NOT NULL UNIQUE,
    fish NUMERIC(10, 2) DEFAULT 0.00 CHECK (fish >= 0),
    meat NUMERIC(10, 2) DEFAULT 0.00 CHECK (meat >= 0),
    chicken NUMERIC(10, 2) DEFAULT 0.00 CHECK (chicken >= 0),
    milk NUMERIC(10, 2) DEFAULT 0.00 CHECK (milk >= 0),
    parotta NUMERIC(10, 2) DEFAULT 0.00 CHECK (parotta >= 0),
    pathiri NUMERIC(10, 2) DEFAULT 0.00 CHECK (pathiri >= 0),
    dosa NUMERIC(10, 2) DEFAULT 0.00 CHECK (dosa >= 0),
    appam NUMERIC(10, 2) DEFAULT 0.00 CHECK (appam >= 0),
    coconut NUMERIC(10, 2) DEFAULT 0.00 CHECK (coconut >= 0),
    vegetables NUMERIC(10, 2) DEFAULT 0.00 CHECK (vegetables >= 0),
    rice NUMERIC(10, 2) DEFAULT 0.00 CHECK (rice >= 0),
    labor_manisha NUMERIC(10, 2) DEFAULT 0.00 CHECK (labor_manisha >= 0),
    labor_midhun NUMERIC(10, 2) DEFAULT 0.00 CHECK (labor_midhun >= 0),
    others NUMERIC(10, 2) DEFAULT 0.00 CHECK (others >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Daily Summary Table
CREATE TABLE IF NOT EXISTS daily_summary (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date TIMESTAMPTZ NOT NULL UNIQUE,
    total_income NUMERIC(10, 2) DEFAULT 0.00,
    total_expense NUMERIC(10, 2) DEFAULT 0.00,
    profit NUMERIC(10, 2) DEFAULT 0.00,
    meals_count INTEGER DEFAULT 0 CHECK (meals_count >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_income_date ON income(date DESC);
CREATE INDEX IF NOT EXISTS idx_expense_date ON expense(date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_summary_date ON daily_summary(date DESC);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_income_updated_at
    BEFORE UPDATE ON income
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_expense_updated_at
    BEFORE UPDATE ON expense
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_summary_updated_at
    BEFORE UPDATE ON daily_summary
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate total income
CREATE OR REPLACE FUNCTION calculate_total_income(inc_record income)
RETURNS NUMERIC AS $$
BEGIN
    RETURN COALESCE(inc_record.online_income, 0) + COALESCE(inc_record.offline_income, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to calculate total expense
CREATE OR REPLACE FUNCTION calculate_total_expense(exp_record expense)
RETURNS NUMERIC AS $$
BEGIN
    RETURN COALESCE(exp_record.fish, 0) + 
           COALESCE(exp_record.meat, 0) + 
           COALESCE(exp_record.chicken, 0) + 
           COALESCE(exp_record.milk, 0) + 
           COALESCE(exp_record.parotta, 0) + 
           COALESCE(exp_record.pathiri, 0) + 
           COALESCE(exp_record.dosa, 0) + 
           COALESCE(exp_record.appam, 0) + 
           COALESCE(exp_record.coconut, 0) + 
           COALESCE(exp_record.vegetables, 0) + 
           COALESCE(exp_record.rice, 0) + 
           COALESCE(exp_record.labor_manisha, 0) + 
           COALESCE(exp_record.labor_midhun, 0) + 
           COALESCE(exp_record.others, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to update or create daily summary
CREATE OR REPLACE FUNCTION update_daily_summary(summary_date TIMESTAMPTZ)
RETURNS VOID AS $$
DECLARE
    v_total_income NUMERIC := 0;
    v_total_expense NUMERIC := 0;
    v_profit NUMERIC := 0;
    v_income_record income;
    v_expense_record expense;
BEGIN
    -- Get income for the date
    SELECT * INTO v_income_record FROM income WHERE date = summary_date;
    IF FOUND THEN
        v_total_income := calculate_total_income(v_income_record);
    END IF;

    -- Get expense for the date
    SELECT * INTO v_expense_record FROM expense WHERE date = summary_date;
    IF FOUND THEN
        v_total_expense := calculate_total_expense(v_expense_record);
    END IF;

    -- Calculate profit
    v_profit := v_total_income - v_total_expense;

    -- Insert or update daily_summary
    INSERT INTO daily_summary (date, total_income, total_expense, profit)
    VALUES (summary_date, v_total_income, v_total_expense, v_profit)
    ON CONFLICT (date) 
    DO UPDATE SET
        total_income = EXCLUDED.total_income,
        total_expense = EXCLUDED.total_expense,
        profit = EXCLUDED.profit,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update daily_summary when income is inserted/updated
CREATE OR REPLACE FUNCTION trigger_update_summary_on_income()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM update_daily_summary(NEW.date);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER income_update_summary
    AFTER INSERT OR UPDATE ON income
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_summary_on_income();

-- Trigger to auto-update daily_summary when expense is inserted/updated
CREATE OR REPLACE FUNCTION trigger_update_summary_on_expense()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM update_daily_summary(NEW.date);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER expense_update_summary
    AFTER INSERT OR UPDATE ON expense
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_summary_on_expense();

-- Enable Row Level Security (RLS)
ALTER TABLE income ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_summary ENABLE ROW LEVEL SECURITY;

-- Create policies (adjust based on your auth requirements)
-- For now, allow all operations for authenticated users
CREATE POLICY "Enable all operations for authenticated users" ON income
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all operations for authenticated users" ON expense
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all operations for authenticated users" ON daily_summary
    FOR ALL USING (auth.role() = 'authenticated');

-- For development/testing: allow anonymous access (remove in production)
CREATE POLICY "Enable read access for all" ON income
    FOR SELECT USING (true);

CREATE POLICY "Enable read access for all" ON expense
    FOR SELECT USING (true);

CREATE POLICY "Enable read access for all" ON daily_summary
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for all" ON income
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable insert for all" ON expense
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable update for all" ON income
    FOR UPDATE USING (true);

CREATE POLICY "Enable update for all" ON expense
    FOR UPDATE USING (true);

CREATE POLICY "Enable update for all" ON daily_summary
    FOR UPDATE USING (true);

CREATE POLICY "Enable delete for all" ON income
    FOR DELETE USING (true);

CREATE POLICY "Enable delete for all" ON expense
    FOR DELETE USING (true);
