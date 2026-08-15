# ShivaayMusic implementation audit

## Confirmed startup and authentication risks

1. `main.dart` wraps the app in both a GetX observer and a new `FirebaseAuth.instance.authStateChanges()` `StreamBuilder`, while `login_screen.dart` and `signup_screen.dart` also call `Get.offAll(() => const Home())` after authentication. This creates competing route owners and can produce a blank/black first frame after Google returns. The root auth gate should be the only owner of Login/Home routing; auth screens should only await the result and show feedback.
2. `AuthService.isInitializing` is never set to a real startup state. Firebase initialization is caught and ignored, and the first UI can be built before auth and Hive state are fully coordinated. A single startup gate with a short, non-blocking loading state is safer.
3. `auth_service.dart` performs Firestore writes and delayed restore work from the auth-state listener. These operations must not block route rendering. Restore should be cancellable/guarded by the current UID and run after Home is mounted.
4. Native Google sign-in uses server client ID `468199347944-u8k8m980b3u9vrun3cb038k1ph36rt8s.apps.googleusercontent.com`, which matches the type-3 client in `android/app/google-services.json`. The Firebase Console screenshot supplied for this project shows SHA-1 `D9:22:B2:07:A7:ED:E7:03:A8:A5:05:F5:9A:6B:78:C8:99:18:15:B3`, which matches the JSON certificate hash `d922b207a7ede703a8a505f59a6b78c8991815b3`. The old B8:27... and BA:C4... values were stale documentation, not a current Firebase configuration mismatch.

## Confirmed persistence and Firestore risks

5. Hive box casing is inconsistent. `main.dart` opens `AppPrefs`, but `theme_controller.dart` reads/writes `appPrefs`. Hive box names are case-sensitive; this can cause an initialization exception or theme state loss. All references should use `AppPrefs`.
6. Playback restore uses the misspelled key `restrorePlaybackSession` in both settings and player code. Preserve a migration from the old key, then use a corrected canonical key for new installs.
7. `cloud_service.dart` syncs settings, history, playlists, favourites, and search history under `users/{uid}/data/*` plus `users/{uid}/playlists/*`, but it does not sync `ListeningStats`, artist favourites, video visibility, or several newer settings. History is stored with an incorrect single-document strategy for an unbounded list and can hit the Firestore 1 MiB document limit. The implementation should cap/chunk data and include stats/artist preferences.
8. Current Firestore rules allow any owner to read/write every document and subcollection below `users/{userId}`, including arbitrary fields. That is functional but broad. Stats currently use top-level `/stats/*` where authenticated users can create but cannot read their own data, which prevents cross-device stats restore. User-owned stats and preference documents should be nested below `/users/{uid}` and protected with owner checks.
9. The user-data sync methods can call `Hive.openBox` repeatedly and restore settings by calling `SettingsScreenController.onInit()` directly. Restore should be serialized and should update observable state through a dedicated refresh method instead of invoking a lifecycle hook manually.

## Existing feature inventory

The project already contains GetX controllers and Hive stores for songs, playlists, albums, artists, listening history, player session, and search history. It also has a standard player, a video mode, a settings page, and artist library support. The enhancement can therefore be implemented incrementally rather than replacing the app architecture.

## Tooling constraint

The sandbox does not contain `flutter` or `dart`, so final validation must use static checks available in the environment and the user should run `flutter pub get`, `flutter analyze`, and an Android debug build locally or in CI.
