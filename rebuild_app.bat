@echo off
echo ========================================
echo  Hotel Expense Tracker - Rebuild Script
echo ========================================
echo.

echo [1/5] Cleaning previous build...
call flutter clean
echo.

echo [2/5] Getting dependencies...
call flutter pub get
echo.

echo [3/5] Building APK...
call flutter build apk --release
echo.

echo [4/5] Installing on connected device...
call flutter install
echo.

echo ========================================
echo  Build Complete!
echo ========================================
echo.
echo Your app has been rebuilt and installed with all the latest changes.
echo You can now unplug USB debugging and test the app.
echo.
pause
