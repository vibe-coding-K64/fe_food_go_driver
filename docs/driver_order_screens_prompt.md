# Prompt: Giao diện Đơn hàng Tài xế (Driver Order Screens) — Luồng Hoạt động Toàn diện

## 1. Tổng quan

Xây dựng toàn bộ màn hình liên quan đến **đơn hàng dành cho tài xế (Role 2)** trong ứng dụng giao đồ ăn **FoodGo**, sử dụng **Flutter** cho mobile. Phạm vi bao gồm: danh sách đơn khả dụng, đơn đang giao, chi tiết đơn, lịch sử, thống kê, ví tài xế, rút tiền, thông báo — kèm **luồng hoạt động chi tiết từng bước** cho mọi chức năng.

> **Nguyên tắc thiết kế:** Mobile-first, thao tác nhanh, thông tin tối giản, hành động rõ ràng. Tài xế cần nhìn thấy ngay đơn cần giao mà không cần scroll nhiều.

---

## 2. Tổng hợp API Endpoints (Backend Spring Boot — Thực tế)


**Auth:** Tất cả API đều yêu cầu `Authorization: Bearer <JWT>` trong header. `driverId` / `userId` được trích từ JWT token đã đăng nhập, **không truyền trong URL**.

### 2.1. Driver Profile & Status (`/api/drivers`)

| API | Method | Body | Mô tả |
|---|---|---|---|
| `/profile` | GET | — | Lấy thông tin hồ sơ tài xế |
| `/profile` | PUT | `DeliveryProfileRequest` | Cập nhật hồ sơ (họ tên, SĐT, ảnh) |
| `/status` | PUT | `DeliveryStatusRequest` | Toggle online/offline (bật phải gửi GPS) |
| `/vehicle` | PUT | `DeliveryVehicleRequest` | Cập nhật thông tin phương tiện |
| `/location` | POST | `DeliveryLocationUpdateRequest` | Gửi vị trí GPS lên Realtime Database |

### 2.2. Delivery Orders (`/api/drivers/orders`)

| API | Method | Body / Params | Mô tả |
|---|---|---|---|
| `/available` | GET | — | Danh sách đơn chờ tài xế nhận (status=1, driverId=null) |
| `/{id}/accept` | POST | — | Nhận đơn hàng (tự chọn) |
| `/{id}/decline` | POST | — | Từ chối đơn hàng (tự chọn) |
| `/{id}/respond` | POST | `{ "action": "accept" \| "decline" }` | Accept/decline khi hệ thống gán tự động |
| `/current` | GET | — | Đơn hàng đang giao hiện tại (status=2, driverId=current) |
| `/active` | GET | — | Tất cả đơn đang hoạt động (status=2) |
| `/history` | GET | — | Lịch sử đơn đã giao (status=3) |
| `/{id}/status` | PUT | `{ "status": 3 \| 4 }` | Cập nhật trạng thái: 3=Hoàn thành, 4=Hủy |

### 2.3. Notifications (`/api/drivers/notifications`)

| API | Method | Params | Mô tả |
|---|---|---|---|
| `?type=11\|12\|13` | GET | `?type=11` (tùy chọn) | Danh sách thông báo |
| `/{id}/read` | PUT | — | Đánh dấu 1 thông báo đã đọc |
| `/read-all` | PUT | — | Đánh dấu tất cả đã đọc |
| `/{id}` | DELETE | — | Xóa 1 thông báo |

### 2.4. Wallet (`/api/drivers`)

| API | Method | Body / Params | Mô tả |
|---|---|---|---|
| `/wallet` | GET | — | Thông tin ví (số dư, thu nhập, đã rút, chờ) |
| `/transactions` | GET | `?page=0&size=20` | Lịch sử giao dịch (có phân trang) |
| `/withdraw` | POST | `{ "amount": 50000 }` | Yêu cầu rút tiền |

---

## 3. Chi tiết DTO — Tất cả objects trả về từ API

### 3.1. DeliveryOrderDTO (Đơn hàng giao hàng)

```dart
class DeliveryOrderDTO {
  String id;                    // ID đơn hàng
  String userId;                // ID người đặt
  String storeId;               // ID cửa hàng
  String storeName;             // Tên cửa hàng
  String storeAddress;          // Địa chỉ cửa hàng
  Double storeLat;               // Vĩ độ cửa hàng
  Double storeLng;              // Kinh độ cửa hàng
  List<OrderItemData> items;     // Danh sách món ăn
  Double totalAmount;            // Tổng tiền đơn (VND)
  Double deliveryFee;            // Phí giao hàng (VND) — THU NHẬP tài xế
  Integer status;                // 0=Chờ xác nhận, 1=Đang chuẩn bị, 2=Đang giao, 3=Hoàn thành, 4=Đã hủy
  Integer paymentStatus;         // 1=Chưa TT, 2=Đã TT
  String deliveryAddress;        // Địa chỉ giao hàng
  Double deliveryLat;            // Vĩ độ giao hàng
  Double deliveryLng;           // Kinh độ giao hàng
  int paymentMethod;            // 1=Tiền mặt, 2=MoMo, 3=Zalo, 4=VNPay
  String driverId;              // ID tài xế nhận đơn
  String driverName;            // Tên tài xế
  String driverPhone;           // SĐT tài xế
  String vehiclePlate;          // Biển số xe
  Instant createdAt;            // Thời gian tạo đơn
  Instant updatedAt;            // Thời gian cập nhật gần nhất
  String note;                  // Ghi chú đơn hàng

  // Nested: OrderItemData
  static class OrderItemData {
    String foodId;
    String name;                 // Tên món
    Double price;                // Đơn giá
    Integer quantity;            // Số lượng
    String imageUrl;             // URL ảnh
    List<OptionData> options;    // Các tùy chọn
  }

  // Nested: OptionData
  static class OptionData {
    String name;                 // Tên tùy chọn
    Double price;                // Giá tùy chọn
  }
}
```

### 3.2. NotificationDTO (Thông báo)

```dart
class NotificationDTO {
  String id;                     // ID thông báo
  Integer type;                  // 11=Yêu cầu nhận đơn, 12=Thông báo giao, 13=Đơn bị tài xế khác nhận
  String title;                  // Tiêu đề
  String body;                   // Nội dung (LƯU Ý: field là "body", KHÔNG phải "message")
  String orderId;                // ID đơn hàng liên quan
  String referenceId;            // Tham chiếu (thường = orderId)
  Boolean isRead;                // Đã đọc chưa
  String imageUrl;              // URL hình ảnh kèm theo
  Instant createdAt;             // Thời gian tạo
}
```

