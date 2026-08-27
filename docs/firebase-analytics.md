# Firebase Analytics

Sasang uses React Native Firebase Analytics for native iOS and Android event
collection.

Required project files are not committed because they are Firebase project
specific:

- `app/GoogleService-Info.plist`
- `app/google-services.json`

After creating iOS and Android apps in the Firebase console, download those two
files into the paths above. `app/app.config.js` only enables the React Native
Firebase config plugins when both files exist, so local Expo startup is not
blocked before Firebase setup is ready.

React Native Firebase uses custom native code, so Analytics runs in an Expo
development build or EAS build, not Expo Go.

Tracked events currently include:

- screen views for login, map, places, more, and info pages
- local start button press
- region photo save/remove
- region search selection
- profile name/image updates
- AdMob placeholder dismissal
