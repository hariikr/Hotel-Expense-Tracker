# Fixing JAVA_HOME Issue

## Problem
The error indicates that JAVA_HOME is pointing to an invalid directory:
```
ERROR: JAVA_HOME is set to an invalid directory: C:\Program Files\Eclipse Adoptium\jdk-21.0.x.x-hotspot
```

## Solution

### Option 1: Fix JAVA_HOME Environment Variable (Recommended)

1. **Find your actual Java installation:**
   - Open File Explorer
   - Navigate to `C:\Program Files\Eclipse Adoptium\`
   - Find the correct JDK folder (it should be something like `jdk-21.0.5-hotspot` not `jdk-21.0.x.x-hotspot`)

2. **Update JAVA_HOME:**
   - Press `Win + X` and select "System"
   - Click "Advanced system settings"
   - Click "Environment Variables"
   - Find `JAVA_HOME` in System Variables
   - Click "Edit"
   - Update the path to the correct JDK folder (e.g., `C:\Program Files\Eclipse Adoptium\jdk-21.0.5-hotspot`)
   - Click OK on all windows

3. **Restart PowerShell/Terminal**
   - Close all terminal windows
   - Open a new terminal
   - Run: `flutter doctor -v` to verify

4. **Try running the app again:**
   ```powershell
   flutter run
   ```

### Option 2: Use Flutter Doctor to Check Java

Run this command to see what Flutter detects:
```powershell
flutter doctor -v
```

This will show you the exact Java version Flutter is finding.

### Option 3: Install/Reinstall Java

If you can't find the correct JDK folder:

1. **Download Java JDK:**
   - Visit: https://adoptium.net/
   - Download Temurin JDK 17 or 21 (LTS versions)
   - Install it (note the installation path)

2. **Set JAVA_HOME manually:**
   ```powershell
   setx JAVA_HOME "C:\Program Files\Eclipse Adoptium\jdk-17.0.xx-hotspot" /M
   ```
   (Replace with your actual path)

3. **Restart terminal and try again**

### Option 4: Quick PowerShell Fix (Temporary)

For a quick temporary fix in your current PowerShell session:

```powershell
# Find Java
dir "C:\Program Files\Eclipse Adoptium\"

# Set JAVA_HOME for this session (replace with actual folder name)
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-21.0.5-hotspot"

# Verify
echo $env:JAVA_HOME

# Now run Flutter
flutter run
```

## After Fixing JAVA_HOME

Once JAVA_HOME is fixed, run:

```powershell
flutter clean
flutter pub get
flutter run
```

## Alternative: Run on Web (No Java Required)

If you want to test the app quickly without fixing Java:

```powershell
flutter run -d chrome
```

This runs the app in Chrome browser (no Java/Android required).

## Verify Everything Works

After fixing JAVA_HOME, verify your setup:

```powershell
flutter doctor -v
```

You should see:
- ✓ Flutter (Channel stable, ...)
- ✓ Android toolchain (with Java version)
- ✓ Chrome - develop for the web
- etc.

## Need More Help?

If you're still having issues:

1. Check the exact folder name in `C:\Program Files\Eclipse Adoptium\`
2. Make sure there are no trailing spaces in JAVA_HOME
3. Restart your computer after changing environment variables
4. Run `flutter doctor` to see all issues

---

**Quick Test:** Run this to see what JAVA_HOME is currently set to:
```powershell
echo $env:JAVA_HOME
```

It should show a valid folder path like:
```
C:\Program Files\Eclipse Adoptium\jdk-21.0.5-hotspot
```

Not:
```
C:\Program Files\Eclipse Adoptium\jdk-21.0.x.x-hotspot
```
