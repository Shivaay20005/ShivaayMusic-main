# Release flow — end to end

This is the single place that explains **what happens after a push**, **where
every file is built**, **where every file is uploaded**, and **how an installed
app finds out that a new version exists**.

Quick start / one-time token setup: [`RELEASE_AUTOMATION.md`](RELEASE_AUTOMATION.md).

---

## 1. TL;DR

| You do | CI does | Result |
| --- | --- | --- |
| `git push origin main` | Android + Windows workflows build and publish | Tag `v1.0.8`, release with APKs/AAB/EXE/ZIP, mirrored tag `1.0.8` in the legacy repos |
| Push any other branch | Same builds, **nothing is published** | Only Actions artifacts (30 days) |
| `git push origin v1.0.8` (new tag) | Same builds, publishes that exact commit | Tag must match `pubspec.yaml` or the job fails |
| Actions → *Run workflow* + `publish_release` | Publishes the selected branch | Used for re-publishing |

---

## 2. Version numbers — one source of truth

`pubspec.yaml` → `version: 1.0.8+13` is the source. CI reads it and derives:

- `name` = `1.0.8`
- `build` = `13`
- `tag` = `v1.0.8` (build repo) and `1.0.8` (legacy repos, no `v`)

Everything else is kept in sync manually when bumping:

| File | What it holds |
| --- | --- |
| `pubspec.yaml` | `version: 1.0.8+13` (Android `versionName`/`versionCode` come from here) |
| `lib/main.dart` | `_appBuildLabel = 'Version 1.0.8 • Build 13'` |
| `lib/ui/screens/Settings/settings_screen_controller.dart` | `V1.0.8` fallback used by the update checker |
| `windows/runner/Runner.rc` | `1,0,8,13` and `"1.0.8.13"` (EXE file version) |
| `windows/packaging/exe/inno_setup.iss` | `AppVersion=1.0.8` (installer) |
| `LICENSE` | `VERSION 1.0.8` |
| `CHANGELOG.txt` | New `#N Release - 1.0.8 - <date>` section |

> `android/app/build.gradle` reads `flutter.versionName` / `flutter.versionCode`
> from `pubspec.yaml`, so no Android file needs editing.

---

## 3. The flow, step by step

```
git push origin main
│
├─► [A] "Build Android APK & Release"   .github/workflows/code_quality.yml
│    1. checkout (fetch-depth 0)  +  JDK 17  +  Flutter stable
│    2. "Read app version"        pubspec.yaml ──► name / build / tag
│    3. flutter pub get
│    4. flutter analyze           (any error stops the job, nothing is published)
│    5. flutter build apk --release
│       flutter build apk --release --split-per-abi
│       flutter build appbundle --release
│    6. copy outputs to release-apks/  +  write SHA256SUMS
│    7. upload Actions artifact  "ShivaayMusic-v1.0.8-android"
│    8. "Decide whether to publish a Release"
│         branch == default branch  -> publish
│         tag push == v1.0.8        -> publish (tag must match pubspec)
│         manual + checkbox         -> publish
│         existing v1.0.8 tag on a branch push -> skip (never move a tag)
│    9. create tag v1.0.8 + GitHub Release "ShivaayMusic 1.0.8"
│       in Shivaay20005/ShivaayMusic-main, attach every file from release-apks/
│   10. mirror tag 1.0.8 + release + same files to Shivaay20005/ShivaayMusic
│       (skipped with a warning when RELEASE_SYNC_TOKEN is missing)
│
└─► [B] "Build Windows EXE & Installer"  .github/workflows/win_exe.yml
     1. checkout + Flutter + CMake/Ninja + symlink support
     2. "Read app version"          (same derivation as Android)
     3. flutter pub get + dart localization/generator.dart
     4. pre-extract audiotags native binaries (CMake cannot untar through
        .plugin_symlinks)
     5. flutter build windows
     6. Inno Setup installer + portable ZIP + SHA256SUMS
     7. upload Actions artifact "ShivaayMusic-v1.0.8-windows"
     8. wait up to 10 min for the Android job to create release v1.0.8,
        then upload the installer/ZIP/checksums to that same release
        (if Android failed, Windows creates the release itself)
     9. mirror tag 1.0.8 + release + files to
        Shivaay20005/ShivaayMusic-Windows-release
```

Both jobs run in parallel; the Windows job only waits at step 8, so the slow
Windows build overlaps with the Android build.

---

## 4. Where every file is built and where it is uploaded

### Android — `code_quality.yml`

| Built at | Final name in `release-apks/` | Uploaded to |
| --- | --- | --- |
| `build/app/outputs/flutter-apk/app-release.apk` | `ShivaayMusic-v1.0.8-Android-Universal.apk` | release + artifact + legacy repo |
| `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` | `ShivaayMusic-v1.0.8-Android-arm64-v8a.apk` | release + artifact + legacy repo |
| `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` | `ShivaayMusic-v1.0.8-Android-armeabi-v7a.apk` | release + artifact + legacy repo |
| `build/app/outputs/flutter-apk/app-x86_64-release.apk` | `ShivaayMusic-v1.0.8-Android-x86_64.apk` | release + artifact + legacy repo |
| `build/app/outputs/bundle/release/app-release.aab` | `ShivaayMusic-v1.0.8-Android.aab` | release + artifact + legacy repo |
| generated in `release-apks/` | `ShivaayMusic-v1.0.8-SHA256SUMS-Android.txt` | release + artifact + legacy repo |

