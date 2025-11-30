@echo off
echo ===================================
echo AI Chat Function Deployment Helper
echo ===================================
echo.

echo This script will help you deploy the AI chat function.
echo.
echo PREREQUISITES:
echo 1. Supabase CLI must be installed
echo 2. You must have a Gemini API key
echo 3. Database migration must be applied first
echo.

pause

echo.
echo Step 1: Checking if Supabase CLI is installed...
where supabase >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Supabase CLI is not installed!
    echo.
    echo Install it using one of these methods:
    echo.
    echo Option 1 - Using npm:
    echo   npm install -g supabase
    echo.
    echo Option 2 - Using Scoop:
    echo   scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
    echo   scoop install supabase
    echo.
    echo Option 3 - Download installer:
    echo   https://github.com/supabase/cli/releases
    echo.
    echo After installation, run this script again.
    pause
    exit /b 1
)

echo [OK] Supabase CLI is installed
echo.

echo Step 2: Login to Supabase...
echo (A browser window will open)
pause
supabase login

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Login failed
    pause
    exit /b 1
)

echo.
echo Step 3: Linking project...
echo Project Reference: khpeuremcbkpdmombtkg
pause
supabase link --project-ref khpeuremcbkpdmombtkg

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Project linking failed
    pause
    exit /b 1
)

echo.
echo Step 4: Do you have your Gemini API key ready?
echo Get it from: https://makersuite.google.com/app/apikey
echo.
set /p apikey="Enter your Gemini API key (or press Enter to skip): "

if not "%apikey%"=="" (
    echo Setting GEMINI_API_KEY secret...
    supabase secrets set GEMINI_API_KEY=%apikey%
    echo [OK] API key set
) else (
    echo [SKIP] You'll need to set the API key manually in Supabase dashboard
)

echo.
echo Step 5: Deploying ai-chat function...
pause
supabase functions deploy ai-chat

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Function deployment failed
    echo.
    echo Check:
    echo - Is the function code in: supabase\functions\ai-chat\index.ts
    echo - Are there any syntax errors in the code
    pause
    exit /b 1
)

echo.
echo ===================================
echo [SUCCESS] Deployment Complete!
echo ===================================
echo.
echo Function URL:
echo https://khpeuremcbkpdmombtkg.supabase.co/functions/v1/ai-chat
echo.
echo Next steps:
echo 1. Test the function using test_ai_chat.bat
echo 2. Run your Flutter app
echo 3. Check the AI tab
echo.
pause
