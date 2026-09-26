# Sasang (사상)

Sasang is a Flutter mobile app for attaching travel photos to administrative
regions. Region boundaries are lightweight vector paths, and photos are clipped
inside those paths while the original image remains unchanged.

## Mobile app

The Flutter project lives directly at the repository root:

```text
lib/       Flutter application code
android/   Android host project (`com.sasang.app`)
ios/       iOS host project (`com.sasang.app`)
assets/    map paths, app images, and fonts
test/      migration and domain tests
```

Run the app with Flutter 3.35.3 stable or a compatible newer stable release:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

The API base URL is supplied at build time:

```sh
flutter run --dart-define=API_URL=http://localhost:3000
```

Release verification commands:

```sh
flutter build appbundle --release
flutter build ios --release --no-codesign
```

The Android release configuration currently falls back to debug signing. Before
a store update, connect the existing ignored production keystore and confirm its
certificate. The iOS archive must use the existing Apple team, distribution
certificate, provisioning profile, and a build number above the live version.

## Supporting projects

- `backend/`: Next.js API server
- `packages/shared/`: shared API contracts
- `scripts/map-data/`: deterministic administrative-map preprocessing
- `docs/`: architecture and migration verification notes

## Existing-user compatibility

The Flutter app keeps `com.sasang.app` and imports the prior Zustand JSON files
and copied images under `Documents/sasang/`. See
[`docs/flutter-migration-validation.md`](docs/flutter-migration-validation.md)
before preparing a store release.

The React Native/Expo baseline is preserved in Git history and tag
`pre-flutter-migration`; it is intentionally absent from this migration branch.