> Flutter's `CopyFlutterApksTask` always renames the Gradle output to
> `app-release.apk` / `app-<abi>-release.apk` inside `build/app/outputs/flutter-apk/`,
> even though `android/app/build.gradle` sets a custom `outputFileName`.
> The CI paths above are therefore the stable ones.

### Windows — `win_exe.yml`

| Built at | Final name in `windows-release/` | Uploaded to |
| --- | --- | --- |
| `build/windows/x64/runner/Release/*` (zipped) | `ShivaayMusic-v1.0.8-Windows-Portable.zip` | release + artifact + Windows legacy repo |
| `windows/packaging/exe/shivaaymusic.exe` (Inno Setup output, moved) | `ShivaayMusic-v1.0.8-Windows-Setup.exe` | release + artifact + Windows legacy repo |
| generated in `windows-release/` | `ShivaayMusic-v1.0.8-SHA256SUMS-Windows.txt` | release + artifact + Windows legacy repo |
| `windows-build.log` | `windows-build-log-<run_id>` | Actions artifact only (7 days) |

### Actions artifacts (temporary, 30 days)

- `ShivaayMusic-v1.0.8-android` → all Android files
- `ShivaayMusic-v1.0.8-windows` → all Windows files

Artifacts are only for debugging/backup. **Users download from Releases, not
from artifacts.**

---

## 5. The three repositories

| Repository | Role | Tag format | Who reads it |
| --- | --- | --- | --- |
| `Shivaay20005/ShivaayMusic-main` | Source + build repo. Workflows live here. | `v1.0.8` | New app versions (1.0.8+) |
| `Shivaay20005/ShivaayMusic` | Legacy **Android download** repo (no source) | `1.0.8` | **Every installed copy up to 1.0.7** |
| `Shivaay20005/ShivaayMusic-Windows-release` | Legacy **Windows download** repo (no source) | `1.0.8` | Installed Windows copies |

The legacy repos only need a tag + release with assets; the workflow creates
them with `gh release create/upload`. That is why the PAT is required:
`GITHUB_TOKEN` can only write to the repo that runs the workflow.

### Branch model

| Branch | Role |
| --- | --- |
| `main` | **Default branch.** Latest code. A push here publishes a release. |
| `version1.0.6` | Previous working branch, kept for history. Pushing here does not publish, because the workflow compares against the repository's default branch. |

---

## 6. How an installed app learns about 1.0.8

```
App start
  └─ HomeScreenController._checkNewVersion()          (if updateCheckFlag)
       └─ helper.newVersionCheck(currentVersion)
            ├─ GET /repos/Shivaay20005/ShivaayMusic/releases/latest
            ├─ GET /repos/Shivaay20005/ShivaayMusic-main/releases/latest
            ├─ (Windows only) .../ShivaayMusic-Windows-release/releases/latest
            ├─ fallback: GET /tags?per_page=100, highest semver wins
            └─ isVersionNewer(current, newest)
                 └─ true → NewVersionDialog
                      └─ button → latestReleaseUrl
                           Android: .../ShivaayMusic/releases/latest
                           Windows: .../ShivaayMusic-Windows-release/releases/latest
```

Old **1.0.7** builds use the old code path: they read
`https://api.github.com/repos/Shivaay20005/ShivaayMusic/tags`, take `tags[0]`
and compare it with `V1.0.7`. They do **not** know about
`ShivaayMusic-main`. Consequences:

- The mirrored tag **must** be named `1.0.8` (no `v`) and must be the newest
  created tag in that repo — the mirror step handles this.
- If `RELEASE_SYNC_TOKEN` is missing, 1.0.7 users are **not** notified even
  though the build repo has the release.

---

## 7. Releasing a new version (the normal way)

```bash
# 1. bump the version in every place listed in section 2
#    (pubspec.yaml is what CI reads; the rest is what users see)

# 2. add a CHANGELOG.txt entry

# 3. commit and push to the default branch
git add -A
git commit -m "release: 1.0.9 (build 14)"
git push origin main
```

Do **not** create tags or releases by hand — CI does both. Pushing a tag that
does not match `pubspec.yaml` fails the "Decide whether to publish" step on
purpose.

### Re-publishing the current version

`action-gh-release` is safe to re-run; it updates the release and overwrites
assets. The branch push path intentionally skips publishing when the tag
already exists, so use one of these:

```bash
# Option A: delete the tag (the release and its assets stay), then dispatch
#           both workflows with publish_release = true from the Actions UI/API.
gh api -X DELETE repos/Shivaay20005/ShivaayMusic-main/git/refs/tags/v1.0.8
gh workflow run code_quality.yml  -f publish_release=true --repo Shivaay20005/ShivaayMusic-main
gh workflow run win_exe.yml        -f publish_release=true --repo Shivaay20005/ShivaayMusic-main

# Option B: re-create the tag on the commit you want to ship
git tag -f v1.0.8 <commit>
git push origin :refs/tags/v1.0.8
git push origin v1.0.8
```

