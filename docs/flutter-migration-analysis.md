# Flutter migration analysis

Baseline: `d850547` (`pre-flutter-migration`)

This document records the React Native behavior that the Flutter application must
preserve. The React Native application remains in `app/` until parity and store
upgrade testing are complete.

## Application structure and navigation

- Expo Router starts at `app/src/app/index.tsx`.
- A persisted `hasStarted` flag selects either the local-consent start screen or
  the three-tab shell.
- The tab shell contains Map (`/map`), Places (`/places`), and More (`/more`).
- Stack routes outside the tabs are Map Store (`/map-store`) and information
  detail (`/info/[type]`).
- Android and iOS use the same route graph. Android uses Lucide icons while iOS
  primarily uses SF Symbols.

## Major screens and UI

- Start: app icon, Sasang wordmark, local-photo notice, and a start button.
- Map: Korea/world selector, search, vector region selection, pan/pinch/zoom,
  selected-region actions, photo picker, photo-date confirmation, clipped photo
  fills, and an AdMob sheet.
- Places: recorded-photo feed, Korea/world filter, date sorting, replacement and
  deletion actions, and an empty state.
- More: local profile name/photo editing, Map Store, privacy/terms/app pages,
  logout, and destructive local-data reset.
- Map Store: six coming-soon country products. No purchase flow is active.
- Visual system: neutral `#FAFAFA` surface, white cards, `#007AFF` accent,
  rounded floating controls, restrained borders/shadows, and Korean copy.

## State and persistence

Zustand with its JSON persist middleware owns three stores:

| Legacy key | Contents | Legacy file |
| --- | --- | --- |
| `sasang-local-session` | `hasStarted` | `Documents/sasang/state/sasang-local-session.json` |
| `sasang-profile` | `name`, `profileImageUri` | `Documents/sasang/state/sasang-profile.json` |
| `sasang-map-ui` | `regionPhotos` only | `Documents/sasang/state/sasang-map-ui.json` |

The persisted Zustand shape is `{ "state": ..., "version": 0 }`. Map mode and
selected region are intentionally not persisted.

Selected images are copied to `Documents/sasang/photos/`; the profile image is
copied to `Documents/sasang/profile/`. Stored `file://` URIs can contain an old
application-container prefix. The RN resolver deliberately keeps the path after
`/sasang/` and rebuilds it relative to the current documents directory.

There is no AsyncStorage, SQLite, Secure Storage, Keychain credential, access
token, refresh token, or local database in the current code.

## API and authentication

- `apiRequest` is a small `fetch` wrapper based on `EXPO_PUBLIC_API_URL`, with a
  localhost fallback. No current screen calls it.
- There is no backend login. “Login” means accepting the local-only photo notice.
- Logout clears only the session flag. Travel records and profile data remain.
- “Data clear and logout” clears all three persisted states. The current RN code
  does not remove copied image files, so Flutter must not silently promise or
  perform a broader deletion during compatibility migration.
- No OAuth or social-login provider is present.

## Platform integrations

- App identity: Android application ID and iOS bundle ID are both
  `com.sasang.app`.
- Display name is `사상`; custom URL schemes are `sasang` and
  `com.sasang.app`. The generated Expo development scheme `exp+sasang` is not a
  production requirement.
- iOS declares photo-library access and local-network access for the Expo
  development client. Production behavior only needs photo-library access.
- No Associated Domains entitlement or Android verified App Link host exists.
- Expo Router can receive custom-scheme links, but the product has no explicit
  business deep-link route contract yet.
- No push-notification package, permission, APNs entitlement, FCM handler, or
  notification-token persistence exists.
- Firebase plist/json files exist only as ignored local files. Firebase is
  explicitly disabled by `hasFirebaseConfig = false`, and no Firebase package is
  installed. Firebase Auth and Analytics are not active. Analytics calls are
  no-op stubs.
- AdMob is active in native builds. App IDs are configured for both platforms;
  home, Places, and More use banner units. Development uses Google's test unit.
- No in-app purchase implementation exists; Map Store products are disabled and
  marked coming soon.
- Native dependencies are generated Expo modules plus image picker, file system,
  linking, gesture handling, Reanimated, SVG, date picker, and Google Mobile Ads.
  There is no project-owned custom native module.
- The checked-in repository does not include generated Android sources. A local,
  ignored generated iOS project was inspected for behavior only. Signing assets
  and keystores remain untouched.

## Map and photo domain

- Korea and world maps are generated JSON vector assets containing a versioned
  view box and SVG path per stable region code.
- Polygon and MultiPolygon are represented in a single path and both must remain
  selectable and clip-capable.
- A region photo stores ID, URI, width, height, scale, offsets, creation time, and
  optional taken date. The current renderer uses centered cover clipping; the
  stored transform fields exist but are not edited by the current UI.
- Image selection reads EXIF date when available and always asks the user to
  confirm a date not later than today.

## Package mapping

| React Native / Expo | Flutter replacement | Purpose |
| --- | --- | --- |
| Expo Router | Flutter Navigator | current route graph and native back behavior |
| Zustand persist | `ChangeNotifier` + JSON files | small local state and exact legacy import |
| TanStack Query | repository/service boundary | no live server-state consumer exists yet |
| `react-native-svg` | Flutter `CustomPainter` + `path_drawing` | paths, hit testing, and image clipping |
| Gesture Handler/Reanimated | Flutter gestures/animations | pan, pinch, modal transitions |
| `expo-image-picker` | `image_picker` | travel/profile photo selection |
| `expo-file-system` | `dart:io` + `path_provider` | local JSON and copied images |
| `expo-image` | Flutter `Image` | asset and file rendering |
| community DateTimePicker | Material/Cupertino date pickers | photo-date confirmation |
| `react-native-google-mobile-ads` | `google_mobile_ads` | AdMob banners |
| `expo-linking` | `app_links` | production custom-scheme intake |
| browser `fetch` | `http` | typed API client transport |

Firebase, push, OAuth, secure storage, SQLite, and IAP packages will not be added
until a real existing feature requires them. This avoids changing production
behavior merely because ignored configuration files are present.

## Compatibility risks

1. Android's Expo and Flutter document-directory roots can differ. Migration must
   probe safe application-owned candidate roots and copy legacy state into the
   Flutter state location without deleting the source.
2. Stored image URIs contain old sandbox-container prefixes. Resolution must use
   the stable suffix after `/sasang/` and probe both Flutter and legacy roots.
3. The same package/bundle identifier is necessary but not sufficient for store
   updates: the existing Android signing key, iOS team/profile, version code, and
   App Store/Play configuration must be supplied by the release owner.
4. Firebase and push behavior cannot be “migrated” because the current app does
   not enable them. Enabling either would be a separate product change.

