# Android Release Build Setup for Google Play Store

This document records all the steps taken to configure the Highwoods Flutter app for Google Play Store release builds.

## Date
2025-11-25

## Overview
Configured the Android app with proper release signing using a keystore, updated build configuration, and successfully built an Android App Bundle (AAB) for Google Play Store upload.

---

## Steps Performed

### 1. Created Keystore File

Generated a new keystore for signing the release builds of the app.

**Command:**
```bash
"C:\Program Files\Java\jdk-22\bin\keytool.exe" -genkey -v \
  -keystore android/app/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias highwoods-key \
  -storepass "K:#x*ik[,MnPDZJv" \
  -keypass "K:#x*ik[,MnPDZJv" \
  -dname "CN=Solve With Software Ltd, OU=Development, O=Solve With Software Ltd, L=Colchester, ST=Essex, C=GB"
```

**Output:**
```
Generating 2,048 bit RSA key pair and self-signed certificate (SHA384withRSA)
with a validity of 10,000 days for:
CN=Solve With Software Ltd, OU=Development, O=Solve With Software Ltd, L=Colchester, ST=Essex, C=GB
[Storing android/app/upload-keystore.jks]
```

**File Created:**
- `android/app/upload-keystore.jks`

**Keystore Details:**
- **Key Alias:** highwoods-key
- **Keystore Password:** K:#x*ik[,MnPDZJv
- **Key Password:** K:#x*ik[,MnPDZJv
- **Algorithm:** RSA 2048-bit
- **Validity:** 10,000 days (~27 years)

---

### 2. Created Key Properties File

Created a properties file to store keystore configuration.

**File Created:** `android/key.properties`

**Contents:**
```properties
storePassword=K:#x*ik[,MnPDZJv
keyPassword=K:#x*ik[,MnPDZJv
keyAlias=highwoods-key
storeFile=upload-keystore.jks
```

---

### 3. Updated Build Configuration

Modified `android/app/build.gradle.kts` to use the keystore for release builds.

**File Modified:** `android/app/build.gradle.kts`

**Changes Made:**

1. Added imports at the top of the file:
```kotlin
import java.util.Properties
import java.io.FileInputStream
```

2. Added keystore properties loading:
```kotlin
// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

3. Added signing configuration:
```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}
```

4. Updated release build type:
```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

---

### 4. Updated .gitignore

Added keystore and properties files to `.gitignore` to prevent committing sensitive credentials.

**File Modified:** `.gitignore`

**Added:**
```gitignore
# Keystore files - NEVER commit these!
/android/key.properties
/android/app/*.jks
/android/app/*.keystore
```

---

### 5. Built Release AAB

Built the Android App Bundle for Google Play Store upload.

**Command:**
```bash
cd flutter-app/highwoods
flutter build appbundle
```

**Output:**
```
Running Gradle task 'bundleRelease'...
Font asset "MaterialIcons-Regular.otf" was tree-shaken, reducing it from 1645184 to 3444 bytes (99.8% reduction).
Running Gradle task 'bundleRelease'...                            287.4s
√ Built build\app\outputs\bundle\release\app-release.aab (41.5MB)
```

**Output File:**
- `build/app/outputs/bundle/release/app-release.aab` (41.5MB)

---

## Files Created/Modified Summary

### Created:
1. `android/app/upload-keystore.jks` - Keystore file for signing
2. `android/key.properties` - Keystore configuration
3. `build/app/outputs/bundle/release/app-release.aab` - Release AAB

### Modified:
1. `android/app/build.gradle.kts` - Build configuration with signing
2. `.gitignore` - Added keystore files to ignore list

---

## Security Notes

### CRITICAL - Protect These Files:

These files must be kept **SECRET** and **BACKED UP SECURELY**:

1. **Keystore File:** `android/app/upload-keystore.jks`
2. **Key Properties:** `android/key.properties`
3. **Passwords:**
   - Keystore Password: `K:#x*ik[,MnPDZJv`
   - Key Password: `K:#x*ik[,MnPDZJv`

### Important Security Requirements:

- ✅ Files are added to `.gitignore` - DO NOT commit to version control
- ✅ Store keystore and passwords in a secure password manager
- ✅ Create encrypted backups of the keystore file
- ⚠️ If you lose these files, you CANNOT update your app on Google Play Store
- ⚠️ You will have to publish a new app with a different package name

---

## Next Steps for Google Play Store Upload

### 1. Prepare for Upload
- Ensure you have a Google Play Developer account ($25 one-time fee)
- Prepare app store listing materials:
  - App icon
  - Feature graphic (1024 x 500px)
  - Screenshots (phone and tablet)
  - App description
  - Privacy policy URL

### 2. Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Create a new app or select existing app
3. Navigate to **Production** → **Create new release**
4. Upload the AAB file: `build/app/outputs/bundle/release/app-release.aab`
5. Fill in release notes
6. Review and rollout

### 3. App Details

- **Package Name:** com.solvewithsoftware.highwoods
- **Version Code:** (from pubspec.yaml)
- **Version Name:** 0.1.0

---

## Future Releases

To build future releases:

### 1. Update Version
Edit `pubspec.yaml`:
```yaml
version: 0.2.0  # Increment version
```

### 2. Build Release AAB
```bash
cd flutter-app/highwoods
flutter clean
flutter pub get
flutter build appbundle
```

### 3. Upload to Play Console
Upload the new AAB file from `build/app/outputs/bundle/release/app-release.aab`

---

## Troubleshooting

### Build Fails with Signing Error
- Verify `android/key.properties` exists
- Verify `android/app/upload-keystore.jks` exists
- Check that passwords in `key.properties` are correct

### NDK Version Warnings
The build may show warnings about NDK versions. These are non-critical but can be fixed by updating `android/app/build.gradle.kts`:
```kotlin
android {
    ndkVersion = "27.0.12077973"
    ...
}
```

### Clean Build
If you encounter build issues:
```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter build appbundle
```

---

## References

- [Flutter Deployment Documentation](https://docs.flutter.dev/deployment/android)
- [Google Play Console](https://play.google.com/console)
- [Android App Signing Guide](https://developer.android.com/studio/publish/app-signing)

---

## Certificate Information

The keystore contains a self-signed certificate with the following details:

- **Common Name (CN):** Solve With Software Ltd
- **Organizational Unit (OU):** Development
- **Organization (O):** Solve With Software Ltd
- **Locality (L):** Colchester
- **State (ST):** Essex
- **Country (C):** GB
- **Key Algorithm:** RSA
- **Key Size:** 2048 bits
- **Signature Algorithm:** SHA384withRSA
- **Validity:** 10,000 days (from 2025-11-25)

---

**Document Created:** 2025-11-25
**Created By:** Claude Code
**App:** Highwoods Flutter App
**Developer:** Solve With Software Ltd
