# Deep Link Setup

This folder contains the Digital Asset Links file for Android App Links verification.

## Setup Instructions

1. **Get your SHA256 certificate fingerprint**:
   ```bash
   # For debug keystore:
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # For release keystore:
   keytool -list -v -keystore path/to/your/release.keystore -alias your-alias
   ```

2. **Update assetlinks.json**:
   Replace `YOUR_SHA256_CERT_FINGERPRINT_HERE` with your actual SHA256 fingerprint (format: `XX:XX:XX:XX...`).

3. **Host this file**:
   Upload `assetlinks.json` to `https://shivaaymusic.app/.well-known/assetlinks.json`

## Verification

Test your App Links setup:
```bash
# Check if your assetlinks.json is correctly hosted
curl https://shivaaymusic.app/.well-known/assetlinks.json

# Verify the link on Android (requires ADB)
adb shell am start -a android.intent.action.VIEW \
  -d "https://shivaaymusic.app/play?url=https%3A%2F%2Fyoutube.com%2Fwatch%3Fv%3DdQw4w9WgXcQ"
```
