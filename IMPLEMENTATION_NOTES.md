# ShivaayMusic v1.0.8 implementation notes

> Release automation, tagging, and update-notification setup are documented in
> [`RELEASE_AUTOMATION.md`](RELEASE_AUTOMATION.md). The complete build →
> release → mirror → in-app notification flow (with every artifact path and
> upload destination) is in [`RELEASE_FLOW.md`](RELEASE_FLOW.md).

## What was changed

The uploaded Flutter source has been updated in-place with a contrast-safe theme foundation, a single auth gate, deferred cloud restore, account-isolated local data, richer search discovery, artist-favourite sync, listening statistics, a default-off video option, and a more useful home continuation feed.

The light and dark theme changes remove the most visible fixed translucent surfaces and make dynamic themes use a darkened background with explicit foreground colours. The settings cards, player action buttons, bottom navigation, login indicators, and search category chips now derive their contrast from the active theme instead of relying on white-on-white or low-alpha defaults.

The authentication flow now lets the root widget decide whether Login or Home is rendered. The login and signup screens no longer replace the root route after success. Firebase's persisted session gets a short cold-start window before Login is shown, which avoids a false login flash after the app is removed from recents. Firestore sync and restore run after Home is mounted and are not allowed to block the first authenticated frame.

The local data layer now tracks the active Firebase UID. When a different account is detected, account-owned Hive boxes are cleared before cloud restoration, preventing favourites, history, followed artists, playlists, or statistics from appearing under the wrong account.

The Player and Audio settings page now includes “Show video option in player”, defaulting to off. When disabled, the Song/Video switch is hidden and an active video mode is stopped safely. Search now includes mood shortcuts plus language/style shortcuts such as Hindi, Punjabi, Bhojpuri, Tamil, Telugu, Malayalam, Bollywood, Indie, Classical, New releases, and Trending songs. The existing artist library remains active, and artist follow/unfollow now syncs to the signed-in user's cloud data.

A Listening Stats page is now available from Settings. It reads the existing local listening analytics, displays 30-day listening time, active days, and top track IDs, and uses the same user-scoped cloud persistence path. Recent history and listening statistics are pushed non-blockingly after playback changes.

## Firebase and Firestore changes

The Firestore rules now declare Rules version 2. New listening statistics are stored under `users/{uid}/listening_stats/{date}`, artist favourites under `users/{uid}/data/artist_favourites`, and existing settings, favourites, history, search history, and playlists remain under the owner-protected `users/{uid}` tree. Legacy top-level statistics are no longer writable by arbitrary authenticated users.

The settings sync includes the corrected playback restore key and the new video visibility preference. The misspelled legacy key `restrorePlaybackSession` is migrated for backward compatibility. Hive access in the theme controller is normalized to the actual `AppPrefs` box name.

## Firebase configuration note

The Firebase Console screenshot supplied for this project shows SHA-1 `D9:22:B2:07:A7:ED:E7:03:A8:A5:05:F5:9A:6B:78:C8:99:18:15:B3`, which matches the certificate hash `d922b207a7ede703a8a505f59a6b78c8991815b3` in `android/app/google-services.json`. The app configuration is therefore consistent. The old B8:27... and BA:C4... values were stale documentation and have been corrected in `FIREBASE_SETUP.txt`.

If a different signing key is used for another build variant, register that key's SHA-1 separately in Firebase Console and Google Cloud Console. The Dart code uses the type-3 OAuth client present in the checked-in JSON.

## Validation status

The sandbox did not contain the Flutter or Dart executable, so `flutter analyze`, `flutter test`, and an Android build could not be run here. A repeatable static checker was run over all changed Dart files: braces, parentheses, and brackets are balanced; duplicate imports were not found in the checked files; stale `appPrefs` access, manual Home route replacement, and the old root `StreamBuilder<User?>` pattern were not found.

Run the following commands on a machine with Flutter installed:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

For device verification, test a cold start with an existing Firebase session, remove the app from recents and reopen it, sign in with Google from a fresh install, switch between light/dark themes, turn the video option on and off, follow an artist, play several songs, sign out, sign in as another account, and confirm that the correct cloud-restored library and statistics appear.