### 3.3. WalletDTO (Ví tài xế)

```dart
class WalletDTO {
  String id;                     // ID ví
  String userId;                // ID chủ ví (= driverId)
  String role;                  // Vai trò ("driver")
  Double balance;               // Số dư khả dụng (VND)
  Double totalEarned;            // Tổng thu nhập (VND)
  Double totalWithdrawn;         // Tổng đã rút (VND)
  Double pendingBalance;         // Số dư chờ xử lý (VND)
  String bankName;               // Tên ngân hàng thụ hưởng
  String bankAccountNumber;      // Số tài khoản
  String bankAccountName;         // Tên người thụ hưởng
  Instant createdAt;            // Thời gian tạo ví
  Instant updatedAt;             // Thời gian cập nhật gần nhất
}
```

### 3.4. TransactionDTO (Giao dịch)

```dart
class TransactionDTO {
  String id;                     // ID giao dịch
  String walletId;              // ID ví liên quan
  String userId;                // ID người thực hiện
  Integer type;                  // 1=delivery_income, 2=withdrawal, 3=refund
  Double amount;                 // Số tiền giao dịch (VND)
  Double fee;                   // Phí giao dịch (VND)
  Double netAmount;              // Số tiền thực nhận = amount - fee
  String description;           // Mô tả giao dịch
  String orderId;               // ID đơn hàng liên quan (nếu là delivery_income)
  Integer status;               // 0=pending, 1=completed, 2=failed
  Instant createdAt;            // Thời gian tạo
}
```

### 3.5. DeliveryProfileDTO (Hồ sơ tài xế)

```dart
class DeliveryProfileDTO {
  String userId;                 // ID tài xế
  String fullName;               // Họ tên đầy đủ
  String phoneNumber;            // SĐT
  String photoUrl;              // URL ảnh đại diện
  Boolean isActive;              // Trạng thái online/offline
  String vehiclePlate;          // Biển số xe
  String vehicleType;            // Loại xe: MOTORCYCLE, BICYCLE, CAR
  String driverLicense;         // Giấy phép lái xe
  Double rating;                // Điểm đánh giá (0.0 - 5.0)
  Integer totalTrips;            // Tổng số chuyến đã giao
  Integer todayTrips;            // Số chuyến hôm nay
  Double todayEarnings;         // Thu nhập hôm nay (VND)
  Instant createdAt;            // Thời gian tạo
  Instant updatedAt;            // Thời gian cập nhật
}
```

### 3.6. Request DTOs (Body gửi lên)

```dart
// PUT /api/drivers/status — Bật online
class DeliveryStatusRequest {
  Boolean isActive;     // true = online
  Double lat;           // BẮT BUỘC khi isActive=true
  Double lng;           // BẮT BUỘC khi isActive=true
  Double heading;       // Hướng di chuyển (0-360 độ)
  Double speed;         // Tốc độ (km/h)
}

// PUT /api/drivers/status — Tắt offline
class DeliveryStatusRequest {
  Boolean isActive;     // false = offline (chỉ cần field này)
}

// POST /api/drivers/location
class DeliveryLocationUpdateRequest {
  Double lat;           // BẮT BUỘC
  Double lng;           // BẮT BUỘC
  Double heading;       // Hướng (0-360)
  Double speed;         // Tốc độ (km/h)
}

// POST /api/drivers/orders/{id}/respond
class DeliveryRespondRequest {
  String action;       // "accept" hoặc "decline"
}

// PUT /api/drivers/orders/{id}/status
class DeliveryOrderStatusRequest {
  Integer status;       // 3=Hoàn thành, 4=Hủy
}

// POST /api/drivers/withdraw
class WithdrawRequest {
  Double amount;        // Số tiền rút (VND), tối thiểu 50000
}
```

---

## 4. Mã trạng thái đơn hàng

| Giá trị | Label | Màu sắc | Mô tả |
|---|---|---|---|
| 0 | Chờ xác nhận | Cam | Cửa hàng chưa xác nhận |
| 1 | Đang chuẩn bị | Vàng | Cửa hàng đang chuẩn bị |
| 2 | Đang giao | Xanh dương | Tài xế đang giao |
| 3 | Hoàn thành | Xanh lá | Giao thành công — **tạo thu nhập** |
| 4 | Đã hủy | Đỏ | Đơn bị hủy |

---

## 5. Mã loại thông báo (Notification type)

| Giá trị | Label | Mô tả |
|---|---|---|
| 11 | Yêu cầu nhận đơn | Hệ thống gán đơn tự động, cần tài xế phản hồi |
| 12 | Thông báo giao hàng | Cập nhật trạng thái đơn |
| 13 | Đơn bị tài xế khác nhận | Đơn đã được tài xế khác nhận (409 conflict) |

---

## 6. Mã loại giao dịch (Transaction type)

| Giá trị | Label | Mô tả |
|---|---|---|
| 1 | delivery_income | Thu nhập từ giao hàng |
| 2 | withdrawal | Rút tiền |
| 3 | refund | Hoàn tiền |

---

## 7. Luồng hoạt động chi tiết từng chức năng

### 7.1. Luồng 1: Toggle Online / Offline

```
[START] → Tài xế bật/tắt toggle Online
    │
    ├─► BẬT ONLINE (isActive = true)
    │   │
    │   ① App kiểm tra GPS permission
    │      ├─► CHƯA CÓ → Hiện dialog xin quyền truy cập vị trí
    │      │      ├─► User GRANT → lấy GPS → bước ②
    │      │      └─► User DENY → snackbar "Cần quyền GPS để nhận đơn"
    │      └─► ĐÃ CÓ → bước ②
    │   │
    │   ② Lấy tọa độ GPS hiện tại (lat, lng, heading, speed)
    │   │
    │   ③ Gửi PUT /api/drivers/status
    │      Body: { "isActive": true, "lat": 10.85, "lng": 106.79, "heading": 90, "speed": 30 }
    │      ├─► SUCCESS (200) → bước ④
    │      └─► FAIL → snackbar lỗi + rollback toggle
    │   │
    │   ④ Backend cập nhật DriverProfile.isActive = true
    │      Backend cập nhật DriverLocation trong Realtime Database
    │   │
    │   ⑤ App cập nhật UI: toggle ON, màu xanh lá, hiện icon online
    │      ├─► Bắt đầu GPS realtime service (cập nhật mỗi 5-10s)
    │      │    POST /api/drivers/location
    │      │    Body: { "lat": ..., "lng": ..., "heading": ..., "speed": ... }
    │      ├─► Bắt đầu polling đơn mới mỗi 10-15s
    │      │    GET /api/drivers/orders/available
    │      └─► Hiện snackbar "Bạn đã online. Sẵn sàng nhận đơn!"
    │
    └─► TẮT ONLINE (isActive = false)
        │
        ① Gửi PUT /api/drivers/status
           Body: { "isActive": false }
           ├─► SUCCESS (200) → bước ②
           └─► FAIL → snackbar lỗi + rollback toggle
        │
        ② Backend cập nhật DriverProfile.isActive = false
           Backend cập nhật DriverLocation.isActive = false trong Realtime DB
        │
        ③ App cập nhật UI: toggle OFF, màu xám, hiện icon offline
           ├─► Dừng GPS realtime service
           ├─► Dừng polling đơn hàng
           └─► Snackbar "Bạn đã offline. Sẽ không nhận được đơn mới."
```

