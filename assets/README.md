# Assets Folder

Place your images here:

## Required Images:

### 1. App Launcher Icon
- **File:** `images/logo.png`
- **Recommended size:** 1024x1024px (will be auto-resized)
- **Format:** PNG with transparent background
- **Usage:** This will be your app icon on the home screen

### 2. Splash Screen Logo
- **File:** `images/splash_logo.png`
- **Recommended size:** 512x512px or larger
- **Format:** PNG with transparent background
- **Usage:** Displayed on the splash screen when app launches

## After Adding Images:

Run these commands in order:

```bash
# 1. Install new packages
flutter pub get

# 2. Generate launcher icons
dart run flutter_launcher_icons

# 3. Generate splash screen
dart run flutter_native_splash:create

# 4. Clean and rebuild
flutter clean
flutter run
```

## Color Scheme:

The current theme uses: **#4A7C59** (forest green)

You can change this in `pubspec.yaml` under:
- `flutter_launcher_icons.adaptive_icon_background`
- `flutter_native_splash.color`
- `flutter_native_splash.android_12.color`

## Additional Images:

Place any other app images in:
- `images/` - for photos, illustrations, etc.
- `icons/` - for custom icon files

They will be automatically available in your Flutter code!
