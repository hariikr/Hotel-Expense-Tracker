@echo off
REM AI Chat Function Diagnostic Script
REM This will test all components and identify issues

echo ============================================
echo AI Chat Function Diagnostic Tool
echo ============================================
echo.

set SUPABASE_URL=https://khpeuremcbkpdmombtkg.supabase.co
set ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtocGV1cmVtY2JrcGRtb21idGtnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0ODYyMDQsImV4cCI6MjA3NzA2MjIwNH0.PBFteAldiRWOR2t74QajvwqTLEfs2D32oWawakweaN4

echo Test 1: Checking if Edge Function is deployed...
echo ------------------------------------------------
curl -X POST "%SUPABASE_URL%/functions/v1/ai-chat" ^
  -H "Authorization: Bearer %ANON_KEY%" ^
  -H "Content-Type: application/json" ^
  -d "{\"message\": \"test\", \"userId\": null}" ^
  -w "\nHTTP Status: %%{http_code}\n"

echo.
echo.
echo Test 2: Checking if database functions exist...
echo ------------------------------------------------
echo Running SQL query to check functions...
curl -X POST "%SUPABASE_URL%/rest/v1/rpc/get_daily_data" ^
  -H "apikey: %ANON_KEY%" ^
  -H "Authorization: Bearer %ANON_KEY%" ^
  -H "Content-Type: application/json" ^
  -d "{\"target_date\": \"2024-01-01\"}" ^
  -w "\nHTTP Status: %%{http_code}\n"

echo.
echo.
echo Test 3: Testing with a simple message (English)...
echo ------------------------------------------------
curl -X POST "%SUPABASE_URL%/functions/v1/ai-chat" ^
  -H "Authorization: Bearer %ANON_KEY%" ^
  -H "Content-Type: application/json" ^
  -d "{\"message\": \"Hello\", \"userId\": null}" ^
  -w "\nHTTP Status: %%{http_code}\n"

echo.
echo.
echo Test 4: Testing with Malayalam message...
echo ------------------------------------------------
curl -X POST "%SUPABASE_URL%/functions/v1/ai-chat" ^
  -H "Authorization: Bearer %ANON_KEY%" ^
  -H "Content-Type: application/json" ^
  -d "{\"message\": \"ഹലോ\", \"userId\": null}" ^
  -w "\nHTTP Status: %%{http_code}\n"

echo.
echo.
echo ============================================
echo Diagnostic Complete!
echo ============================================
echo.
echo INTERPRETING RESULTS:
echo.
echo - HTTP Status 200 = Success!
echo - HTTP Status 404 = Function not deployed
echo - HTTP Status 500 = Function deployed but has errors
echo - HTTP Status 401 = Authentication issue
echo.
echo If you see 404: Deploy the edge function first
echo If you see 500: Check function logs for errors
echo.
pause
