# Flutter migration validation

Date: 2026-09-28

Branch: `migration/flutter`

React Native baseline: `pre-flutter-migration` (`d850547`)

## Completed migration scope

- Standard Flutter Android/iOS project at the repository root. The superseded
  React Native `app/` tree is removed from this branch and preserved in the
  `pre-flutter-migration` tag and Git history.
- Existing production identity (`com.sasang.app`), Korean display name, Sasang
  custom schemes, portrait behavior, photo-library description, app icon,
  splash, and AdMob app/unit IDs.
- Local consent session and logout behavior.
- Apple-style visual system using Cupertino controls, iOS page transitions,
  restrained neutral surfaces, thin separators, glass-like overlays, and native
  confirmation/date interactions instead of default Material components.
- Floating Map/Places/More navigation and Android back-to-Map behavior.
- Korea/world generated vector assets, Polygon/MultiPolygon rendering, region
  search and selection, pan/pinch/zoom/reset, photo clipping, and transform
  metadata rendering.
- Aspect-correct map rendering and hit testing, zoom-independent selected-region
  borders, safe-area-aligned bottom controls, explicit photo-add icon colors,
  a compact record-count summary, and restrained search typography without the
  decorative brand image.
- Map overlays use unclipped two-layer shadows, stronger hairline borders, and
  more opaque glass surfaces; the search field retains a 46 px touch height and
  zoom controls sit closer to the lower contextual control.
- Places filter controls, empty state, and record cards share the same subtle
  two-layer elevation treatment for consistent surface separation.
- Photo selection, EXIF date lookup, date confirmation, device-local copy,
  replacement, and deletion of region associations.
- Places filtering, sorting, photo management, and the original compact
  filter/card-based empty-state hierarchy.
- Privacy/terms/app information, local-data reset, and coming-soon Map Store.
- Typed API client using `API_URL` supplied through `--dart-define`.
- AdMob initialization with Google test units in debug and existing production
  units in release.
- `sasang://map`, `/places`, `/more`, `/map-store`, and `/info/{type}` routing.
- Cold-start and warm custom-scheme routing, including direct Map Store launch.
- Map Store country-outline previews, lock badges, product count, and explicit
  sheet close control matching the React Native reference hierarchy.
- Illustrated owned-map Bottom Sheet with Korea/world vector previews, selected
  card treatment, explicit close control, and Map Store entry matching the
  React Native iOS-style hierarchy.

## Existing-user data migration

The Flutter implementation reads and writes the existing Zustand JSON envelope
(`state` plus `version: 0`) under `Documents/sasang/state`. It probes the Flutter
documents root, application-support root, and the Expo-style Android files root.
No legacy state is deleted during import.

Stored photo/profile URIs are repaired using the stable suffix after `/sasang/`,
matching the RN resolver's sandbox-container migration behavior. A
`flutter-migration-v1.json` marker records successful initialization. An iOS
Simulator that already contained `com.sasang.app` state entered the tab shell
without showing the first-run consent screen, confirming session compatibility
in that environment.

There are no access/refresh tokens, AsyncStorage records, secure-storage values,
SQLite databases, Firebase Auth sessions, or push tokens in the current RN app,
so no migration exists for those absent data classes.

## Verification results

| Check | Result |
| --- | --- |
| `flutter pub get` | Pass |
| `flutter analyze` | Pass, zero issues |
| `flutter test` | Pass, 12 tests |
| iOS Simulator debug build/install/launch | Pass, iPhone 17 Pro / iOS 26.4 |
| Android release AAB | Pass, 50.7 MB, `1.0.3` (`versionCode 23`) |
| Android release signing | Pass; AAB signer matches the recovered EAS upload certificate |
| iOS release build | Pass from repository root, unsigned `Runner.app`, 32.5 MB |
| Physical Android device | Not available |
| Physical iOS device | Not available |
| Play upload-ready candidate | Pass; Play Console acceptance still requires Internal testing upload |
| App Store upload-ready IPA | Blocked; no Apple Distribution identity is installed locally |

Tests cover legacy Zustand decoding, RN/EXIF date formats, map asset decoding,
MultiPolygon preservation, photo transform persistence, and the illustrated
owned-map selector structure. UI regressions cover the Places filter/icon-free
empty state, the simplified map top bar and search typography, and removal of
profile controls from More.

## Intentional or remaining differences

- RN profile selection requested the platform's square edit UI. Flutter keeps
  previously stored profile values only for update compatibility. Profile
  controls are intentionally no longer shown in More.
- The current RN app stores scale/offset fields but has no photo-position editor.
  Flutter preserves and renders those fields but likewise does not add an editor.
- Firebase files are ignored locally but Firebase is explicitly disabled in RN.
  Flutter does not enable Firebase, Firebase Auth, Analytics, or push.
- Map Store purchases remain disabled/coming soon because RN has no active IAP.
- No verified Universal Link/App Link host exists in RN. Flutter preserves custom
  schemes only; adding Associated Domains or an `https` host requires an approved
  domain and hosted association files.
- Analytics remains effectively absent. RN calls a no-op analytics stub; Flutter
  does not invent a replacement event backend.

## Store-update blockers and manual checklist

- [ ] Confirm the live Play application ID and App Store bundle ID are exactly
      `com.sasang.app` in their consoles.
- [x] Set the candidate to `1.0.3+23`, above Play versionCode 22 and App Store
      build 18 reported for the live `1.0.2` release.
- [x] Recover the existing EAS-managed Play upload keystore and connect release
      signing locally without committing the key or passwords.
- [ ] Configure the existing Apple development team, distribution certificate,
      provisioning profile, and App Store signing. Rebuild without
      `--no-codesign` and archive through Xcode/CI.
- [ ] Install the production-signed RN version on physical iOS and Android
      devices, create session/profile/Korea/world photo data, update in place to
      the Flutter candidate, and compare every record and image.
- [ ] Verify photo permission denied/limited/full flows, large HEIC/JPEG images,
      EXIF/no-EXIF dates, app termination during copy, and low-storage failures.
- [ ] Exercise Korea/world region taps, island MultiPolygons, search, pinch/pan,
      Android system back, and iOS swipe-back behavior.
- [ ] Test every custom-scheme URL while the app is cold and warm. Decide whether
      verified web links are required before adding native entitlements/filters.
- [ ] Validate production AdMob consent/privacy requirements, live units, and
      store privacy disclosures. Debug builds already use test ads.
- [ ] Confirm that Firebase and push are genuinely not present in the live binary;
      if the store version differs from this repository, inventory the production
      native project before release.
- [ ] Review privacy policy and terms copy; both RN and Flutter currently state
      that final documents will be supplied before distribution.
- [ ] Run accessibility, Dynamic Type/text scaling, Korean localization, offline,
      background/foreground, and crash monitoring checks on physical devices.
- [ ] Confirm the `pre-flutter-migration` tag is available on the remote before
      release so the React Native source remains an explicit rollback point.

## React Native cleanup

The tracked Expo application, Expo configuration, and Expo-only assets were
removed after the Flutter implementation became independently runnable. Backend,
shared contracts, map preprocessing, migration notes, signing configuration, and
Git history were retained. The deletion is isolated to `migration/flutter`.
Ignored local Firebase configuration files were moved to
`.local/legacy-native-config/` before deleting local Expo build artifacts; the
directory is not committed and no credential or project setting was altered.
