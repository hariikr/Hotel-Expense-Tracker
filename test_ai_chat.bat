@echo off
REM Quick Test Script for AI Chat Edge Function
REM Replace YOUR_ANON_KEY with your actual Supabase anon key

echo Testing AI Chat Edge Function...
echo.

REM Test 1: English question
echo Test 1: English Question
curl -X POST "https://khpeuremcbkpdmombtkg.supabase.co/functions/v1/ai-chat" ^
  -H "Authorization: Bearer YOUR_ANON_KEY" ^
  -H "Content-Type: application/json" ^
  -d "{\"message\": \"What is today's profit?\", \"userId\": null}"

echo.
echo.

REM Test 2: Malayalam question
echo Test 2: Malayalam Question
curl -X POST "https://khpeuremcbkpdmombtkg.supabase.co/functions/v1/ai-chat" ^
  -H "Authorization: Bearer YOUR_ANON_KEY" ^
  -H "Content-Type: application/json" ^
  -d "{\"message\": \"ഇന്നത്തെ ലാഭം എത്ര?\", \"userId\": null}"

echo.
echo.
echo Tests completed!
pause
