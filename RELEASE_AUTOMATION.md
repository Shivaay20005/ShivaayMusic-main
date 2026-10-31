# Release automation

Everything below happens automatically. The only manual work is the one-time
secret setup in step 1.

> Full step-by-step flow, artifact paths, upload destinations, update-check
> behaviour and troubleshooting: [`RELEASE_FLOW.md`](RELEASE_FLOW.md).

## What happens on every push

1. **Push to any branch** → both workflows run `flutter analyze`/build so a
   broken commit is visible immediately, but nothing is published.
2. **Push to the default branch** (`main`) →
   - the version is read from `pubspec.yaml` (currently `1.0.8+13`);
   - the tag `v1.0.8` is created if it does not exist yet;
   - the GitHub Release `ShivaayMusic 1.0.8` is created/updated with:
     - universal APK,
     - `arm64-v8a`, `armeabi-v7a`, `x86_64` APKs,
     - Android App Bundle (`.aab`),
     - SHA-256 checksums;
   - the same tag + release is mirrored to `Shivaay20005/ShivaayMusic` so
     **already-installed copies show the “Update Available!” dialog**;
   - the Windows workflow attaches the installer and portable ZIP to the same
     release and mirrors them to
     `Shivaay20005/ShivaayMusic-Windows-release`.
3. **Pushing a `v1.0.8` tag** publishes that exact commit (the workflow verifies
   the tag matches `pubspec.yaml`).
4. **Manual run** (`workflow_dispatch`) with `publish_release` checked publishes
   the selected branch.

To release a new version, change `version:` in `pubspec.yaml` and push. Do not
create tags or releases by hand.

## One-time setup: `RELEASE_SYNC_TOKEN`

The app that is already installed on users' phones checks the **legacy**
download repositories, not this build repository:

- Android: `Shivaay20005/ShivaayMusic`
- Windows: `Shivaay20005/ShivaayMusic-Windows-release`

GitHub's built-in `GITHUB_TOKEN` can only write to the repository that runs the
workflow, so a Personal Access Token is needed to mirror the tag/release there:

1. Open **GitHub → Settings → Developer settings → Personal access tokens →
   Fine-grained tokens → Generate new token**.
2. Repository access: **Only select repositories** →
   `Shivaay20005/ShivaayMusic` and
   `Shivaay20005/ShivaayMusic-Windows-release`.
3. Repository permissions: **Contents → Read and write**.
4. Copy the token.
5. In `Shivaay20005/ShivaayMusic-main` open **Settings → Secrets and variables →
   Actions → New repository secret**:
   - Name: `RELEASE_SYNC_TOKEN`
   - Value: the token from step 4.

Until the secret exists the build still succeeds; the mirror step only prints a
warning (`Legacy release sync skipped`) and old installs are not notified.

## Version locations kept in sync

| File | Value |
| --- | --- |
| `pubspec.yaml` | `version: 1.0.8+13` |
| `lib/main.dart` | `_appBuildLabel = 'Version 1.0.8 • Build 13'` |
| `lib/ui/screens/Settings/settings_screen_controller.dart` | `V1.0.8` fallback |
| `windows/runner/Runner.rc` | `1,0,8,13` / `"1.0.8.13"` |
| `windows/packaging/exe/inno_setup.iss` | `AppVersion=1.0.8` |
| `LICENSE` | `VERSION 1.0.8` |

`android/app/build.gradle` reads `versionName`/`versionCode` from `pubspec.yaml`,
so no Android-specific edit is required.