**Lưu ý:**
- Khi online, GPS chạy ở background dù app minimize (dùng `flutter_background_service`).
- Nếu GPS không lấy được location trong 10 giây, vẫn cho online nhưng cảnh báo.
- Khi app bị kill, GPS background vẫn chạy nếu user cho phép.
- **Body khi bật online**: `{ isActive: true, lat, lng, heading, speed }` — **KHÔNG phải** `{ isActive: true }` riêng rẽ.

---

### 7.2. Luồng 2: Nhận đơn hàng (Manual — tự chọn)

```
[START] → Tài xế vào màn "Đơn khả dụng" (Available Orders)
    │
    ① Load danh sách: GET /api/drivers/orders/available
    │   ├─► SUCCESS → Hiển thị ListView các đơn
    │   │       ├─► Có đơn → render OrderCard với nút "Nhận đơn"
    │   │       └─► Không đơn → Empty state + icon xe + "Không có đơn hàng nào"
    │   └─► FAIL → Error state + nút "Thử lại"
    │
    ② Tài xế nhấn "Nhận đơn" trên card đơn X
    │
    ③ Hiện dialog xác nhận:
       "Bạn có chắc nhận đơn #{mã rút gọn 6 ký tự} không?"
       Nội dung: "{storeName} - Phí: {deliveryFee}đ"
       ├─► "Hủy" → Đóng dialog
       └─► "Xác nhận" → bước ④
    │
    ④ Gửi POST /api/drivers/orders/{id}/accept
       ├─► SUCCESS (200) → bước ⑤
       ├─► 409 CONFLICT → "Đơn hàng đã được tài xế khác nhận."
       │      Hiện dialog → xóa card với animation slide-out
       ├─► 404 NOT_FOUND → "Không tìm thấy đơn hàng."
       └─► 403 FORBIDDEN → "Bạn không có quyền thực hiện."
    │
    ⑤ Backend thực hiện Firestore Transaction:
       - driverId = currentUser, driverName, driverPhone, vehiclePlate
       - status = 1 (Đang chuẩn bị)
       - Tạo Notification type=11 cho tài xế
    │
    ⑥ App nhận response (DeliveryOrderDTO đã được cập nhật driver info)
    │
    ⑦ Hiện dialog thành công:
       "Bạn đã nhận đơn thành công!"
       "Đơn: #{mã} từ {storeName}"
       "Phí giao: {deliveryFee}đ"
       ├─► "Xem chi tiết" → điều hướng OrderDetailScreen(id)
       └─► "Đóng" → ở lại trang, refresh danh sách
    │
    ⑧ Đơn biến mất khỏi danh sách "Khả dụng"
       vì driverId đã được gán, không còn thỏa driverId == null
```

---

### 7.3. Luồng 3: Hệ thống gán đơn tự động (Auto-assign)

```
[START] → Backend tự động gán đơn cho tài xế
    │
    ① Backend ghi Notification vào Firestore, type=11
       Backend gửi FCM push notification đến app tài xế
    │
    ├─► APP ĐANG MỞ (foreground)
    │   │
    │   ② FCM nhận notification → kiểm tra type=11
    │      Hiện custom in-app banner / bottom sheet đặt trên cùng màn
    │      Nội dung:
    │        "Bạn có đơn hàng mới!"
    │        "{storeName}"
    │        "Phí giao: {deliveryFee}đ"
    │        "{deliveryAddress}" (rút gọn)
    │      Phát âm thanh thông báo (audioplayers)
    │      Hiệu ứng vibration (HapticFeedback.heavyImpact())
    │      ├─► "Nhận đơn" → bước ③
    │      └─► "Từ chối" → bước ⑤
    │   │
    │   ③ Tài xế nhấn "Nhận đơn"
    │   │
    │   ④ Gửi POST /api/drivers/orders/{id}/respond
    │      Body: { "action": "accept" }
    │      ├─► SUCCESS (200) → Dialog thành công → điều hướng OrderDetail
    │      │       Nội dung: "Đã nhận đơn thành công! Đi giao ngay thôi."
    │      ├─► 409 CONFLICT → "Đơn đã được tài xế khác nhác."
    │      │       Đóng banner → snackbar
    │      └─► 403 FORBIDDEN → "Yêu cầu đã hết hạn."
    │   │
    │   ⑤ Tài xế nhấn "Từ chối"
    │   │
    │   ⑥ Gửi POST /api/drivers/orders/{id}/respond
    │      Body: { "action": "decline" }
    │      ├─► SUCCESS (200) → Đóng banner → đơn biến mất
    │      └─► FAIL → Snackbar lỗi
    │
    └─► APP ĐANG ĐÓNG HOẶC BACKGROUND
        │
        ② FCM hiện system notification (native OS banner)
           Title: "Đơn hàng mới cần giao!"
           Body: "{storeName} - Phí: {deliveryFee}đ"
           ├─► User tap → Mở app → điều hướng OrderDetailScreen(id)
           │      Hiện dialog: "Bạn có nhận đơn này không?"
           │      ├─► "Nhận" → POST /respond action=accept
           │      └─► "Từ chối" → POST /respond action=decline
           └─► User dismiss notification → App vẫn đóng
              Notification lưu trong Firestore → đọc sau ở màn Notifications
```

---

### 7.4. Luồng 4: Giao đơn hàng (Delivery Flow — Chi tiết theo từng trạng thái)

