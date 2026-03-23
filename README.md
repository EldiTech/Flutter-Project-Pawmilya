# Pawmilya Flutter App

Flutter app for Pawmilya shelter operations, backed by Firebase.

## Firebase Services

- Firebase Auth (login/signup)
- Cloud Firestore (`pets`, `bookings`, `employees`, `shelter_zones`, `shelter_users`)
- Firebase Storage (ready for image/file uploads)

## Architecture

- `lib/models`: Firestore data models
- `lib/services/firestore_service.dart`: Firebase interaction layer
- `lib/providers/dashboard_provider.dart`: state management with `provider`
- `lib/screens/system_home_screen.dart`: UI bound to provider state

## Setup

1. Ensure FlutterFire config is present in `lib/firebase_options.dart`
2. Install dependencies:

	`flutter pub get`

3. Run app:

	`flutter run`

## Security Rules

Use these rule files when deploying Firebase rules:

- `firestore.rules`
- `storage.rules`

Deploy to Firebase project `pawmilya-shelter-management`:

1. Login and select project:

	`firebase login`

	`firebase use pawmilya-shelter-management`

2. Deploy database/storage config:

	`firebase deploy --only firestore:rules,firestore:indexes,storage`

## Validation Checklist

- Login/Signup creates and authenticates Firebase users
- Dashboard module counts reflect Firestore collections
- Animal/Application/Employee/Zone modules render Firestore data
- Clearing data in app no longer uses local storage
- Flutter and website show consistent data for shared collections
