# Firebase Push Notifications Setup

## Backend (Django)

1. **Install dependency** (already in requirements.txt):
   ```bash
   pip install firebase-admin
   ```

2. **Firebase Console**:
   - Create a project at https://console.firebase.google.com/
   - Go to Project Settings → Service accounts → Generate new private key
   - Save the JSON file (e.g. `serviceAccountKey.json`) in a secure location

3. **Configure Django**:
   - **Default**: Place your Firebase Admin SDK JSON file at:
     `backend/firebase_credentials/school-a97c9-firebase-adminsdk-fbsvc-b11f77baa3.json`
   - Or set `FIREBASE_CREDENTIALS_PATH` in `.env` to the full path of your service account JSON.
   - Get the JSON from Firebase Console → Project Settings → Service accounts → Generate new private key.
   - If the path is not set or the file is missing, push sending is skipped (no error; push is optional).
   - **Product key / legacy server key**: If you have a separate FCM product key, keep it for client or legacy use; the backend uses only the service account JSON.

4. **Run migration** (FCM device tokens table):
   ```bash
   python manage.py migrate main_login
   ```

## Flutter (Parent & Teacher apps)

1. **Firebase Console** (for each app):
   - Add Android app: package name `com.example.parent_main_folder` / `com.example.teacher_main_folder`
   - Add iOS app: bundle ID from Xcode
   - Download `google-services.json` (Android) and put in `android/app/`
   - Download `GoogleService-Info.plist` (iOS) and add to `ios/Runner/` in Xcode

2. **Android**: Google Services plugin is already applied in `android/settings.gradle.kts` and `android/app/build.gradle.kts`. Ensure `google-services.json` is in `android/app/`.

3. **iOS**:
   - Enable Push Notifications and Background Modes → Remote notifications in Xcode
   - Upload APNs key in Firebase Console → Project Settings → Cloud Messaging (iOS)

4. **Token registration**: After login, the app registers the FCM token with the backend via `POST /api/auth/fcm/register/` (title/body and audience are sent from management).

## Management app – Sending push

- Open **Notifications** in the management app.
- Click **Send Push**.
- Enter title, message, and audience (Students & Teachers / Students only / Teachers only).
- Push is sent to all registered devices for users in the management user’s school.

## API summary

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/fcm/register/` | POST | Register FCM token (body: `token`, `platform`: android/ios). Requires auth. |
| `/api/auth/fcm/unregister/` | POST | Remove FCM token (body: `token`). Requires auth. |
| `/api/management-admin/send-push/` | POST | Send push (body: `title`, `body`, `audience`: all_students \| all_teachers \| both, optional `school_id`). Management auth only. |
