-- Security hardening: no data is read, changed or deleted by this migration.
--
-- 1. daily_summary had a policy "Allow all operations" (USING true / WITH CHECK true).
--    Policies are OR-ed, so it overrode the per-user policies and let anyone with
--    the public anon key read, edit or delete every user's daily summaries.
--    The per-user SELECT/INSERT/UPDATE/DELETE policies stay in place.
--
-- 2. These SECURITY DEFINER functions bypass RLS and take a user id (or email)
--    from the caller, so any anon caller could read another user's totals, or
--    reassign ownerless rows with migrate_data_to_user. Neither the app nor the
--    edge functions call them, so only service_role keeps EXECUTE.
--
-- 3. The analytics functions used by the edge functions run as SECURITY INVOKER
--    (RLS applies). The edge functions call them with the service role, so anon
--    does not need EXECUTE on them.
--
-- Rollback (if ever needed):
--   CREATE POLICY "Allow all operations on daily_summary" ON daily_summary FOR ALL USING (true) WITH CHECK (true);
--   GRANT EXECUTE ON FUNCTION <each function below> TO anon, authenticated;

BEGIN;

DROP POLICY IF EXISTS "Allow all operations on daily_summary" ON public.daily_summary;

REVOKE EXECUTE ON FUNCTION public.compare_date_ranges(text, text, text, text, uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.get_category_total(text, date, date, uuid, boolean) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.get_daily_data(date, uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.get_top_expense_categories(text, text, uuid, integer) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.migrate_data_to_user(text) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.compare_date_ranges(text, text, text, text, uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_category_total(text, date, date, uuid, boolean) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_daily_data(date, uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_top_expense_categories(text, text, uuid, integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.migrate_data_to_user(text) TO service_role;

REVOKE EXECUTE ON FUNCTION public.get_expense_summary_by_category(uuid, date, date) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_income_summary_by_category(uuid, date, date) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_daily_trend(uuid, integer) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_month_summary(uuid, integer, integer) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_savings_rate(uuid, date, date) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_top_spending_days(uuid, integer) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.get_expense_summary_by_category(uuid, date, date) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_income_summary_by_category(uuid, date, date) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_daily_trend(uuid, integer) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_month_summary(uuid, integer, integer) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_savings_rate(uuid, date, date) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_top_spending_days(uuid, integer) TO authenticated, service_role;

COMMIT;
