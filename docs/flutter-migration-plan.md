# Flutter migration plan

## Guardrails

- Work only on `migration/flutter` from baseline tag `pre-flutter-migration`.
- Preserve the React Native baseline in Git tag `pre-flutter-migration`, Git
  history, ignored signing files, and local Firebase files.
- Build the new application at the repository root with application/bundle identifier
  `com.sasang.app` and display name `사상`.
- Preserve API contracts and generated map assets; copy assets rather than hand
  editing geometry.

## Implementation sequence

1. Generate the Flutter mobile project and configure identity, theme, assets,
   environment injection, URL scheme, photo permission, AdMob, and portrait mode.
2. Add the domain models, map asset loader, typed API service, image storage, and
   a legacy-compatible state repository.
3. Import Zustand JSON and legacy image locations idempotently. Keep migration
   markers and source data so an interrupted update is recoverable.
4. Recreate startup consent, the floating Map/Places/More navigation shell, info
   pages, and Map Store.
5. Recreate vector map rendering, MultiPolygon paths, hit testing, pan/pinch/zoom,
   search, selection, image clipping, and photo-date confirmation.
6. Recreate Places sorting/photo management and More profile/logout/reset flows.
7. Initialize AdMob with test IDs in debug and production IDs in release. Add
   custom-scheme intake without inventing new remote universal-link hosts.
8. Add unit/widget tests for path parsing, photo dates, legacy Zustand migration,
   session persistence, route behavior, and map mode/selection.
9. Run formatting, `flutter pub get`, `flutter analyze`, tests, debug execution
   where a simulator/device is available, Android app bundle, and unsigned iOS
   release build. Classify signing/device failures separately from code failures.
10. Record parity gaps and a human release checklist. The React Native source is
    retained in Git history and the `pre-flutter-migration` tag for rollback.

## Explicit non-goals for this branch

- No new backend authentication, Firebase feature, push system, social login, or
  purchase flow.
- No API redesign and no map-data regeneration.
- No deletion or modification of signing material.
- No merge, force push, store submission, or production Firebase project change.
