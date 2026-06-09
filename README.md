# Food Go Driver

Ung dung tai xe giao hang cho he thong Food Go - giao hang thuc an truc tuyen.

---

## Cong nghe su dung

| Linh vuc | Cong nghe |
|---|---|
| Framework | Flutter |
| Ngon ngu | Dart |
| State Management | flutter_bloc |
| Dependency Injection | get_it |
| Real-time Communication | STOMP (WebSocket) |
| Database | Firebase Firestore, Firebase Realtime Database |
| Authentication | Firebase Authentication |
| Push Notification | Firebase Cloud Messaging (FCM) |
| Maps | flutter_map (OpenStreetMap) |
| Location | Geolocator |
| Local Storage | shared_preferences, flutter_secure_storage |

---

## Phien ban

- **Flutter SDK:** `^3.11.1`
- **Dart SDK:** `^3.11.1`
- **Android Gradle Plugin:** 8.x
- **Kotlin:** 1.9.x

Kiem tra phien ban Flutter dang su dung:

```bash
flutter --version
```

---

## Cac buoc cai dat va chay project

### 1. Yeu cau he thong

- Flutter SDK >= 3.11.1
- Dart SDK >= 3.11.1
- Android SDK (neu build Android)
- Xcode + CocoaPods (neu build iOS, chi tren macOS)
- Git

### 2. Clone project

```bash
git clone <repo-url>
cd fe_food_go_driver
```

### 3. Cai dat dependencies

```bash
flutter pub get
```

### 4. Cau hinh Firebase

Ung dung su dung Firebase, can thuc hien cac buoc sau:

