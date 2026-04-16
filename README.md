# flutter_enchance

Flutter app configured with Firebase using FlutterFire.

## Current setup

- Flutter project created in this folder
- Firebase project linked: `pawmilya-flutter`
- FlutterFire configuration generated in `lib/firebase_options.dart`
- Firebase dependencies added:
  - `firebase_core`
  - `firebase_auth`
  - `cloud_firestore`

## Run the app

1. Enable Windows Developer Mode (required for plugin symlinks):
	- Run: `start ms-settings:developers`
	- Turn on Developer Mode in Windows Settings
2. Get packages:
	- `flutter pub get`
3. Run:
	- `flutter run`

## Reconfigure Firebase later

If you want to switch Firebase project or platforms:

`dart pub global run flutterfire_cli:flutterfire configure`
