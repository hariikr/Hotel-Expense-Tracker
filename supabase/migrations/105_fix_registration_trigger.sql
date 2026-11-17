-- Fix Registration Triggers
-- Consolidates profile creation and category seeding into a single, robust transaction
-- Ensures all operations run with SECURITY DEFINER to bypass RLS during signup

-- 1. Create a consolidated handler function
CREATE OR REPLACE FUNCTION public.handle_new_user_setup()
RETURNS trigger AS $$
DECLARE
    default_expense_categories TEXT[] := ARRAY['Fish', 'Meat', 'Chicken', 'Milk', 'Vegetables', 'Rice', 'Coconut', 'Appam', 'Pathiri', 'Parotta', 'Labor', 'Others'];
    default_income_categories TEXT[] := ARRAY['Online', 'Offline'];
    cat_name TEXT;
BEGIN
    -- A. Create User Profile
    -- We use COALESCE and ensure required fields like email are present
    -- If email is missing (OAuth sometimes hides it), we use a placeholder or the ID
    INSERT INTO public.profiles (
        id, 
        email, 
        full_name, 
        business_name,
        preferred_language,
        business_type,
        timezone
    )
    VALUES (
        new.id, 
        COALESCE(new.email, new.id::TEXT || '@placeholder.com'), 
        COALESCE(new.raw_user_meta_data->>'full_name', 'User'), 
        COALESCE(new.raw_user_meta_data->>'business_name', 'My Hotel'),
        COALESCE(new.raw_user_meta_data->>'preferred_language', 'ml'),
        COALESCE(new.raw_user_meta_data->>'business_type', 'hotel'),
        COALESCE(new.raw_user_meta_data->>'timezone', 'Asia/Kolkata')
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        updated_at = NOW();

    -- B. Seed Expense Categories
    FOREACH cat_name IN ARRAY default_expense_categories LOOP
        INSERT INTO public.expense_categories (user_id, name)
        VALUES (new.id, cat_name)
        ON CONFLICT (user_id, name) DO NOTHING;
    END LOOP;

    -- C. Seed Income Categories
    FOREACH cat_name IN ARRAY default_income_categories LOOP
        INSERT INTO public.income_categories (user_id, name)
        VALUES (new.id, cat_name)
        ON CONFLICT (user_id, name) DO NOTHING;
    END LOOP;

    RETURN new;
EXCEPTION WHEN OTHERS THEN
    -- In rare cases, we don't want the whole registration to fail 
    -- if just the seeding fails, but since this is critical, we log it or let it fail
    -- For now, let it fail to ensure database integrity
    RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Clean up old triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_seed_categories ON auth.users;

-- 3. Create the single, unified trigger
CREATE TRIGGER on_auth_user_created_master
  AFTER INSERT ON auth.users
  FOR EACH ROW 
  EXECUTE FUNCTION public.handle_new_user_setup();

-- Explanation:
-- This script fixes the "Database error saving new user" issue by:
-- 1. Using SECURITY DEFINER so background inserts into profiles/categories aren't blocked by RLS.
-- 2. Consolidating multiple triggers into one to avoid race conditions and transaction issues.
-- 3. Handling NULL values gracefully with COALESCE.
-- 4. Using ON CONFLICT to prevent errors if a registration is retried.