1. Tao project Firebase tai [Firebase Console](https://console.firebase.google.com/)
2. Dang ky ung dung Android:
   - Lay `google-services.json` tu Firebase Console -> Project Settings -> Your apps
   - Dat file `google-services.json` vao `android/app/google-services.json`
3. Dang ky ung dung iOS:
   - Lay `GoogleService-Info.plist` tu Firebase Console
   - Dat file vao `ios/Runner/GoogleService-Info.plist`
4. Bat Firebase Authentication:
   - Vao Firebase Console -> Authentication -> Sign-in method
   - Bat **Email/Password**
5. Tao Firestore Database:
   - Vao Firebase Console -> Firestore Database -> Create database
   - Dat rules cho phep doc/ghi hoac thiet lap rules phu hop
6. Tao Realtime Database:
   - Vao Firebase Console -> Realtime Database -> Create Database
7. Cau hinh Cloud Messaging (FCM):
   - Vao Firebase Console -> Project Settings -> Cloud Messaging
   - Lay **Server key** de cau hinh phia server gui notification

### 5. Cau hinh Android

#### Them quyen trong `android/app/src/main/AndroidManifest.xml`

File da co san cac quyen can thiet:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```

#### Cau hinh minSdkVersion

Trong `android/app/build.gradle`, dam bao `minSdkVersion` >= 21:

```groovy
defaultConfig {
    minSdkVersion 21
    // ...
}
```

#### Them Google Services plugin

Trong `android/build.gradle` (project-level):

```groovy
plugins {
    id 'com.android.application' version '8.1.0' apply false
    id 'com.google.gms.google-services' version '4.4.2' apply false
}
```

Trong `android/app/build.gradle` (app-level):

```groovy
plugins {
    id 'com.google.gms.google-services'
}
```

### 6. Cau hinh iOS (chi macOS)

#### Them quyen trong `ios/Runner/Info.plist`

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>App can xac dinh vi tri cua ban de nhan don giao hang</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>App can xac dinh vi tri khi chay nen de cap nhat vi tri lien tuc</string>
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>remote-notification</string>
</array>
```

#### Chay pod install

```bash
cd ios
pod install
cd ..
```

### 7. Chay ung dung

```bash
# Chay che do debug
flutter run

# Build APK debug
flutter build apk --debug

# Build APK release
flutter build apk --release
```

---

## Cac package/dependency can cai

Tat ca cac package da duoc khai bao trong `pubspec.yaml`:

| Package | Phien ban | Muc dich |
|---|---|---|
| flutter_bloc | ^8.1.6 | Quan ly trang thai |
| equatable | ^2.0.5 | So sanh doi tuong |
| dartz | ^0.10.1 | Functional programming |
| rxdart | ^0.28.0 | Reactive extensions |
| get_it | ^8.0.3 | Dependency injection |
| shared_preferences | ^2.3.5 | Luu tru cuc bo |
| flutter_secure_storage | ^9.2.4 | Luu tru an toan |
| intl | ^0.20.2 | Đinh dang ngon ngu |
| http | ^1.2.0 | Goi API |
| stomp_dart_client | ^3.0.1 | WebSocket STOMP |
| geolocator | ^13.0.2 | Lay vi tri |
| permission_handler | ^11.3.1 | Xu ly quyen |
| flutter_tts | ^4.2.0 | Text-to-speech |
| flutter_map | ^7.0.2 | Ban do |
| latlong2 | ^0.9.1 | Toa do dia ly |
| google_fonts | ^6.2.1 | Phong chu |
| shimmer | ^3.0.0 | Hieu ung loading |
| pinput | ^5.0.0 | Nhap OTP |
| url_launcher | ^6.3.1 | Mo URL |
| firebase_core | ^3.12.1 | Firebase core |
| cloud_firestore | ^5.6.6 | Cloud Firestore |
| firebase_database | ^11.3.5 | Realtime Database |
| firebase_auth | ^5.5.3 | Xac thuc |
| firebase_messaging | ^15.2.4 | Push notification |
| flutter_local_notifications | ^21.0.0 | Thong bao cuc bo |

---

## Tai khoan test

Ung dung su dung Firebase Authentication (Email/Password).

### Tao tai khoan test

1. Vao Firebase Console -> Authentication -> Users
2. Chon **Add user** va tao tai khoan:

   ```
   Email:    driver_test@example.com
   Password: Test123456
   ```

3. Hoac dang ky truc tiep trong ung dung.

### Phan quyen driver

Tai khoan driver can duoc tao/phan quyen tu phia backend API. Khi driver dang nhap, backend se kiem tra thong tin va tra ve token.

---

## Cac loi can luu y de project hoat dong

### 1. Quyen location

Ung dung yeu cau **quyen vi tri** de:
- Hien thi vi tri tai xe tren ban do
- Cap nhat vi tri len server (real-time tracking)
- Nhan don giao hang gan vi tri

Neu khong cap quyen vi tri, mot so chuc nang se khong hoat dong.

### 2. Firebase Configuration

- File `google-services.json` (Android) va `GoogleService-Info.plist` (iOS) **bat buoc** phai co. Neu khong co, ung dung se loi khi khoi dong.
- Dam bao Firebase project da bat cac dich vu: **Authentication**, **Firestore**, **Realtime Database**, **Cloud Messaging**.

### 3. WebSocket / STOMP

Ung dung ket noi den server qua **STOMP over WebSocket** de nhan don giao hang real-time. Dam bao:
- Server backend da cau hinh WebSocket endpoint
- Dia chi server (URL) da duoc cau hinh dung trong `lib/core/api/api_constants.dart` hoac `lib/injection_container.dart`
- Device co internet de ket noi

### 4. API Backend

Ung dung goi API den backend (REST) cho cac tac vu nhu:
- Dang nhap / xac thuc
- Lay danh sach don hang
- Cap nhat trang thai don hang
- Lay thong tin nguoi dung

Dam bao backend API da chay va dia chi da duoc cau hinh dung.

### 5. Notification khi app o nen

Khi app o che do nen (background/terminated), push notification duoc gui qua **FCM**. Can:
- Cai dat `firebase_messaging`
- Cau hinh FCM server key phia backend de gui notification

### 6. Foreground Service (Android)

Ung dung su dung **Foreground Service** de cap nhat vi tri khi app o nen. Dam bao:
- Quyen `FOREGROUND_SERVICE` va `FOREGROUND_SERVICE_LOCATION` da duoc khai bao
- Khong tat ung dung khi dang giao hang

### 7. Thu muc assets

Dam bao thu muc assets ton tai:

```
assets/
  lang/
  img/
```

Neu khong co, chay:

```bash
mkdir -p assets/lang assets/img
```

### 8. Build loi thuong gap

- **Loi `minSdkVersion`:** Tang minSdkVersion trong `build.gradle` len 21+
- **Loi `google-services.json`:** Kiem tra file co dung project Firebase
- **Loi `pod install` (iOS):** Chay `cd ios && pod install --repo-update`
- **Loi Flutter: `Unable to find git`:** Cai dat git va them vao PATH

---

## Cau truc project

```
lib/
  core/           # Cau hinh chung, API, constants, theme
  features/       # Cac chuc nang theo feature
    auth/         # Dang nhap, xac thuc
    home/         # Man hinh chinh, nhan don hang
    orders/       # Quan ly don hang
    profile/      # Thong tin tai xe
  injection_container.dart  # Cau hinh DI (get_it)
  main.dart      # Entry point
```

---

## Lien he / Ho tro

Neu gap van de khi cai dat hoac chay du an, vui long kiem tra:
1. Cac buoc cau hinh Firebase o tren
2. Phien ban Flutter/Dart
3. Quyen truy cap (location, internet)
4. Backend API va WebSocket server da chay
