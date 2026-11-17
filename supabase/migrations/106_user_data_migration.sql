-- MIGRATION: DATA MERGE/MIGRATION
-- Source User: 44b5cb51-05d8-4590-bdf0-c6624517a93a
-- Target User: c8886bab-44f3-4c6a-897b-fbd7f3792b75

DO $$
DECLARE
    source_id UUID := '44b5cb51-05d8-4590-bdf0-c6624517a93a';
    target_id UUID := 'c8886bab-44f3-4c6a-897b-fbd7f3792b75';
    r RECORD;
    new_cat_id UUID;
BEGIN
    RAISE NOTICE 'Starting migration from % to %', source_id, target_id;

    -- 1. Migrate Expense Categories
    -- Loop through all categories owned by the source user
    FOR r IN SELECT * FROM expense_categories WHERE user_id = source_id LOOP
        -- Check if target user already has a category with this name
        SELECT id INTO new_cat_id FROM expense_categories WHERE user_id = target_id AND name = r.name;
        
        IF new_cat_id IS NOT NULL THEN
            -- Re-link source user's expenses to the target user's existing category
            UPDATE expenses SET category_id = new_cat_id WHERE user_id = source_id AND category_id = r.id;
        ELSE
            -- Move the category itself to the target user
            UPDATE expense_categories SET user_id = target_id WHERE id = r.id;
        END IF;
    END LOOP;

    -- 2. Migrate Income Categories
    FOR r IN SELECT * FROM income_categories WHERE user_id = source_id LOOP
        SELECT id INTO new_cat_id FROM income_categories WHERE user_id = target_id AND name = r.name;
        
        IF new_cat_id IS NOT NULL THEN
            UPDATE incomes SET category_id = new_cat_id WHERE user_id = source_id AND category_id = r.id;
        ELSE
            UPDATE income_categories SET user_id = target_id WHERE id = r.id;
        END IF;
    END LOOP;

    -- 3. Migrate Expenses (Ownership)
    -- Simply update the user_id for all remaining expenses
    UPDATE expenses SET user_id = target_id WHERE user_id = source_id;

    -- 4. Migrate Incomes (Ownership + Conflict Resolution)
    -- Incomes have a UNIQUE(user_id, date, category_id) constraint.
    -- We must merge entries if they conflict.
    FOR r IN SELECT * FROM incomes WHERE user_id = source_id LOOP
        IF EXISTS (SELECT 1 FROM incomes WHERE user_id = target_id AND date = r.date AND category_id = r.category_id) THEN
            -- Merge amount into the existing record
            UPDATE incomes 
            SET amount = amount + r.amount,
                description = COALESCE(description, '') || ' [Migrated: ' || COALESCE(r.description, '') || ']'
            WHERE user_id = target_id AND date = r.date AND category_id = r.category_id;
            
            -- Delete the source record since it's merged
            DELETE FROM incomes WHERE id = r.id;
        ELSE
            -- No conflict, just move ownership
            UPDATE incomes SET user_id = target_id WHERE id = r.id;
        END IF;
    END LOOP;

    -- 5. Migrate Daily Summaries (Optional but recommended for consistency)
    -- Merges summaries if entries exist for the same day
    FOR r IN SELECT * FROM daily_summary WHERE user_id = source_id LOOP
        IF EXISTS (SELECT 1 FROM daily_summary WHERE user_id = target_id AND date = r.date) THEN
            UPDATE daily_summary 
            SET total_income = total_income + r.total_income,
                total_expense = total_expense + r.total_expense,
                profit = profit + r.profit,
                meals_count = meals_count + COALESCE(r.meals_count, 0)
            WHERE user_id = target_id AND date = r.date;
            
            DELETE FROM daily_summary WHERE id = r.id;
        ELSE
            UPDATE daily_summary SET user_id = target_id WHERE id = r.id;
        END IF;
    END LOOP;

    -- 6. Cleanup leftover categories (those that were re-linked rather than moved)
    DELETE FROM expense_categories WHERE user_id = source_id;
    DELETE FROM income_categories WHERE user_id = source_id;

    RAISE NOTICE 'Migration completed successfully.';
END $$;