#### 4A. Status 1 → 2: Xác nhận đã lấy hàng từ cửa hàng

```
[START] → Tài xế nhận đơn thành công, đang ở OrderDetailScreen (status=1)
    │
    ① Hiển thị OrderDetailScreen:
       - Mã đơn (6 ký tự cuối), thông tin cửa hàng, thông tin người nhận
       - Nút "Đã lấy hàng" (PRIMARY, màu xanh lá, nổi bật)
       - Nút "Từ chối đơn" (secondary, màu đỏ nhạt)
       - Nút "Chỉ đường đến cửa hàng" (icon bản đồ)
       - Nút "Gọi cửa hàng" (icon điện thoại) — nếu backend cung cấp
    │
    ② Tài xế đến cửa hàng → nhấn "Đã lấy hàng"
    │
    ③ Hiện dialog xác nhận:
       "Xác nhận đã lấy hàng từ {storeName}?"
       ├─► "Hủy" → Đóng dialog
       └─► "Xác nhận" → bước ④
    │
    ④ Gửi PUT /api/drivers/orders/{id}/status
       Body: { "status": 2 }
       ├─► SUCCESS (200) → bước ⑤
       ├─► 403 FORBIDDEN → "Bạn không phải tài xế của đơn này."
       └─► 400 BAD_REQUEST → "Trạng thái không hợp lệ."
    │
    ⑤ Backend cập nhật: status = 2 (Đang giao)
    │
    ⑥ App cập nhật UI:
       - Status badge: "Đang giao" (màu xanh dương)
       - Nút hành động: "Đã giao hàng" (PRIMARY, xanh lá)
       - Nút "Báo sự cố" (secondary, cam)
       - Nút "Chỉ đường đến người nhận" (icon bản đồ)
       - Nút "Gọi người nhận" (icon điện thoại)
       - Bật GPS tracking realtime cho phép người nhận xem vị trí
       - Snackbar: "Đã xác nhận lấy hàng. Bắt đầu giao!"
```

#### 4B. Status 2 → 3: Xác nhận đã giao hàng thành công

```
[START] → Tài xế đến địa chỉ giao, status=2
    │
    ① Hiển thị OrderDetailScreen:
       - Mã đơn (6 ký tự cuối), thông tin cửa hàng, thông tin người nhận
       - Phí giao hàng (deliveryFee) — hiển thị rất lớn, màu xanh lá, icon ₫
       - Nút "Đã giao hàng" (PRIMARY, màu xanh lá, NỔI BẬT NHẤT)
       - Nút "Báo sự cố" (secondary, cam)
       - Nút "Chỉ đường" (icon bản đồ) → Google Maps
       - Nút "Gọi người nhận" (icon điện thoại)
    │
    ② Tài xế giao hàng xong → nhấn "Đã giao hàng"
    │
    ③ Hiện dialog xác nhận:
       "Xác nhận đã giao hàng cho {receiverName}?"
       "Địa chỉ: {deliveryAddress}"
       ├─► "Hủy" → Đóng dialog
       └─► "Xác nhận" → bước ④
    │
    ④ Gửi PUT /api/drivers/orders/{id}/status
       Body: { "status": 3 }
       ├─► SUCCESS (200) → bước ⑤
       ├─► 403 FORBIDDEN → "Bạn không phải tài xế của đơn này."
       └─► 400 BAD_REQUEST → "Trạng thái không hợp lệ."
    │
    ⑤ Backend tự động:
       - status = 3 (Hoàn thành)
       - Tạo TransactionDTO: type=1 (delivery_income), amount=deliveryFee
       - Cập nhật WalletDTO: balance += deliveryFee, totalEarned += deliveryFee
       - Dừng GPS tracking realtime
    │
    ⑥ App cập nhật UI:
       - Status badge: "Hoàn thành" (màu xanh lá)
       - Nút hành động: disabled, hiển thị "Đã hoàn thành"
       - Dừng GPS service
       - Hiện dialog chúc mừng:
         "Chúc mừng! Bạn đã hoàn thành đơn hàng."
         "Thu nhập: +{deliveryFee}đ"
         "Tổng số dư: {newBalance}đ"
         ├─► "Nhận đơn mới" → điều hướng AvailableOrdersScreen
         └─► "Đóng" → điều hướng OrdersScreen (tab "Đang giao")
       - Snackbar: "Cảm ơn bạn! +{deliveryFee}đ đã được cộng vào ví."
```

#### 4C. Status 2 → 4: Báo sự cố / Hủy đơn khi đang giao

```
[START] → Tài xế gặp sự cố khi đang giao, status=2
    │
    ① Tài xế nhấn "Báo sự cố"
    │
    ② Hiện bottom sheet với danh sách lý do:
       - "Không tìm thấy địa chỉ giao hàng"
       - "Khách hàng không nghe máy"
       - "Cửa hàng đóng cửa / hết hàng"
       - "Tắc đường, giao trễ"
       - "Lý do khác" → TextField nhập thêm
       ├─► "Hủy" → Đóng bottom sheet
       └─► "Tiếp tục" → bước ③
    │
    ③ Hiện dialog xác nhận:
       "Xác nhận hủy đơn hàng #{mã}?"
       "Lý do: {selectedReason}"
       ├─► "Hủy" → Đóng dialog
       └─► "Xác nhận hủy" → bước ④
    │
    ④ Gửi PUT /api/drivers/orders/{id}/status
       Body: { "status": 4 }
       ├─► SUCCESS (200) → bước ⑤
       └─► FAIL → Snackbar lỗi
    │
    ⑤ Backend:
       - status = 4 (Đã hủy)
       - Xóa driverId khỏi order (reset để hệ thống gán lại)
       - Tạo Notification type=13 cho các tài xế khác
    │
    ⑥ App cập nhật UI:
       - Snackbar: "Đã báo cáo sự cố. Đơn hàng đã được hủy."
       - Điều hướng về OrdersScreen
       - Nếu đang ở OrderDetail → pop về danh sách
```

---

### 7.5. Luồng 5: Từ chối đơn hàng (Decline — Manual)

```
[START] → Tài xế xem đơn khả dụng, quyết định không nhận
    │
    ① Tài xế nhấn "Từ chối" trên OrderCard
    │
    ② Hiện dialog nhỏ:
       "Bạn có chắc từ chối đơn hàng #{mã}?"
       ├─► "Hủy" → Đóng dialog
       └─► "Xác nhận từ chối" → bước ③
    │
    ③ Gửi POST /api/drivers/orders/{id}/decline
       ├─► SUCCESS (200) → bước ④
       └─► FAIL → Snackbar lỗi
    │
    ④ Backend ghi decline log (không gán cho tài xế khác tự động)
    │
    ⑤ App: Xóa card với animation slide-out + snackbar "Đã từ chối đơn hàng."
```

