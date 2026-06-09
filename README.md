# Food Go Driver

Ứng dụng tài xế giao hàng cho hệ thống Food Go - giao hàng thực phẩm trực tuyến.

---

## Công nghệ sử dụng

| Lĩnh vực | Công nghệ |
|---|---|
| Framework | Flutter |
| Ngôn ngữ | Dart |
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

## Phiên bản

- **Flutter SDK:** `^3.11.1`
- **Dart SDK:** `^3.11.1`
- **Android Gradle Plugin:** 8.x
- **Kotlin:** 1.9.x

Kiểm tra phiên bản Flutter đang sử dụng:

```bash
flutter --version
```

---

## Các bước cài đặt và chạy project

### 1. Yêu cầu hệ thống

- Flutter SDK >= 3.11.1
- Dart SDK >= 3.11.1
- Android SDK (nếu build Android)
- Xcode + CocoaPods (nếu build iOS, chỉ trên macOS)
- Git

### 2. Clone project

```bash
git clone <repo-url>
cd fe_food_go_driver
```

### 3. Cài đặt dependencies

```bash
flutter pub get
```

### 4. Cấu hình Firebase

Ứng dụng sử dụng Firebase, cần thực hiện các bước sau:

1. Tạo project Firebase tại [Firebase Console](https://console.firebase.google.com/)
2. Đăng ký ứng dụng Android:
   - Lấy `google-services.json` từ Firebase Console -> Project Settings -> Your apps
   - Đặt file `google-services.json` vào `android/app/google-services.json`
3. Đăng ký ứng dụng iOS:
   - Lấy `GoogleService-Info.plist` từ Firebase Console
   - Đặt file vào `ios/Runner/GoogleService-Info.plist`
4. Bật Firebase Authentication:
   - Vào Firebase Console -> Authentication -> Sign-in method
   - Bật **Email/Password**
5. Tạo Firestore Database:
   - Vào Firebase Console -> Firestore Database -> Create database
   - Đặt rules cho phép đọc/ghi hoặc thiết lập rules phù hợp
6. Tạo Realtime Database:
   - Vào Firebase Console -> Realtime Database -> Create Database
7. Cấu hình Cloud Messaging (FCM):
   - Vào Firebase Console -> Project Settings -> Cloud Messaging
   - Lấy **Server key** để cấu hình phía server gửi notification

### 5. Cấu hình Android

#### Thêm quyền trong `android/app/src/main/AndroidManifest.xml`

File đã có sẵn các quyền cần thiết:

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

#### Cấu hình minSdkVersion

Trong `android/app/build.gradle`, đảm bảo `minSdkVersion` >= 21:

```groovy
defaultConfig {
    minSdkVersion 21
    // ...
}
```

#### Thêm Google Services plugin

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

### 6. Cấu hình iOS (chỉ macOS)

#### Thêm quyền trong `ios/Runner/Info.plist`

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>App có thể xác định vị trí của bạn để nhận đơn giao hàng</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>App có thể xác định vị trí khi chạy nền để cập nhật vị trí liên tục</string>
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>remote-notification</string>
</array>
```

#### Chạy pod install

```bash
cd ios
pod install
cd ..
```

### 7. Chạy ứng dụng

```bash
# Chạy chế độ debug
flutter run

# Build APK debug
flutter build apk --debug

# Build APK release
flutter build apk --release
```

---

## Các package/dependency cần cài

Tất cả các package đã được khai báo trong `pubspec.yaml`:

| Package | Phiên bản | Mục đích |
|---|---|---|
| flutter_bloc | ^8.1.6 | Quản lý trạng thái |
| equatable | ^2.0.5 | So sánh đối tượng |
| dartz | ^0.10.1 | Functional programming |
| rxdart | ^0.28.0 | Reactive extensions |
| get_it | ^8.0.3 | Dependency injection |
| shared_preferences | ^2.3.5 | Lưu trữ cục bộ |
| flutter_secure_storage | ^9.2.4 | Lưu trữ an toàn |
| intl | ^0.20.2 | Định dạng ngôn ngữ |
| http | ^1.2.0 | Gọi API |
| stomp_dart_client | ^3.0.1 | WebSocket STOMP |
| geolocator | ^13.0.2 | Lấy vị trí |
| permission_handler | ^11.3.1 | Xử lý quyền |
| flutter_tts | ^4.2.0 | Text-to-speech |
| flutter_map | ^7.0.2 | Bản đồ |
| latlong2 | ^0.9.1 | Tọa độ địa lý |
| google_fonts | ^6.2.1 | Phông chữ |
| shimmer | ^3.0.0 | Hiệu ứng loading |
| pinput | ^5.0.0 | Nhập OTP |
| url_launcher | ^6.3.1 | Mở URL |
| firebase_core | ^3.12.1 | Firebase core |
| cloud_firestore | ^5.6.6 | Cloud Firestore |
| firebase_database | ^11.3.5 | Realtime Database |
| firebase_auth | ^5.5.3 | Xác thực |
| firebase_messaging | ^15.2.4 | Push notification |
| flutter_local_notifications | ^21.0.0 | Thông báo cục bộ |

---

## Tài khoản test

Ứng dụng sử dụng Firebase Authentication (Email/Password).

### Tạo tài khoản test

1. Vào Firebase Console -> Authentication -> Users
2. Chọn **Add user** và tạo tài khoản:

   ```
   Email:    trangkimdatst2005@gmail.com
   Password: Kimdat@123
   ```

3. Hoặc đăng ký trực tiếp trong ứng dụng.

### Phân quyền driver

Tài khoản driver cần được tạo/phân quyền từ phía backend API. Khi driver đăng nhập, backend sẽ kiểm tra thông tin và trả về token.

---

## Các lỗi cần lưu ý để project hoạt động

### 1. Quyền location

Ứng dụng yêu cầu **quyền vị trí** để:
- Hiển thị vị trí tài xế trên bản đồ
- Cập nhật vị trí lên server (real-time tracking)
- Nhận đơn giao hàng gần vị trí

Nếu không cấp quyền vị trí, một số chức năng sẽ không hoạt động.

### 2. Firebase Configuration

- File `google-services.json` (Android) và `GoogleService-Info.plist` (iOS) **bắt buộc** phải có. Nếu không có, ứng dụng sẽ lỗi khi khởi động.
- Đảm bảo Firebase project đã bật các dịch vụ: **Authentication**, **Firestore**, **Realtime Database**, **Cloud Messaging**.

### 3. WebSocket / STOMP

Ứng dụng kết nối đến server qua **STOMP over WebSocket** để nhận đơn giao hàng real-time. Đảm bảo:
- Server backend đã cấu hình WebSocket endpoint
- Địa chỉ server (URL) đã được cấu hình đúng trong `lib/core/api/api_constants.dart` hoặc `lib/injection_container.dart`
- Thiết bị có internet để kết nối

### 4. API Backend

Ứng dụng gọi API đến backend (REST) cho các tác vụ như:
- Đăng nhập / xác thực
- Lấy danh sách đơn hàng
- Cập nhật trạng thái đơn hàng
- Lấy thông tin người dùng

Đảm bảo backend API đã chạy và địa chỉ đã được cấu hình đúng.

### 5. Notification khi app ở nền

Khi app ở chế độ nền (background/terminated), push notification được gửi qua **FCM**. Cần:
- Cài đặt `firebase_messaging`
- Cấu hình FCM server key phía backend để gửi notification

### 6. Foreground Service (Android)

Ứng dụng sử dụng **Foreground Service** để cập nhật vị trí khi app ở nền. Đảm bảo:
- Quyền `FOREGROUND_SERVICE` và `FOREGROUND_SERVICE_LOCATION` đã được khai báo
- Không tắt ứng dụng khi đang giao hàng

### 7. Thư mục assets

Đảm bảo thư mục assets tồn tại:

```
assets/
  lang/
  img/
```

Nếu không có, chạy:

```bash
mkdir -p assets/lang assets/img
```

### 8. Build lỗi thường gặp

- **Lỗi `minSdkVersion`:** Tăng minSdkVersion trong `build.gradle` lên 21+
- **Lỗi `google-services.json`:** Kiểm tra file có đúng project Firebase
- **Lỗi `pod install` (iOS):** Chạy `cd ios && pod install --repo-update`
- **Lỗi Flutter: `Unable to find git`:** Cài đặt git và thêm vào PATH

---

## Cấu trúc project

```
lib/
  core/           # Cấu hình chung, API, constants, theme
  features/       # Các chức năng theo feature
    auth/         # Đăng nhập, xác thực
    home/         # Màn hình chính, nhận đơn hàng
    orders/       # Quản lý đơn hàng
    profile/      # Thông tin tài xế
  injection_container.dart  # Cấu hình DI (get_it)
  main.dart      # Entry point
```

---

## Liên hệ / Hỗ trợ

Nếu gặp vấn đề khi cài đặt hoặc chạy dự án, vui lòng kiểm tra:
1. Các bước cấu hình Firebase ở trên
2. Phiên bản Flutter/Dart
3. Quyền truy cập (location, internet)
4. Backend API và WebSocket server đã chạy
