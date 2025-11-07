# App Icon Instructions

## How to Change the App Icon

### Step 1: Create or Get Your Icon
1. Create a square image (preferably 1024x1024 pixels)
2. Save it as `app_icon.png` in the `assets/icon/` folder
3. Make sure it's a PNG file with transparency if needed

### Step 2: Generate Launcher Icons
Run the following command in your terminal:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

This will automatically generate all required icon sizes for Android and iOS.

### Step 3: Rebuild Your App
```bash
flutter clean
flutter run
```

## Icon Design Tips

### For Hotel Expense Tracker:
- Use hotel/restaurant related imagery (🏨 🍽️ 📊)
- Consider colors that match your app theme:
  - Primary: #2196F3 (Blue)
  - Profit: #4CAF50 (Green)
  - Loss: #F44336 (Red)
  
### Recommended Icon Sizes:
- **Source image**: 1024x1024 px (PNG with transparency)
- Android generates: hdpi, mdpi, xhdpi, xxhdpi, xxxhdpi
- iOS generates: Multiple sizes for different devices

### Design Recommendations:
1. Keep it simple and recognizable
2. Avoid text (it won't be readable at small sizes)
3. Use high contrast
4. Test on both light and dark backgrounds
5. Consider using a solid background color for better visibility

## Quick Icon Ideas:

### Option 1: Hotel + Chart
- Building/hotel icon with an upward trending arrow

### Option 2: Receipt + Money
- Receipt paper with currency symbol

### Option 3: Dashboard Style
- Simple pie chart or bar graph with hotel theme

### Option 4: Minimalist
- Letters "HET" (Hotel Expense Tracker) in a circle

## Online Icon Generators:
- https://www.canva.com/create/logos/
- https://www.flaticon.com/
- https://icon-icons.com/
- https://www.iconfinder.com/

## Current Icon Location:
- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

The flutter_launcher_icons package will automatically update these locations when you run the command.