---

### 7.6. Luồng 6: Thông báo push (Push Notifications — FCM)

```
[START] → Backend tạo thông báo cho tài xế
    │
    ① Backend ghi Notification vào Firestore collection "notifications"
       type values:
       - 11 = Yêu cầu nhận đơn (auto-assign)
       - 12 = Thông báo giao hàng (order status update)
       - 13 = Đơn đã được tài xế khác nhận (409 conflict)
    │
    ② Backend gửi FCM push notification đến device của tài xế
    │
    ├─► PUSH KHI APP FOREGROUND
    │   │
    │   ③ FCM nhận message → kiểm tra notification type
    │   │
    │   ├─► type=11 (Yêu cầu nhận đơn)
    │   │      Hiện custom in-app banner / bottom sheet
    │   │      Phát âm thanh thông báo (audioplayers)
    │   │      HapticFeedback.heavyImpact()
    │   │      Nút "Nhận" / "Từ chối" → gọi /respond
    │   │      Banner tự động ẩn sau 30 giây nếu không phản hồi
    │   │
    │   ├─► type=12 (Thông báo giao hàng)
    │   │      Hiện snackbar nhỏ: "Đơn #{mã} đã được cập nhật."
    │   │      Refresh OrderDetail nếu đang mở
    │   │
    │   └─► type=13 (Tài xế khác nhận)
    │          Hiện dialog: "Đơn hàng đã được tài xế khác nhận."
    │          Đơn tự động biến mất khỏi danh sách
    │          Nếu đang ở OrderDetail → pop về danh sách
    │
    └─► PUSH KHI APP BACKGROUND / CLOSED
        │
        ③ FCM hiện system notification (native OS banner)
           ├─► User tap → Mở app → xử lý theo type
           │      type=11 → điều hướng OrderDetail + dialog accept/decline
           │      type=12/13 → điều hướng NotificationsScreen
           └─► User swipe dismiss → Notification lưu trong Firestore
              User đọc sau ở màn Notifications
```

**Lưu ý quan trọng:**
- NotificationDTO.field `body` chứa nội dung — **KHÔNG phải `message`**
- Trường `referenceId` thường = `orderId` — dùng để điều hướng

---

### 7.7. Luồng 7: Ví & Rút tiền (Wallet & Withdraw)

```
[START] → Tài xế vào màn Ví
    │
    ① Load ví: GET /api/drivers/wallet
    │   ├─► SUCCESS → Hiển thị số dư nổi bật
    │   └─► FAIL → Error state + retry
    │
    ├─► XEM LỊCH SỬ GIAO DỊCH
    │   │
    │   ② Load giao dịch: GET /api/drivers/transactions?page=0&size=20
    │   │   ├─► SUCCESS → Hiển thị ListView
    │   │   │       ├─► type=1 (delivery_income): icon ↑ màu xanh lá, "+{amount}đ"
    │   │   │       ├─► type=2 (withdrawal): icon ↓ màu đỏ, "-{amount}đ"
    │   │   │       └─► type=3 (refund): icon ↩ màu cam, "+{amount}đ"
    │   │   │   Pull-to-refresh → reload page 0
    │   │   │   Infinite scroll → page++ khi cuộn đến cuối
    │   │   └─► FAIL → Snackbar lỗi
    │   │
    │   ③ Tap transaction item:
    │      Hiện bottom sheet chi tiết:
    │      - Mô tả: description
    │      - Số tiền: {amount}đ
    │      - Phí: {fee}đ
    │      - Thực nhận: {netAmount}đ
    │      - Trạng thái: badge (0=pending, 1=completed, 2=failed)
    │      - Thời gian: formatted createdAt
    │      - Mã đơn: orderId (nếu là delivery_income)
    │
    └─► RÚT TIỀN
        │
        ② Nhấn nút "Rút tiền" (chỉ hiện khi balance >= 50000)
        │   Nếu balance < 50000 → nút disabled + tooltip "Số dư tối thiểu 50.000đ"
        │
        ③ Hiện bottom sheet nhập số tiền:
           - Input số tiền rút (VND), formatter số tự động thêm dấu chấm
           - Số dư khả dụng: {balance}đ (tap để điền max)
           - Phí rút: 0đ (miễn phí)
           - Số tiền nhận được: {amount}đ (= amount - fee)
           - Thông tin ngân hàng (từ WalletDTO):
             - {bankName}
             - {bankAccountNumber} (mask: ****1234)
             - {bankAccountName}
           - Nút chọn nhanh: "50K", "100K", "200K", "500K", "Tất cả"
           ├─► "Hủy" → Đóng bottom sheet
           └─► "Xác nhận rút tiền" → bước ④
        │
        ④ Validation client-side:
           ├─► amount < 50000 → "Số tiền tối thiểu là 50.000đ"
           ├─► amount > balance → "Số dư không đủ"
           ├─► bankAccountNumber == null → "Bạn chưa liên kết ngân hàng. Vui lòng cập nhật trong Hồ sơ."
           └─► PASS → bước ⑤
        │
        ⑤ Gửi POST /api/drivers/withdraw
           Body: { "amount": 50000 }
           ├─► SUCCESS (200) → bước ⑥
           ├─► 400 BAD_REQUEST → "Số dư không đủ" / "Vượt giới hạn rút"
           └─► 404 NOT_FOUND → "Không tìm thấy ví"
        │
        ⑥ Backend tạo TransactionDTO: type=2 (withdrawal), status=0 (pending)
           Backend cập nhật WalletDTO: balance -= amount, pendingBalance += amount
        │
        ⑦ Hiện dialog thành công:
           "Yêu cầu rút tiền thành công!"
           "Số tiền: {amount}đ"
           "Ngân hàng: {bankName}"
           "Sẽ được xử lý trong 1-3 ngày làm việc."
           "Trạng thái: Đang chờ xử lý"
           └─► "Đóng" → refresh ví + giao dịch
```

---

### 7.8. Luồng 8: Thống kê tài xế (Driver Stats)

