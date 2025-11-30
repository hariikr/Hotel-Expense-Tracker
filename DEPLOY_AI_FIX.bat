@echo off
echo ========================================
echo  Deploying AI Chat Fix to Supabase
echo ========================================
echo.
echo Fixes applied:
echo  1. Added tool_config with function_calling_config
echo  2. Enhanced parseDate() for Malayalam dates
echo  3. Removed all [CALLS ...] examples from prompt
echo  4. Added clear warnings against text-based function calls
echo.
echo Deploying...
echo.

cd /d "%~dp0"
supabase functions deploy ai-chat

echo.
echo ========================================
echo  Deployment Complete!
echo ========================================
echo.
echo Test the following:
echo  - "ഇന്നലെ കണക്ക്" (yesterday's data)
echo  - "നവംബർ 21" (November 21 data)
echo  - "ഈ ആഴ്ച മൊത്തം" (this week total)
echo.
pause