### Forcing only the legacy mirror

The mirror step runs only when `publish == true`. To refresh the legacy repos
without rebuilding, run the **Mirror release to download repositories**
workflow (`.github/workflows/mirror_release.yml`). It copies the assets of an
existing release into both download repos, splits them by platform, and marks
the mirrored release as *Latest* — no APK/EXE rebuild, takes about a minute.

```bash
# Actions → Mirror release to download repositories → Run workflow
#   version     = 1.0.8            (empty = read pubspec.yaml)
#   source_repo = Shivaay20005/ShivaayMusic-main

# Same thing from the CLI:
gh workflow run mirror_release.yml \
  --repo Shivaay20005/ShivaayMusic-main \
  -f version=1.0.8
```

Use it when:

- the Windows build failed after Android already published,
- `RELEASE_SYNC_TOKEN` was missing on the first run,
- a mirrored release/tag was deleted by accident,
- you need the *Latest* badge to move to the new version.

The workflow only mirrors what exists: if the release has no `*Windows*` assets
it prints a warning and leaves the Windows download repo untouched, so you never
end up with an empty Windows release.

If you prefer doing it by hand:

```bash
VERSION=1.0.8
gh release create "$VERSION" --repo Shivaay20005/ShivaayMusic \
  --title "ShivaayMusic v$VERSION" --notes "Automatic mirror" --latest \
  <files from the build repo release>
```

---

## 8. One-time secret: `RELEASE_SYNC_TOKEN`

GitHub → repo `Shivaay20005/ShivaayMusic-main` → **Settings → Secrets and
variables → Actions → New repository secret**.

- Name: `RELEASE_SYNC_TOKEN`
- Value: a PAT that can write to **both** legacy repos
  - Classic token: scopes `repo` (+ `workflow` if it will ever push workflow
    files)
  - Fine-grained token: *Contents: Read and write* on
    `Shivaay20005/ShivaayMusic` and
    `Shivaay20005/ShivaayMusic-Windows-release`

Without it the build still succeeds; the mirror steps print
`Legacy release sync skipped` and old installs get no notification.

---

## 9. Failure playbook

| Symptom | Cause | Fix |
| --- | --- | --- |
| `flutter analyze` error annotation | Compile/lint error | Fix code; nothing was published |
| `Tag v1.0.8 already exists` message, job green | Version not bumped | Bump `pubspec.yaml`; or re-publish with section 7 |
| `Tag v1.0.9 does not match pubspec version v1.0.8` | Tag pushed by hand | Push the matching tag or delete it |
| `Legacy release sync skipped` warning | `RELEASE_SYNC_TOKEN` missing/invalid | Add the secret, then re-run (section 7) |
| Windows job hangs ~10 min before uploading | Waiting for the Android release | Normal; if Android failed, Windows creates the release alone |
| Release has APKs but no EXE/ZIP | Windows job failed | Open the Windows run, check `windows-build-log-<id>` artifact |
| Release has EXE/ZIP but no APKs | Android job failed | Fix Android first, then re-publish |
| Old 1.0.7 users see no dialog | Legacy tag missing/not newest | Check `.../ShivaayMusic/tags`; run the mirror again |

---

## 10. Release 1.0.8 checklist (current)

- [x] Version `1.0.8+13` in every file from section 2
- [x] `CHANGELOG.txt` entry `#29`
- [x] Android workflow builds universal + 3 ABI APKs + AAB + checksums
- [x] Auto tag `v1.0.8` + release on default-branch push
- [x] Windows workflow attaches installer + portable ZIP
- [x] Legacy mirror steps for both download repos
- [x] `RELEASE_SYNC_TOKEN` secret added (required for old-version notification)
- [ ] First successful run of both workflows on `main`

---

## 11. File map

| File | Purpose |
| --- | --- |
| `.github/workflows/code_quality.yml` | Android analyze/build/tag/release/mirror |
| `.github/workflows/win_exe.yml` | Windows build/installer/release/mirror |
| `.github/workflows/mirror_release.yml` | Re-mirror an existing release into the download repos (no rebuild) |
| `pubspec.yaml` | Version source of truth + dependencies |
| `lib/utils/helper.dart` | `newVersionCheck()`, `isVersionNewer()`, release URLs |
| `lib/ui/screens/Home/home_screen_controller.dart` | Startup update dialog |
| `lib/utils/update_check_flag_file.dart` | `updateCheckFlag` kill-switch for F-Droid builds |
| `windows/packaging/exe/inno_setup.iss` | Installer definition + `AppVersion` |
| `windows/runner/Runner.rc` | Windows EXE version resource |
| `android/app/build.gradle` | Reads version from pubspec, signing config |
| `RELEASE_AUTOMATION.md` | Short "what runs when" + token setup |
| `RELEASE_FLOW.md` | This document |