```
[START] → Tài xế mở app / vào màn Orders
    │
    ① Load profile: GET /api/drivers/profile
    │   └─► Lấy: todayTrips, todayEarnings, totalTrips, rating
    │
    ② Hiển thị sticky header stats:
       - Hôm nay: {todayTrips} đơn | Thu nhập: {todayEarnings}đ
       - Tổng: {totalTrips} đơn | Rating: ★{rating}/5.0
    │
    ③ Mỗi khi có đơn hoàn thành (status 3):
       - todayTrips += 1
       - todayEarnings += deliveryFee
       - Animate số thu nhập (count-up animation)
```

---

## 8. Yêu cầu giao diện từng màn hình

### 8.1. Màn hình Tổng hợp Đơn hàng (Driver Orders Tab)

**Route:** `/driver/orders` (tab thứ 2 trong Bottom Navigation Bar)

**Giao diện:**
- **AppBar:** "Đơn hàng của tôi" + icon thông báo (chuông) + badge số chưa đọc
- **Sticky Header Stats:** 2 card nằm ngang
  - Card trái: "Hôm nay" + `{todayTrips}` đơn + `{todayEarnings}`đ (màu xanh lá)
  - Card phải: "Tổng" + `{totalTrips}` đơn + "★{rating}"
- **Chip filter:** "Tất cả" | "Đang giao" | "Hoàn thành" | "Đã hủy"
- **Danh sách đơn:** ListView, mỗi item là OrderCard
  - Tap → điều hướng OrderDetailScreen
  - Swipe left → quick actions (xem nhanh)
- **FAB (Floating Action Button):** icon "+" / icon xe → điều hướng AvailableOrdersScreen
  - Chỉ hiện khi tài xế **Online**
  - Khi Offline: ẩn FAB hoặc hiện mờ + tooltip "Bật online để nhận đơn"
- **Pull-to-refresh:** Refresh tất cả dữ liệu (profile + orders)
- **Empty state:** Icon đơn hàng rỗng + "Chưa có đơn hàng nào"

**Logic lọc API:**
| Chip | API gọi |
|---|---|
| Tất cả | Gọi `/active` + `/history` gộp lại, sort theo createdAt desc |
| Đang giao | `GET /api/drivers/orders/active` |
| Hoàn thành | `GET /api/drivers/orders/history` (lọc status=3) |
| Đã hủy | `GET /api/drivers/orders/history` (lọc status=4) |

---

### 8.2. Màn hình Đơn hàng Khả dụng (Available Orders Screen)

**Route:** `/driver/orders/available`

**Giao diện:**
- **AppBar:** "Đơn hàng khả dụng" + icon refresh (manual fetch) + icon sound toggle
- **Sound toggle:** Bật/tắt âm thanh thông báo đơn mới (lưu vào SharedPreferences)
- **Thông tin tóm tắt:** "Có {n} đơn hàng chờ bạn" (hiển thị khi n > 0)
- **Danh sách đơn:** ListView, mỗi AvailableOrderCard gồm:
  - **Header:** Icon cửa hàng + `storeName` (font lớn, bold)
  - **Body:**
    - `storeAddress` (icon địa chỉ, màu xám, 2 dòng max)
    - `deliveryAddress` (icon giao hàng, màu cam)
    - Danh sách món (collapsible, hiển thị 2 món đầu + "Xem thêm X món")
    - Phí giao: `deliveryFee` — **NỔI BẬT NHẤT**, font lớn, xanh lá
    - Tổng tiền: `totalAmount`đ (font nhỏ, xám)
  - **Footer:** Nút "Nhận đơn" (PRIMARY, full width) + Nút "Từ chối" (text button)
- **Pull-to-refresh:** Refresh danh sách
- **Auto-refresh:** Polling `GET /available` mỗi 10-15 giây khi screen đang hiển thị
- **Empty state:** Hình minh họa xe máy + "Không có đơn hàng nào khả dụng"

**Logic:**
- Nhấn "Nhận đơn" → dialog xác nhận → `POST /accept`
- Nhấn "Từ chối" → dialog xác nhận → `POST /decline` → animation xóa card
- Khi polling có đơn mới → phát âm thanh + HapticFeedback + animation slide-in card mới
- Khi đơn bị tài xế khác nhận (409) → card biến mất với animation + snackbar

---

### 8.3. Màn hình Chi tiết Đơn hàng (Order Detail Screen)

**Route:** `/driver/orders/detail/:id` — nhận `orderId` từ route param

**Giao diện - chia thành 6 sections:**

**Section 1: Thông tin cửa hàng**
- Icon cửa hàng + `storeName` (font lớn, bold)
- Địa chỉ `storeAddress` (tap để copy clipboard)
- Tọa độ: `storeLat`, `storeLng`
- Nút **"Chỉ đường"** (Google Maps):
  - URL: `https://www.google.com/maps/dir/?api=1&destination={storeLat},{storeLng}`
  - Dùng `url_launcher` để mở

**Section 2: Thông tin người nhận**
- Icon người + `receiverName` (ẩn 1 phần: "Ng*** Van A")
- Địa chỉ giao `deliveryAddress` (font normal, 2 dòng)
- Tọa độ: `deliveryLat`, `deliveryLng`
- Nút **"Chỉ đường"** (Google Maps) → đến deliveryLat/lng
- Nút **"Gọi người nhận"** → `url_launcher` với scheme `tel:{receiverPhone}`

**Section 3: Danh sách món ăn**
- ListView từng `OrderItemData`:
  - Ảnh thumbnail (60×60, border-radius 8, có fallback icon)
  - Tên món `name` (bold)
  - Số lượng × đơn giá: "`{quantity}` × `{price}`đ"
  - Options hiển thị: "+ Tran chau: 5.000đ" (màu xám, font nhỏ)
  - Divider giữa các món
- Tổng tiền: `totalAmount`đ (font bold, gạch ngang nếu có giảm giá)

**Section 4: Thông tin thanh toán**
- Phương thức: icon + text ("Tiền mặt", "MoMo", "ZaloPay", "VNPay")
- Trạng thái thanh toán: badge ("Đã thanh toán" / "Chưa thanh toán")
- **Phí giao hàng (THU NHẬP):** `deliveryFee` — **HIỂN THỊ RẤT LỚN**, màu xanh lá, icon ₫
- Ghi chú `note`: hiển thị với icon ⚠️, nền vàng nhạt, border vàng

**Section 5: Thông tin đơn**
- Mã đơn: **6 ký tự cuối** của `id` — font very large (28sp), bold, màu primary
- Thời gian tạo: format "Hôm nay HH:mm" hoặc "dd/MM HH:mm"
- Trạng thái: StatusBadge với màu theo bảng trạng thái

