-- Migration: Migrate Existing Data to Specific User
-- Description: Associate existing data (with null user_id) to the user with the specified email.
-- Note: Requires the user to be signed up first!

CREATE OR REPLACE FUNCTION migrate_data_to_user(target_email TEXT)
RETURNS TEXT AS $$
DECLARE
    target_user_id UUID;
    income_count INTEGER;
    expense_count INTEGER;
    summary_count INTEGER;
    chat_count INTEGER;
BEGIN
    -- Get user ID
    SELECT id INTO target_user_id FROM auth.users WHERE email = target_email;

    IF target_user_id IS NULL THEN
        RETURN 'User not found: ' || target_email;
    END IF;

    -- Update Income
    UPDATE income 
    SET user_id = target_user_id 
    WHERE user_id IS NULL;
    GET DIAGNOSTICS income_count = ROW_COUNT;

    -- Update Expense
    UPDATE expense 
    SET user_id = target_user_id 
    WHERE user_id IS NULL;
    GET DIAGNOSTICS expense_count = ROW_COUNT;

    -- Update Daily Summary
    UPDATE daily_summary 
    SET user_id = target_user_id 
    WHERE user_id IS NULL;
    GET DIAGNOSTICS summary_count = ROW_COUNT;

    -- Update Chat Messages
    UPDATE chat_messages 
    SET user_id = target_user_id 
    WHERE user_id IS NULL;
    GET DIAGNOSTICS chat_count = ROW_COUNT;

    RETURN format(
        'Migration successful for %s. Updated: %s income, %s expense, %s summary, %s chat records.',
        target_email, income_count, expense_count, summary_count, chat_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Usage:
-- SELECT migrate_data_to_user('mom@example.com');
