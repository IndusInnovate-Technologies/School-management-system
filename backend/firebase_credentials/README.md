# Firebase credentials for push notifications

Place your **Firebase Admin SDK** service account JSON file here so the backend can send push notifications.

## Setup

1. **File name** (used by default in settings):
   - `school-a97c9-firebase-adminsdk-fbsvc-b11f77baa3.json`

   Or set `FIREBASE_CREDENTIALS_PATH` in your `.env` to the full path of your JSON file.

2. **Where to get the JSON**:
   - Firebase Console → Project Settings → Service accounts → **Generate new private key**
   - Save the downloaded file into this folder with the name above (or your chosen path).

3. **Security**: Do **not** commit the JSON file. This folder is set up so `*.json` is ignored by git.

## Product key / legacy server key

If you have a separate **product key** (e.g. FCM legacy server key), keep it secure and use it only where needed (e.g. client config or legacy HTTP API). The Django backend uses the **service account JSON** only (Firebase Admin SDK); it does not use the legacy server key.

## Verify

After placing the file, restart the Django server. Send a test push from the management app (Notifications → Send Push). If the path is correct, push will be sent; if not set or file missing, push is skipped without crashing.