**Section 6: Hành động (Action Buttons)**

| Status | Nút Primary | Nút Secondary | Icon chỉ đường | Icon gọi |
|---|---|---|---|---|
| 0 (Chờ xác nhận) | Disabled: "Chờ cửa hàng xác nhận" | — | ✅ | ✅ |
| 1 (Đang chuẩn bị) | "Đã lấy hàng" (xanh lá) | "Từ chối" (đỏ nhạt) | ✅ (cửa hàng) | ✅ (cửa hàng) |
| 2 (Đang giao) | "Đã giao hàng" (xanh lá, NỔI BẬT) | "Báo sự cố" (cam) | ✅ (người nhận) | ✅ (người nhận) |
| 3 (Hoàn thành) | Disabled: "Đã hoàn thành" (xám) | — | ✅ | ✅ |
| 4 (Đã hủy) | Disabled: "Đã hủy" (đỏ) | — | ✅ | ✅ |

---

### 8.4. Màn hình Thông báo (Notifications Screen)

**Route:** `/driver/notifications`

**Giao diện:**
- **AppBar:** "Thông báo" + nút "Đánh dấu đã đọc tất cả" (icon checkmark-all)
  - Chỉ hiện khi có thông báo chưa đọc
- **Danh sách thông báo:** ListView, mỗi NotificationItem:
  - Icon theo type (11=motorcycle_delivery, 12=local_shipping, 13=warning, khác=info)
    - type=11: icon xe máy, màu xanh dương
    - type=12: icon giao hàng, màu xanh lá
    - type=13: icon warning, màu đỏ
  - Tiêu đề `title` (bold nếu chưa đọc, normal nếu đã đọc)
  - Nội dung `body` (màu xám, 2 dòng max)
  - Thời gian: "5 phút trước", "Hôm nay 14:30", "02/06 14:30" (dùng intl package)
  - Badge chấm đỏ nhỏ trên góc phải nếu `isRead == false`
  - Swipe left → nút xóa đỏ → `DELETE /{id}`
- **Tap item:**
  - Nếu có `orderId` (hoặc `referenceId`): điều hướng OrderDetailScreen → đánh dấu đã đọc
  - Nếu không có orderId: chỉ đánh dấu đã đọc → cập nhật badge
- **Pull-to-refresh:** Refresh danh sách
- **Empty state:** Icon chuông + "Chưa có thông báo nào"

**Lưu ý quan trọng:**
- NotificationDTO dùng field **`body`** chứa nội dung — **KHÔNG phải `message`**
- Field `referenceId` thường = `orderId` — dùng để điều hướng

---

### 8.5. Màn hình Ví Tài xế (Wallet Screen)

**Route:** `/driver/wallet`

**Giao diện:**
- **AppBar:** "Ví của tôi" (không có back button nếu là tab)
- **Balance Card** (Gradient background, nổi bật):
  - Label: "Số dư khả dụng"
  - Số dư: `{balance}đ` — font very large (36sp+), bold, white
  - Nút "Rút tiền" (màu trắng, border-radius full)
    - Disabled nếu balance < 50000, kèm tooltip
- **Stats Row:** 3 item nằm ngang (cách đều):
  - "Tổng thu nhập" / `{totalEarned}đ` (xanh lá)
  - "Đang chờ" / `{pendingBalance}đ` (cam)
  - "Đã rút" / `{totalWithdrawn}đ` (xám)
- **Thông tin ngân hàng:**
  - Nếu đã liên kết: icon ngân hàng + `{bankName}` + số TK mask "••••{last4digits}"
  - Nếu chưa: Card nền cam nhạt + icon warning + "Bạn chưa liên kết ngân hàng" + nút "Liên kết ngay"
- **Danh sách giao dịch:**
  - Tab bar: "Tất cả" | "Thu nhập" | "Rút tiền"
  - ListView TransactionDTO
  - Mỗi item:
    - Icon ↑ (income=xanh lá), ↓ (withdrawal=đỏ), ↩ (refund=cam)
    - Mô tả: `description` (VD: "Thu nhập giao đơn #{mã}")
    - Số tiền: `+{amount}đ` (income/refund), `-{amount}đ` (withdrawal)
    - Thời gian: formatted `createdAt`
    - Status badge: pending=xám, completed=xanh lá, failed=đỏ
  - Pull-to-refresh
  - Infinite scroll phân trang (page++ khi cuộn đến cuối)
  - Empty state theo tab

---

### 8.6. Màn hình Rút tiền (Withdraw Screen)

**Route:** `/driver/wallet/withdraw`

**Giao diện:**
- **AppBar:** "Rút tiền" + back button
- **Số dư hiện tại:** `{balance}đ` (hiển thị lớn ở đầu, màu xám)
- **Input số tiền:**
  - TextField với formatter tự động thêm dấu chấm phân cách (VD: "50.000")
  - Icon ₫ ở bên phải
  - Nút chọn nhanh: chip buttons "50K" | "100K" | "200K" | "500K" | "Tất cả"
  - Khi tap "Tất cả" → điền balance vào input
- **Thông tin nhận tiền:**
  - Tên ngân hàng: `{bankName}`
  - Số tài khoản: `{bankAccountNumber}` (mask: "•••• •••• •••• 1234")
  - Tên chủ TK: `{bankAccountName}`
- **Chi tiết:**
  - Số tiền rút: `{amount}đ`
  - Phí rút: `0đ` (miễn phí)
  - Số tiền nhận được: `{amount}đ`
- **Validation:**
  - amount < 50000 → error text "Số tiền tối thiểu: 50.000đ"
  - amount > balance → error text "Số dư không đủ"
  - bankAccountNumber == null → disabled button + text "Bạn chưa liên kết ngân hàng"
- **Nút "Xác nhận rút tiền"** (disabled nếu validation fail)
- **Lưu ý:** Text nhỏ bên dưới: "Yêu cầu sẽ được xử lý trong 1-3 ngày làm việc."

---

## 9. Ràng buộc kỹ thuật

