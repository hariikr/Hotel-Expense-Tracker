-- Seed Default Categories
-- Creates Online/Offline income categories and common expense categories for all users

-- Function to seed categories for a user
CREATE OR REPLACE FUNCTION seed_user_categories(target_user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Seed expense categories
    INSERT INTO expense_categories (user_id, name)
    VALUES 
        (target_user_id, 'Fish'),
        (target_user_id, 'Meat'),
        (target_user_id, 'Chicken'),
        (target_user_id, 'Milk'),
        (target_user_id, 'Vegetables'),
        (target_user_id, 'Rice'),
        (target_user_id, 'Coconut'),
        (target_user_id, 'Appam'),
        (target_user_id, 'Pathiri'),
        (target_user_id, 'Parotta'),
        (target_user_id, 'Labor'),
        (target_user_id, 'Others')
    ON CONFLICT (user_id, name) DO NOTHING;

    -- Seed income categories
    INSERT INTO income_categories (user_id, name)
    VALUES 
        (target_user_id, 'Online'),
        (target_user_id, 'Offline')
    ON CONFLICT (user_id, name) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Seed for all existing users
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN SELECT id FROM auth.users LOOP
        PERFORM seed_user_categories(user_record.id);
    END LOOP;
END $$;

-- Create trigger for new users
CREATE OR REPLACE FUNCTION trigger_seed_categories()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM seed_user_categories(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_auth_user_created_seed_categories ON auth.users;
CREATE TRIGGER on_auth_user_created_seed_categories
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION trigger_seed_categories();
