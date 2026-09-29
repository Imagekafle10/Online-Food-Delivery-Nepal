# Push notifications – setup (5 steps)

Extract this zip **over your project** (paths match: `lib/`, `src/`, `migrations/`).

## 1. Firebase project (one-time)
1. https://console.firebase.google.com → create/open a project.
2. Add your **Android app** (use your `applicationId` from `android/app/build.gradle`) → download `google-services.json` → put it in `android/app/`.
3. (iOS only) add iOS app → `GoogleService-Info.plist` → `ios/Runner/`, and upload an APNs key under Project Settings → Cloud Messaging.
4. Project Settings → **Service accounts** → *Generate new private key* → JSON file for the backend.

## 2. Database
Run `migrations/002_device_tokens.sql` on your MySQL database.

## 3. Backend
```bash
npm i firebase-admin
```
Add the service-account JSON to your env (Render → Environment):
```bash
# Linux/Mac:  base64 -w0 serviceAccount.json
# Windows PS: [Convert]::ToBase64String([IO.File]::ReadAllBytes("serviceAccount.json"))
FIREBASE_SERVICE_ACCOUNT_BASE64=<paste the base64 string>
```
Without this var the API still works; push is just skipped (a warning is logged).

## 4. Flutter
`pubspec.yaml` → dependencies:
```yaml
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^18.0.1
```
Then `flutter pub get`.

**Android Gradle** (Google services plugin):
- `android/settings.gradle(.kts)` plugins block: `id("com.google.gms.google-services") version "4.4.2" apply false`
- `android/app/build.gradle(.kts)` plugins block: `id("com.google.gms.google-services")`
- `android/app/build.gradle(.kts)` → `compileOptions`: set `isCoreLibraryDesugaringEnabled = true` and add
  `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` to dependencies (needed by flutter_local_notifications).

**AndroidManifest.xml** (`android/app/src/main/AndroidManifest.xml`), inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

## 5. Run
`flutter run` → log in → the token is registered automatically.

## What sends what
| Event | Who gets it |
|---|---|
| Order placed | Restaurant owner + staff |
| Accepted / Cooking / On the way / Delivered / Cancelled | Customer |
| Rider assigned (auto or manual) | Rider |
| Customer cancels | Restaurant owner + staff |

Tapping a customer notification opens Order Tracking; a rider notification opens the delivery screen.

## Files
**New:** `migrations/002_device_tokens.sql`, `src/config/firebase.ts`, `src/models/device.model.ts`, `src/services/notification.service.ts`, `src/controllers/device.controller.ts`, `src/routes/device.routes.ts`, `lib/services/notification_service.dart`
**Changed:** `src/routes/index.ts`, `src/services/order.service.ts`, `src/services/delivery.service.ts`, `lib/main.dart`, `lib/providers/auth_provider.dart`, `lib/config/api_config.dart`

## Test quickly
Firebase Console → Messaging → *Send test message* with your device token, or just place an order and move its status from the dashboard.
