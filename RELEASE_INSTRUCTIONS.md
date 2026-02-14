# How to Release the App for a Client

To share the app with a client, you need to build a **Release APK**.

## 1. Update Version (Optional but Recommended)
Open `pubspec.yaml` and update the version number to keep track of releases.
Current version: `1.0.1+2`
Change to: `1.0.2+3` (or your preferred version)

```yaml
version: 1.0.2+3
```

## 2. Clean the Project
Run this command in your terminal to ensure a fresh build:
```bash
flutter clean
flutter pub get
```

## 3. Build the APK
Run the following command to generate the release APK:
```bash
flutter build apk --release
```

**Note:** Since we haven't set up a custom keystore, this release will use the **debug signature**. 
- Users might see a "Play Protect" warning when installing. This is normal for test builds.
- They can click "Install Anyway" to proceed.
- This APK is safe to send via WhatsApp, Email, or Drive.

## 4. Locate the File
After the build finishes, find the APK here:
`build/app/outputs/flutter-apk/app-release.apk`
(path relative to project root)

## 5. Share with Client
Send the `app-release.apk` file to your client. They can install it directly on their Android phone.
