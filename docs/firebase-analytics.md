# Firebase Analytics (legacy reference)

The React Native baseline contains an optional Firebase Analytics integration.
The current Flutter app does not enable Firebase because the checked-in React
Native configuration disabled it and no active Firebase behavior was found.

Required project files are not committed because they are Firebase project
specific:

- `ios/Runner/GoogleService-Info.plist`
- `android/app/google-services.json`

Do not copy or commit these project-specific files until Firebase is deliberately
enabled for Flutter. Reuse the existing Firebase project and identifiers; never
create or switch projects as part of routine app setup.

Legacy event names to preserve if Analytics is re-enabled:

- screen views for login, map, places, more, and info pages
- local start button press
- region photo save/remove
- region search selection
- profile name/image updates
- AdMob placeholder dismissal
