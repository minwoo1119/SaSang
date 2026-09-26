# Sasang Flutter app

This directory contains the Flutter migration of the Sasang mobile app. The
React Native production reference remains in `../app/` during parity testing.

## Requirements

- Flutter 3.35.3 stable or a compatible newer stable release
- Xcode/CocoaPods for iOS
- Android SDK/JDK for Android

## Run and verify

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

The API base URL is supplied at build time and defaults to the same local URL as
the React Native app:

```sh
flutter run --dart-define=API_URL=http://localhost:3000
```

Release code verification:

```sh
flutter build appbundle --release
flutter build ios --release --no-codesign
```

The generated Android build currently falls back to the debug signing config.
Before a Play update, connect the existing production keystore using a local
ignored `android/key.properties` and verify its certificate matches the current
Play application. iOS release archives must use the existing team, distribution
certificate, provisioning profile, and a build number higher than the live app.

## Upgrade compatibility

The Flutter app keeps `com.sasang.app` on both platforms and reads the legacy
Zustand files below without deleting them:

- `Documents/sasang/state/sasang-local-session.json`
- `Documents/sasang/state/sasang-profile.json`
- `Documents/sasang/state/sasang-map-ui.json`
- `Documents/sasang/photos/`
- `Documents/sasang/profile/`

See `../docs/flutter-migration-analysis.md` and
`../docs/flutter-migration-validation.md` before preparing a store release.
