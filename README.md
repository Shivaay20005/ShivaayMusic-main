# ShivaayMusic

<div align="center">
  <img src="https://github.com/shivaay20005/ShivaayMusic-Windows-release/blob/main/cover.png" width="100%" >
</div>

## 🎵 Premium Music Experience

**ShivaayMusic** is a cross-platform (Windows & Android) music streaming app built with Flutter, designed for speed, beauty, and privacy.
It combines **Material 3** aesthetics with powerful **Cloud Sync**, delivering a seamless experience across all your devices.

---

# 🌟 Key Features

### 🎧 Listening Experience

- **Unlimited Streaming**: High-quality audio from YouTube/YouTube Music.
- **Auto-Caching**: Songs are automatically cached for offline listening while you play.
- **Smart Downloads**: Fast multi-threaded downloader with support for Opus/M4a formats.
- **Explore Tab (New!)**: Discover new music with the rebranded Compass Explore tab.
- **Lyrics**: Synced and plain lyrics integration.
- **Audio Control**: Built-in 6-band Equalizer, Loudness Normalization, and Sleep Timer.

### ☁️ Cloud Sync & Backup

- **Sync Everything**: Your History, Favorites, Playlists, and App Settings sync instantly across Windows & Android via Firebase.
- **Smart Restore**: Log in once, and your entire library is restored in seconds.
- **Profile Sync**: Uses your Google Avatar and Name for a personalized touch.

### 🎨 Design & Customization

- **Material 3 UI**: Modern animations, rounded corners, and dynamic color theming.
- **Dynamic Themes**: The UI draws colors from the current song's album art.
- **Aesthetic Modes**:
  - **Dark Mode**: The signature deep black/OLED-friendly theme.
  - **Light Mode**: A new premium Monochrome/Black & White theme for high contrast.

### 🔒 Privacy & Security

- **Biometric App Lock**: Secure your music with:
  - **Windows**: PIN / Windows Hello.
  - **Android**: Fingerprint / Face Unlock.
- **Safe Mode**: Manual "Unlock" button to prevent infinite auth loops.
- **Admin Broadcasts (New!)**: Receive important updates and alerts directly from the developer within the app.

---

# 📦 Download & Installation

### 💻 Windows

- **Installer (.exe)**: Recommended. Installs to AppData (No Admin Rights needed). Supports `Win+R` -> `shivaaymusic`.
- **Portable**: Standalone executable for USB drives.

### 📱 Android

- **APK**: Install the latest `app-release.apk` for the best experience.
- _Supports Android 5.0 (Lollipop) to Android 14._

[**📥 Download Latest Version**](https://github.com/shivaay20005/ShivaayMusic-Windows-release/releases/latest)

---

# 🛠️ For Developers

### Prerequisites

1. **Flutter SDK**: 3.27+
2. **Dart**: 3.6+
3. **Visual Studio** (C++ Workload) for Windows build.

### Firebase Setup

1. Create a project on [Firebase Console](https://console.firebase.google.com/).
2. Enable **Firestore** & **Authentication** (Google Sign-In).
3. Place `google-services.json` in `android/app/`.
4. _Note: Admin features require specific database rules._

```bash
# Clone & Run
git clone https://github.com/shivaay20005/ShivaayMusic.git
cd ShivaayMusic
flutter pub get
flutter run
```

### 📱 Android Build Commands

Generate optimized APKs for different Android versions and architectures:

| Command                             | Output Type             | Supports                               | Use Case                                                                                         |
| :---------------------------------- | :---------------------- | :------------------------------------- | :----------------------------------------------------------------------------------------------- |
| `flutter build apk --release`       | **Fat APK** (Universal) | All Devices (ARM, x86, x64)            | Best for sharing directly with friends. Works everywhere but file size is larger.                |
| `flutter build apk --split-per-abi` | **Split APKs**          | Specific CPUs (arm64-v8a, armeabi-v7a) | Creates separate small APKs for each device type. Best for reducing download size.               |
| `flutter build appbundle`           | **AAB** (App Bundle)    | Play Store Standard                    | **Required for Google Play Store**. Google generates the correct APK for the user automatically. |

> **Supported Architectures:**
>
> - `armeabi-v7a` (Old Android phones, 32-bit)
> - `arm64-v8a` (Modern Android phones, 64-bit)
> - `x86_64` (Emulators / Desktop Android)

### 💻 Windows Build Commands

Generate a standalone executable folder for Windows:

```bash
flutter build windows --release
```

**Output Location:** `build/windows/x64/runner/Release/`

#### 📦 Creating an Installer (Inno Setup)

To create a professional `.exe` installer (like `Setup_ShivaayMusic.exe`):

1.  **Build Release**: Run the build command above.
2.  **Download Inno Setup**: Install [Inno Setup Compiler](https://jrsoftware.org/isinfo.php).
3.  **Create Script**: Open Inno Setup -> New Script Wizard -> Select your `Release` folder.
4.  **Compile**: This will pack everything into a single, compressed Setup file ready for distribution.
    - _Tip: Inno Setup automatically compresses files better than standard Zip._

---

# 📜 Legal & Disclaimer

**ShivaayMusic** is a proprietary project developed by **Shivaay Developer**.

- This software is for **Educational Purposes Only**.
- Content is provided by third-party services (YouTube); we do not host any copyrighted files.
- Not affiliated with Google LLC.

**© 2026 Shivaay Developer. All Rights Reserved.**