| Thành phần | Yêu cầu |
|---|---|
| **Framework** | Flutter (StatelessWidget + StatefulWidget thuần, không code generation phức tạp) |
| **State Management** | Provider hoặc BLoC (thống nhất với project) |
| **HTTP Client** | dio (interceptor tự động gắn JWT, handle 401 → redirect login) |
| **Navigation** | go_router hoặc Navigator 2.0 thuần |
| **Maps** | url_launcher (Google Maps URL scheme) |
| **Phone** | url_launcher (`tel:` scheme) |
| **Date/Time** | intl package (format "5 phút trước", "Hôm nay 14:30", "02/06 14:30") |
| **Push Notifications** | firebase_messaging (FCM) |
| **Background GPS** | flutter_background_service + geolocator |
| **Permissions** | permission_handler |
| **Local Storage** | shared_preferences (token, driverId, sound toggle, cached orders) |
| **Secure Storage** | flutter_secure_storage (JWT credentials — KHÔNG dùng shared_preferences cho token) |
| **Audio** | audioplayers (thông báo đơn mới) |
| **Haptic** | Flutter services (HapticFeedback.heavyImpact() khi nhấn nút quan trọng) |
| **Pull-to-refresh** | RefreshIndicator cho mọi danh sách |
| **Loading** | Shimmer skeleton (2-3 placeholder cards) |
| **Error** | Snackbar cho lỗi thường, dialog cho lỗi nghiêm trọng (409, 403) |
| **Empty State** | SVG/PNG placeholder + message theo ngữ cảnh |
| **Polling** | Timer.periodic 10-15s cho danh sách đơn khả dụng khi online |
| **Confirm Dialog** | Luôn hỏi xác nhận trước khi action irreversible (nhận đơn, giao hàng, hủy) |
| **Count-up animation** | Thu nhập tăng → animate số (dùng flutter_countup) |

---

## 10. Cấu trúc thư mục đề xuất

```
lib/
├── main.dart
├── config/
│   ├── api_config.dart              # Base URL, headers, dio instance
│   ├── app_theme.dart               # Colors, typography, constants
│   └── app_routes.dart              # go_router route definitions
├── models/
│   ├── delivery_order_model.dart    # DeliveryOrderDTO + nested OrderItemData, OptionData
│   ├── notification_model.dart      # NotificationDTO
│   ├── wallet_model.dart            # WalletDTO
│   ├── transaction_model.dart        # TransactionDTO
│   ├── driver_profile_model.dart     # DeliveryProfileDTO
│   └── requests/
│       ├── delivery_status_request.dart     # PUT /drivers/status
│       ├── delivery_location_request.dart    # POST /drivers/location
│       ├── delivery_respond_request.dart     # POST /orders/{id}/respond
│       ├── delivery_order_status_request.dart # PUT /orders/{id}/status
│       └── withdraw_request.dart              # POST /withdraw
├── services/
│   ├── api_service.dart             # Dio + JWT interceptor (auto-add Bearer token)
│   ├── auth_service.dart            # Token management (get/set/clear token)
│   ├── order_service.dart           # Tất cả API orders
│   ├── notification_service.dart     # Notifications API
│   ├── wallet_service.dart          # Wallet & transactions API
│   ├── driver_service.dart          # Profile, status, vehicle API
│   └── location_service.dart        # GPS + Realtime DB update
├── providers/
│   ├── auth_provider.dart           # Login state, token
│   ├── driver_provider.dart         # Profile, isActive, online/offline
│   ├── order_provider.dart          # Danh sách đơn hàng + polling
│   ├── order_detail_provider.dart   # Chi tiết 1 đơn + status update
│   ├── notification_provider.dart   # Notifications state + badge count
│   └── wallet_provider.dart         # Ví + giao dịch + withdraw
├── screens/
│   └── driver/
│       ├── driver_main_screen.dart   # Bottom nav + tab views
│       ├── orders/
│       │   ├── orders_screen.dart         # Tab tổng hợp
│       │   ├── available_orders_screen.dart
│       │   ├── order_detail_screen.dart
│       │   └── widgets/
│       │       ├── order_card.dart
│       │       ├── available_order_card.dart
│       │       ├── order_status_badge.dart
│       │       ├── order_action_buttons.dart
│       │       ├── order_store_info.dart
│       │       ├── order_recipient_info.dart
│       │       └── order_items_list.dart
│       ├── wallet/
│       │   ├── wallet_screen.dart
│       │   ├── withdraw_screen.dart
│       │   └── widgets/
│       │       ├── balance_card.dart
│       │       ├── wallet_stats_row.dart
│       │       ├── transaction_item.dart
│       │       └── withdraw_form.dart
│       ├── notifications/
│       │   ├── notifications_screen.dart
│       │   └── widgets/
│       │       └── notification_item.dart
│       └── profile/
│           └── driver_profile_screen.dart
└── utils/
    ├── formatters.dart              # Currency (VND), date/time formatters
    ├── constants.dart               # Status codes, colors, strings
    ├── validators.dart              # Form validators
    └── helpers.dart                 # URL helpers, phone dialer, map opener
```

---

## 11. Một số lưu ý quan trọng

1. **deliveryFee** luôn hiển thị **NỔI BẬT NHẤT** màu xanh lá, font lớn — đây là thu nhập tài xế.
2. **Mã đơn hàng**: Hiển thị **6 ký tự cuối** của UUID để dễ đọc và xác nhận với cửa hàng/khách.
3. **Polling khi online**: Khi tài xế online, polling `GET /available` mỗi 10-15s. Khi app minimize, dùng FCM push thay vì polling.
4. **GPS Background**: Khi online, GPS chạy ở background (`flutter_background_service`) mỗi 5-10s, gửi `POST /location`.
5. **Âm thanh thông báo**: Phát âm thanh khi có đơn mới (dùng `audioplayers`), kèm `HapticFeedback.heavyImpact()`.
6. **JWT Token**: Lưu trong `flutter_secure_storage`, KHÔNG dùng `shared_preferences` cho credentials.
7. **409 Conflict**: Khi nhận đơn mà tài xế khác đã nhận → hiện dialog "Đơn đã được tài xế khác nhận", xóa card với animation.
8. **NotificationDTO**: Field chứa nội dung là **`body`**, KHÔNG phải `message`. Field tham chiếu là **`referenceId`**, KHÔNG phải `data`.
9. **DriverId từ JWT**: Tất cả API dùng driverId từ token — KHÔNG hardcode, KHÔNG truyền trong URL.
10. **Confirm Dialog**: Luôn hỏi xác nhận trước khi: nhận đơn, xác nhận lấy hàng, xác nhận giao hàng, hủy đơn.
11. **Offline graceful**: Khi không có mạng, hiển thị cached data từ local storage.
12. **Status 0**: Khi đơn ở status=0 (Chờ xác nhận), tài xế chỉ xem được thông tin, không có action.
