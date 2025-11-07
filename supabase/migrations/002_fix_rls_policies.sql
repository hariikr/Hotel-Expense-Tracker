-- Fix Row Level Security Policies
-- This migration removes conflicting policies and creates proper policies for anonymous access

-- Drop all existing policies
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON income;
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON expense;
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON daily_summary;
DROP POLICY IF EXISTS "Enable read access for all" ON income;
DROP POLICY IF EXISTS "Enable read access for all" ON expense;
DROP POLICY IF EXISTS "Enable read access for all" ON daily_summary;
DROP POLICY IF EXISTS "Enable insert for all" ON income;
DROP POLICY IF EXISTS "Enable insert for all" ON expense;
DROP POLICY IF EXISTS "Enable update for all" ON income;
DROP POLICY IF EXISTS "Enable update for all" ON expense;
DROP POLICY IF EXISTS "Enable update for all" ON daily_summary;
DROP POLICY IF EXISTS "Enable delete for all" ON income;
DROP POLICY IF EXISTS "Enable delete for all" ON expense;

-- Create comprehensive policies that allow all operations for both authenticated and anonymous users
-- INCOME TABLE POLICIES
CREATE POLICY "Allow all operations on income" ON income
    FOR ALL 
    USING (true)
    WITH CHECK (true);

-- EXPENSE TABLE POLICIES
CREATE POLICY "Allow all operations on expense" ON expense
    FOR ALL 
    USING (true)
    WITH CHECK (true);

-- DAILY SUMMARY TABLE POLICIES
CREATE POLICY "Allow all operations on daily_summary" ON daily_summary
    FOR ALL 
    USING (true)
    WITH CHECK (true);

-- Note: In production, you should replace these permissive policies with more restrictive ones
-- For example:
-- CREATE POLICY "Allow operations for authenticated users" ON income
--     FOR ALL 
--     USING (auth.role() = 'authenticated')
--     WITH CHECK (auth.role() = 'authenticated');
