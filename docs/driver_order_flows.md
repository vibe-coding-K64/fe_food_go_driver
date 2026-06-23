# Prompt: Luồng Hoạt Động Đơn Hàng Tài Xế — Chi Tiết Từng Bước

## Mục lục

1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Luồng 1 — Toggle Online/Offline](#2-luồng-1--toggle-onlineoffline)
3. [Luồng 2 — Nhận đơn hàng (tự chọn)](#3-luồng-2--nhận-đơn-hàng-tự-chọn)
4. [Luồng 3 — Hệ thống gán đơn tự động](#4-luồng-3--hệ-thống-gán-đơn-tự-động)
5. [Luồng 4 — Giao đơn hàng (trạng thái)](#5-luồng-4--giao-đơn-hàng-trạng-thái)
6. [Luồng 5 — Thông báo Push (WebSocket)](#6-luồng-5--thông-báo-push-websocket)
7. [Luồng 6 — Ví & Rút tiền](#7-luồng-6--ví--rút-tiền)
8. [Luồng 7 — Từ chối đơn hàng](#8-luồng-7--từ-chối-đơn-hàng)
9. [Luồng 8 — GPS Realtime](#9-luồng-8--gps-realtime)
10. [Bảng mã trạng thái & loại](#10-bảng-mã-trạng-thái--loại)

---

## 1. Tổng quan kiến trúc

### 1.1. Sơ đồ luồng đơn hàng tổng quan

```
Khách đặt món
     │
     ▼
┌─────────────────┐
│ Order status = 0 │  PENDING — chờ cửa hàng xác nhận
└────────┬────────┘
         │ cửa hàng xác nhận
         ▼
┌─────────────────┐
│ Order status = 1 │  PREPARING — đang chuẩn bị
└────────┬────────┘
         │ OrderAssignmentService tìm tài xế trong bán kính 5km
         ▼
┌─────────────────────────────────────────────┐
│  Gửi WebSocket Push Notification (type=11) │
│  Tạo order_requests trong database          │
└────────┬────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────┐
│           TÀI XẾ NHẬN ĐƯỢC NOTIFICATION           │
│  ┌─────────────────────────────────────────────┐ │
│  │  in-app banner / system notification         │ │
│  │  "Bạn có đơn hàng mới!"                   │ │
│  │  "{storeName} - Phí: {deliveryFee}đ"        │ │
│  │  [Nhận đơn]  [Từ chối]                    │ │
│  └─────────────────┬───────────────────────────┘ │
│                    │                              │
│          ┌─────────┴──────────┐                 │
│          ▼                    ▼                  │
│   Tài xế nhấn ACCEPT    Tài xế nhấn DECLINE    │
│          │                    │                  │
│          ▼                    ▼                  │
│   POST /respond           POST /respond         │
│   action=accept           action=decline        │
│          │                    │                  │
│          ▼                    ▼                  │
│   order.driverId = me    Đơn được gán           │
│   status = 1             tài xế khác           │
│          │                                      │
         ▼
┌─────────────────────────────┐
│ Order status = 2            │  DELIVERING — đang giao
│ driverId = current_driver   │
└────────┬────────────────────┘
         │ tài xế bấm "Đã giao hàng"
         ▼
┌─────────────────────────────┐
│ Order status = 3            │  COMPLETED — hoàn thành
│ Tạo Transaction (type=1)   │  Wallet.balance += deliveryFee
│ Wallet.totalEarned += fee   │
└─────────────────────────────┘
```

### 1.2. Vai trò các thành phần

| Thành phần | Vai trò |
|---|---|
| **Database `orders/{id}`** | Lưu trữ đơn hàng chính |
| **Realtime Database `/active_drivers/{id}`** | Vị trí GPS tài xế đang online |
| **Realtime Database `/orders/{id}/status`** | Sync trạng thái để listener theo dõi |
| **Database `order_requests/{id}`** | Yêu cầu nhận đơn — danh sách tài xế được gán |
| **Database `driver_profiles/{id}/notifications`** | Thông báo của tài xế |
| **OrderAssignmentService** | Tự động tìm tài xế khi có đơn mới |
| **DriverLocationMonitorService** | Tự động offline tài xế nếu không cập nhật GPS > 60s |

### 1.3. Nguyên tắc thiết kế giao diện tài xế

- **Ưu tiên tốc độ**: Tài xế cần thao tác nhanh, tối thiểu 3 tap để nhận đơn
- **Thông tin tối giản**: Hiển thị vừa đủ, không scroll nhiều
- **Xác nhận trước hành động**: Luôn hỏi dialog trước khi accept/complete/cancel
- **Feedback tức thì**: Snackbar, animation, haptic khi có sự kiện
- **Offline-first**: Hiển thị cached data khi không có mạng
- **Realtime**: GPS + polling đơn mới khi online

---

## 2. Luồng 1 — Toggle Online/Offline

### 2.1. Sơ đồ

```
Tài xế bật/tắt toggle Online
         │
         ├─► BẬT ONLINE
         │   │
         │   ① App kiểm tra GPS permission
         │   │
         │   ├─► CHƯA CÓ permission
         │   │   └─► Hiện dialog xin quyền truy cập vị trí
         │   │       ├─► User GRANT → bước ②
         │   │       └─► User DENY → Snackbar "Cần quyền GPS" → dừng
         │   │
         │   ├─► ĐÃ CÓ permission
         │   │   └─► bước ②
         │   │
         │   ② Lấy tọa độ GPS hiện tại
         │   │   (lat, lng, heading, speed)
         │   │
         │   ③ PUT /api/drivers/status
         │   │   Body: { "isActive": true, "lat": 10.85, "lng": 106.79,
         │   │           "heading": 90, "speed": 30 }
         │   │
         │   ├─► 200 SUCCESS → bước ④
         │   └─► FAIL → Snackbar lỗi + rollback toggle về OFF
         │   │
         │   ④ Backend thực hiện:
         │   │   - DriverProfile.isActive = true
         │   │   - Realtime DB: /active_drivers/{driverId}
         │   │       { lat, lng, heading, lastUpdate: now }
         │   │
         │   ⑤ App cập nhật UI:
         │   │   - Toggle ON, màu xanh lá
         │   │   - Icon online glow
         │   │   - Badge "Online"
         │   │
         │   ⑥ Bắt đầu background services:
         │   │   ├─► GPS Service: cập nhật mỗi 5-10s
         │   │   │       POST /api/drivers/location
         │   │   │       Body: { lat, lng, heading, speed }
         │   │   │
         │   │   └─► Polling Service: kiểm tra đơn mới mỗi 10-15s
         │   │           GET /api/drivers/orders/available
         │   │
         │   ⑦ Snackbar: "Bạn đã online. Sẵn sàng nhận đơn!"
         │
         └─► TẮT ONLINE
             │
             ① PUT /api/drivers/status
             │   Body: { "isActive": false }
             │
             ├─► 200 SUCCESS → bước ②
             └─► FAIL → Snackbar lỗi + rollback toggle về ON
             │
             ② Backend:
             │   - DriverProfile.isActive = false
             │   - Xóa /active_drivers/{driverId}
             │
             ③ App:
             │   - Toggle OFF, màu xám
             │   - Icon offline mờ
             │   - Dừng GPS Service
             │   - Dừng Polling Service
             │
             ④ Snackbar: "Bạn đã offline."
```

### 2.2. Request body chi tiết

**Bật online** — `PUT /api/drivers/status`:
```json
{
  "isActive": true,
  "lat": 10.8500,
  "lng": 106.7900,
  "heading": 90.0,
  "speed": 30.0
}
```

**Tắt online** — `PUT /api/drivers/status`:
```json
{
  "isActive": false
}
```

### 2.3. Lưu ý quan trọng

- **BẮT BUỘC gửi lat/lng khi isActive=true** — backend sẽ reject nếu thiếu
- Khi app bị kill, GPS background vẫn chạy nếu user cho phép (`flutter_background_service`)
- Nếu không lấy được GPS trong 10 giây → vẫn cho online nhưng cảnh báo

---

## 3. Luồng 2 — Nhận đơn hàng (tự chọn)

### 3.1. Sơ đồ

```
Tài xế mở màn "Đơn khả dụng"
         │
         ▼
① GET /api/drivers/orders/available
    │
    ├─► Có đơn → Hiển thị danh sách AvailableOrderCard
    │   Mỗi card có: storeName, deliveryAddress, deliveryFee, items
    │
    └─► Không đơn → Empty state "Không có đơn hàng nào"
         │
         ▼
Tài xế nhấn "Nhận đơn" trên card X
         │
         ▼
② Dialog xác nhận
    Tiêu đề: "Xác nhận nhận đơn?"
    Nội dung:
      - Mã đơn: #{6 ký tự cuối}
      - Cửa hàng: {storeName}
      - Phí giao: {deliveryFee}đ
    ├─► "Hủy" → Đóng dialog
    └─► "Xác nhận" → bước ③
         │
         ▼
③ POST /api/drivers/orders/{id}/accept
    │
    ├─► 200 SUCCESS
    │   Backend thực hiện (Database Transaction):
    │     - order.driverId = currentDriver
    │     - order.driverName = driver.fullName
    │     - order.driverPhone = driver.phoneNumber
    │     - order.vehiclePlate = driver.vehiclePlate
    │     - order.status = 1 (Đang chuẩn bị)
    │     - Tạo Notification type=11 cho tài xế
    │
    │   App nhận response (DeliveryOrderDTO đã cập nhật)
    │
    │   Dialog thành công:
    │     "Bạn đã nhận đơn thành công!"
    │     "Cửa hàng: {storeName}"
    │     "Phí giao: {deliveryFee}đ"
    │     ├─► "Xem chi tiết" → OrderDetailScreen(id)
    │     └─► "Đóng" → refresh danh sách khả dụng
    │
    │   Card biến mất khỏi danh sách khả dụng
    │   (vì driverId đã được gán, không còn thỏa driverId == null)
    │
    ├─► 409 CONFLICT
    │   "Đơn hàng đã được tài xế khác nhận."
    │   Dialog thông báo → card biến mất với animation
    │
    ├─► 404 NOT_FOUND
    │   "Không tìm thấy đơn hàng."
    │   Card biến mất → snackbar lỗi
    │
    └─► 403 FORBIDDEN
        "Bạn không có quyền thực hiện."
        Snackbar lỗi
```

### 3.2. Các trường hợp đặc biệt

| Tình huống | Hành xử |
|---|---|
| Nhấn nhận đơn đang load | Disable nút, hiện loading spinner |
| Đơn bị tài xế khác nhận lúc đang xác nhận | Nhận 409 → hiện dialog "Đơn đã được nhận" |
| Nhấn "Xác nhận" nhiều lần | Disable nút sau lần đầu, chỉ gửi 1 request |
| Mất mạng khi xác nhận | Snackbar lỗi mạng + enable lại nút |

### 3.3. AvailableOrderCard — thông tin hiển thị

```
┌──────────────────────────────────────────┐
│ 🍽️ {storeName}                          │
│ 📍 {storeAddress}                       │
│ 📦 → {deliveryAddress}                   │
│                                          │
│ ┌────────────────────────────────────────┐│
│ │ 📋 Bún bò Huế (x2)                    ││
│ │    + Trứng: 5.000đ                     ││
│ │ 📋 Bánh flan (x1)                     ││
│ └────────────────────────────────────────┘│
│                                          │
│ 💰 Phí giao: {deliveryFee}đ  ← NỔI BẬT  │
│    Tổng đơn: {totalAmount}đ             │
│                                          │
│ ┌──────────────────────────────────────┐ │
│ │         [ NHẬN ĐƠN ]  (PRIMARY)      │ │
│ └──────────────────────────────────────┘ │
│           [ Từ chối ]   (TEXT)          │
└──────────────────────────────────────────┘
```

---

## 4. Luồng 3 — Hệ thống gán đơn tự động

### 4.1. Sơ đồ tổng thể phía backend

```
Order mới (status = 1)
        │
        ▼
OrderAssignmentService phát hiện order mới trên RTDB
        │
        ▼
① Tính khoảng cách Haversine từ cửa hàng đến các tài xế
   Điều kiện lọc:
   - driver.isActive == true
   - Khoảng cách ≤ 5km
   - Chênh lệch heading ≤ 45 độ
        │
        ▼
② Tạo document: order_requests/{orderId}
   {
     targetDriverIds: [driver1, driver2, ...],
     acceptedDriverId: null,
     status: "PENDING",
     expiresAt: now + 10 giây
   }
        │
        ▼
③ Gửi WebSocket Push Notification đến tất cả target drivers
   Notification type=11
   Title: "Bạn có đơn hàng mới!"
   Body: "{storeName} - Phí: {deliveryFee}đ"
        │
        ▼
④ Đợi phản hồi trong 10 giây
   ├─► Có tài xế nhấn ACCEPT trước
   │   acceptedDriverId = driver_id
   │   → Gán đơn cho tài xế đó
   │   → Thông báo các tài xế khác: "Đơn đã được nhận"
   │
   └─► Không ai accept sau 10 giây
       Tìm tài xế tiếp theo gần nhất (bán kính 5-10km)
       → Lặp lại bước ②-④
```

### 4.2. Sơ đồ phía app — khi nhận WebSocket

```
WebSocket nhận Push Notification (type=11)
         │
         ├─► APP ĐANG FOREGROUND (đang mở)
         │   │
         │   ① Kiểm tra notification type = 11
         │   │
         │   ② Hiện custom in-app banner (overlay trên cùng màn hình)
         │   │   ┌──────────────────────────────────────────────┐
         │   │   │  🛵 Bạn có đơn hàng mới!                   │
         │   │   │  {storeName}                                │
         │   │   │  Phí giao: {deliveryFee}đ                  │
         │   │   │  → {deliveryAddress}                       │
         │   │   │  [ NHẬN ĐƠN ]    [ TỪ CHỐI ]             │
         │   │   └──────────────────────────────────────────────┘
         │   │
         │   ③ Phát âm thanh thông báo (audioplayers)
         │   ④ HapticFeedback.heavyImpact()
         │   ⑤ Banner auto-dismiss sau 30 giây nếu không phản hồi
         │   │
         │   ├─► Tài xế nhấn "Nhận đơn"
         │   │   │
         │   │   ⑥ POST /api/drivers/orders/{id}/respond
         │   │       Body: { "action": "accept" }
         │   │       │
         │   │       ├─► 200 SUCCESS
         │   │       │   Dialog thành công
         │   │       │   → Điều hướng OrderDetailScreen(id)
         │   │       │   Banner đóng
         │   │       │
         │   │       ├─► 409 CONFLICT
         │   │       │   "Đơn đã được tài xế khác nhận."
         │   │       │   Banner đóng → snackbar
         │   │       │
         │   │       └─► 403 FORBIDDEN
         │   │           "Yêu cầu đã hết hạn."
         │   │           Banner đóng
         │   │
         │   └─► Tài xế nhấn "Từ chối"
         │       │
         │       ⑥ POST /api/drivers/orders/{id}/respond
         │           Body: { "action": "decline" }
         │           ├─► 200 SUCCESS → Banner đóng
         │           └─► FAIL → Snackbar lỗi
         │
         └─► APP ĐANG BACKGROUND hoặc ĐÓNG
             │
             ① WebSocket hiện SYSTEM NOTIFICATION (native OS)
             │   Title: "🛵 Đơn hàng mới cần giao!"
             │   Body: "{storeName} - Phí: {deliveryFee}đ"
             │
             ├─► User TAP vào notification
             │   App mở → điều hướng OrderDetailScreen(id)
             │   │
             │   Hiện dialog accept/decline:
             │     "Bạn có đơn hàng được gán tự động."
             │     "{storeName} - Phí: {deliveryFee}đ"
             │     ├─► "Nhận đơn" → POST /respond action=accept
             │     └─► "Từ chối" → POST /respond action=decline
             │
             └─► User SWIPE DISMISS (xóa notification)
                 Notification vẫn lưu trong database
                 → Đọc sau ở màn Notifications
```

### 4.3. Kịch bản race condition

```
Tình huống: 2 tài xế cùng nhấn "Nhận đơn" gần như đồng thời

Tài xế A ──► POST /respond action=accept ──► Backend kiểm tra
Tài xế B ──► POST /respond action=accept ──► Backend kiểm tra

Backend dùng Database Transaction:
① Read order_requests/{id}
② Kiểm tra status == "PENDING" && acceptedDriverId == null
③ Nếu TRUE → gán acceptedDriverId = this_driver, status = "ACCEPTED"
④ Nếu FALSE → throw 409 Conflict

Kết quả:
- Tài xế nhấn trước (A): 200 SUCCESS
- Tài xế nhấn sau (B): 409 CONFLICT → "Đơn đã được tài xế khác nhận."
```

---

## 5. Luồng 4 — Giao đơn hàng (trạng thái)

### 5.1. Ma trận hành động theo trạng thái

```
┌──────────────┬───────────────────────────────────────────────────────────────────────────────┐
│   Status     │  Hành động hiển thị                                                            │
├──────────────┼───────────────────────────────────────────────────────────────────────────────┤
│  0 = PENDING │  - Chỉ xem, không action                                                       │
│              │  - Badge: "Chờ cửa hàng xác nhận" (cam)                                      │
│              │  - Có thể: Gọi cửa hàng, Chỉ đường cửa hàng                                  │
├──────────────┼───────────────────────────────────────────────────────────────────────────────┤
│  1 =         │  - PRIMARY: "Đã lấy hàng" (xanh lá)     ← NHẬN ĐƠN THÀNH CÔNG                │
│  PREPARING   │  - SECONDARY: "Từ chối đơn" (đỏ nhạt)  ← BÁO SỰ CỐ                        │
│              │  - INFO: Thông tin cửa hàng + người nhận                                       │
│              │  - Nút: Chỉ đường cửa hàng + Gọi cửa hàng                                    │
├──────────────┼───────────────────────────────────────────────────────────────────────────────┤
│  2 =         │  - PRIMARY: "Đã giao hàng" (xanh lá, NỔI BẬT NHẤT) ← HOÀN THÀNH ĐƠN         │
│  DELIVERING  │  - SECONDARY: "Báo sự cố" (cam)                                              │
│              │  - INFO: Phí giao hiển thị rất lớn (đây là thu nhập)                          │
│              │  - Nút: Chỉ đường người nhận + Gọi người nhận                                │
│              │  - GPS tracking bật (gửi location realtime)                                    │
├──────────────┼───────────────────────────────────────────────────────────────────────────────┤
│  3 =         │  - PRIMARY: DISABLED "Đã hoàn thành" (xám)                                   │
│  COMPLETED   │  - Hiện thu nhập: "+{deliveryFee}đ" (xanh lá, animation count-up)             │
│              │  - Dialog chúc mừng khi vừa complete                                          │
├──────────────┼───────────────────────────────────────────────────────────────────────────────┤
│  4 =         │  - PRIMARY: DISABLED "Đã hủy" (đỏ)                                           │
│  CANCELLED   │  - Hiện lý do hủy (nếu có)                                                    │
└──────────────┴───────────────────────────────────────────────────────────────────────────────┘
```

### 5.2. Luồng 4A — Nhấn "Đã lấy hàng" (1 → 2)

```
OrderDetailScreen (status = 1)
         │
         ▼
Tài xế nhấn "Đã lấy hàng"
         │
         ▼
Dialog xác nhận
  "Xác nhận đã lấy hàng từ {storeName}?"
  ├─► "Hủy" → Đóng
  └─► "Xác nhận" → bước tiếp
         │
         ▼
PUT /api/drivers/orders/{id}/status
  Body: { "status": 2 }
         │
         ├─► 200 SUCCESS
         │   Backend: status = 2 (Đang giao)
         │
         │   App cập nhật UI:
         │   - Status badge: "Đang giao" (xanh dương)
         │   - Thay đổi action button → "Đã giao hàng"
         │   - Thay đổi icon chỉ đường → đến người nhận
         │   - Bật GPS tracking realtime
         │   - Snackbar: "Đã xác nhận lấy hàng. Bắt đầu giao!"
         │
         ├─► 403 FORBIDDEN
         │   "Bạn không phải tài xế của đơn này."
         │   Snackbar lỗi → pop về danh sách
         │
         └─► 400 BAD_REQUEST
             "Trạng thái không hợp lệ."
             Snackbar lỗi
```

### 5.3. Luồng 4B — Nhấn "Đã giao hàng" (2 → 3)

```
OrderDetailScreen (status = 2)
         │
         ▼
Tài xế nhấn "Đã giao hàng"
         │
         ▼
Dialog xác nhận (quan trọng nhất)
  "Xác nhận đã giao hàng cho {receiverName}?"
  "Địa chỉ: {deliveryAddress}"
  ├─► "Hủy" → Đóng
  └─► "Xác nhận" → bước tiếp
         │
         ▼
PUT /api/drivers/orders/{id}/status
  Body: { "status": 3 }
         │
         ├─► 200 SUCCESS
         │   Backend tự động:
         │   - status = 3 (Hoàn thành)
         │   - Tạo TransactionDTO
         │     type = 1 (delivery_income)
         │     amount = deliveryFee
         │     orderId = this_order
         │   - Cập nhật WalletDTO:
         │     balance += deliveryFee
         │     totalEarned += deliveryFee
         │   - Dừng GPS tracking
         │
         │   App cập nhật UI:
         │   - Status badge: "Hoàn thành" (xanh lá)
         │   - Action button: disabled, "Đã hoàn thành"
         │   - Dừng GPS service
         │
         │   Dialog chúc mừng (hiện 1 lần duy nhất):
         │     🎉 "Chúc mừng! Bạn đã hoàn thành đơn hàng."
         │     Thu nhập: +{deliveryFee}đ
         │     Tổng số dư ví: {newBalance}đ
         │     ├─► "Nhận đơn mới" → AvailableOrdersScreen
         │     └─► "Đóng" → OrdersScreen (tab "Đang giao")
         │
         │   Snackbar: "Cảm ơn bạn! +{deliveryFee}đ vào ví."
         │
         ├─► 403 FORBIDDEN
         │   "Bạn không phải tài xế của đơn này."
         │
         └─► 400 BAD_REQUEST
             "Trạng thái không hợp lệ."
```

### 5.4. Luồng 4C — Báo sự cố / Hủy đơn (2 → 4)

```
OrderDetailScreen (status = 2)
         │
         ▼
Tài xế nhấn "Báo sự cố"
         │
         ▼
Bottom Sheet chọn lý do
  "Báo sự cố đơn hàng #{mã}"
  ┌─────────────────────────────────────┐
  │ ○ Không tìm thấy địa chỉ giao hàng │
  │ ○ Khách hàng không nghe máy          │
  │ ○ Cửa hàng đóng cửa / hết hàng     │
  │ ○ Tắc đường, giao trễ               │
  │ ○ ( ) Lý do khác: [____________]    │
  └─────────────────────────────────────┘
  ├─► "Hủy" → Đóng
  └─► "Tiếp tục" → bước tiếp
         │
         ▼
Dialog xác nhận
  "Xác nhận hủy đơn hàng #{mã}?"
  "Lý do: {selectedReason}"
  ├─► "Hủy" → Đóng
  └─► "Xác nhận hủy" → bước tiếp
         │
         ▼
PUT /api/drivers/orders/{id}/status
  Body: { "status": 4 }
         │
         ├─► 200 SUCCESS
         │   Backend:
         │   - status = 4 (Đã hủy)
         │   - Xóa driverId khỏi order (reset để hệ thống gán lại)
         │   - Tạo Notification type=13 cho các tài xế khác
         │   - Dừng GPS tracking
         │
         │   App:
         │   - Status badge: "Đã hủy" (đỏ)
         │   - Action button: disabled
         │   - Snackbar: "Đã báo cáo sự cố. Đơn đã được hủy."
         │   - Pop về danh sách OrdersScreen
         │
         └─► FAIL
             Snackbar lỗi
```

### 5.5. Luồng 4D — Từ chối đơn đã nhận (1 → 4)

```
OrderDetailScreen (status = 1)
         │
         ▼
Tài xế nhấn "Từ chối đơn"
         │
         ▼
Dialog xác nhận
  "Bạn có chắc từ chối đơn hàng #{mã}?"
  "Cửa hàng: {storeName}"
  ├─► "Hủy" → Đóng
  └─► "Xác nhận từ chối" → bước tiếp
         │
         ▼
PUT /api/drivers/orders/{id}/status
  Body: { "status": 4 }
         │
         ├─► 200 SUCCESS
         │   Backend:
         │   - status = 4
         │   - Xóa driverId (reset)
         │   - Hệ thống sẽ gán tài xế khác
         │
         │   App:
         │   - Snackbar: "Đã từ chối đơn hàng."
         │   - Pop về danh sách
         │
         └─► FAIL → Snackbar lỗi
```

---

## 6. Luồng 5 — Thông báo Push (WebSocket)

### 6.1. Các loại thông báo tài xế nhận được

| type | Tên | Khi nào | Hành động trên app |
|---|---|---|---|
| 11 | Yêu cầu nhận đơn | Hệ thống gán tự động | Hiện banner accept/decline |
| 12 | Thông báo giao hàng | Cập nhật trạng thái đơn | Refresh OrderDetail nếu đang mở |
| 13 | Đơn bị tài xế khác nhận | 409 conflict | Đơn biến mất khỏi danh sách |

### 6.2. Sơ đồ xử lý WebSocket chi tiết

```
WebSocket nhận message
         │
         ▼
Kiểm tra: message.data["type"] hoặc notification type
         │
    ┌────┴────────────────────────────────┐
    ▼                                    ▼
type = 11                          type = 12
"Yêu cầu nhận đơn"               "Cập nhật đơn"
    │                                    │
    │                                    ① Kiểm tra OrderDetail đang mở?
    │                                    ├─► CÓ → Refresh OrderDetailScreen
    │                                    │       (GET /api/drivers/orders/{id})
    │                                    └─► KHÔNG → Bỏ qua
    │                                    ② Snackbar nhỏ: "Đơn #{mã} đã cập nhật."
    │                                    ③ Thoát
    │
    ▼
Kiểm tra: app.state
         │
    ┌────┴────────────────────────────┐
    │      APP FOREGROUND             │
    │ (user đang dùng app)            │
    ├─────────────────────────────────┤
    │ ① Parse message.data            │
    │    - orderId                    │
    │    - storeName                  │
    │    - deliveryFee                │
    │    - deliveryAddress            │
    │                                 │
    │ ② Tạo custom in-app banner     │
    │    (AnimatedContainer,          │
    │     slideDown from top)          │
    │                                 │
    │ ③ Sound: play notification.mp3  │
    │ ④ Haptic: heavyImpact()         │
    │                                 │
    │ ⑤ Banner auto-dismiss: 30s      │
    │    (Timer countdown)            │
    │                                 │
    │ ⑥ Actions:                     │
    │    ├─► "Nhận đơn" → /respond   │
    │    └─► "Từ chối" → /respond    │
    ├─────────────────────────────────┤
    │     APP BACKGROUND              │
    │ (app đang chạy nhưng không mở)  │
    ├─────────────────────────────────┤
    │ ① WebSocket hiện native notification │
    │    (system tray banner)          │
    │    Title: "🛵 Đơn hàng mới!"   │
    │    Body: "{storeName}"           │
    │    Subtitle: "Phí: {fee}đ"     │
    │                                 │
    │ ② User tap notification         │
    │    → app comes to foreground    │
    │    → điều hướng OrderDetail     │
    │    → hiện dialog accept/decline │
    │                                 │
    │ ③ User swipe dismiss            │
    │    → notification vào system tray│
    │    → lưu notification          │
    ├─────────────────────────────────┤
    │     APP CLOSED (đã kill)        │
    ├─────────────────────────────────┤
    │ ① WebSocket hiện native notification │
    │ ② User tap → app opens         │
    │    → điều hướng OrderDetail     │
    │    → hiện dialog               │
    │                                 │
    │ OR: User không tap              │
    │    → notification lưu          │
    │    → đọc ở màn Notifications    │
    └─────────────────────────────────┘

Ngoài ra:

type = 13
"Đơn bị tài xế khác nhận"
    │
    ├─► Foreground: Dialog "Đơn đã được tài xế khác nhận."
    │       Đơn tự động biến mất khỏi danh sách
    │
    └─► Background: WebSocket notification đẩy
            "Đơn #{mã} đã được tài xế khác nhận."
```

### 6.3. Lưu trữ notification trong database

```
Database: driver_profiles/{driverId}/notifications/{notifId}

{
  "id": "notif_xxx",
  "type": 11,                        // Integer, không phải String
  "title": "Bạn có đơn hàng mới!",
  "body": "Com tam Phuc Loc Tho - Phí: 15.000đ",
  "orderId": "order_001",
  "referenceId": "order_001",        // Thường = orderId
  "isRead": false,
  "imageUrl": null,
  "createdAt": 2026-06-02T10:30:00Z
}

⚠️ LƯU Ý QUAN TRỌNG:
- Field chứa nội dung: "body", KHÔNG phải "message"
- Field tham chiếu: "referenceId", KHÔNG phải "data" hay "orderId" (trong một số trường hợp)
```

---

## 7. Luồng 6 — Ví & Rút tiền

### 7.1. Sơ đồ tổng quan ví tài xế

```
Tài xế mở màn Ví
         │
         ▼
① GET /api/drivers/wallet
    │
    ├─► SUCCESS → Hiển thị:
    │   - Số dư khả dụng: {balance}đ  ← LỚN NHẤT
    │   - Tổng thu nhập: {totalEarned}đ
    │   - Đang chờ: {pendingBalance}đ
    │   - Đã rút: {totalWithdrawn}đ
    │
    └─► FAIL → Error state + nút "Thử lại"
         │
         ▼
┌─────────────────────────────────────────────┐
│              NÚT "RÚT TIỀN"                │
│                                             │
│ if (balance < 50000) {                      │
│   // Nút disabled + tooltip                 │
│   // "Số dư tối thiểu: 50.000đ"            │
│ }                                           │
│                                             │
│ if (bankAccountNumber == null) {             │
│   // Nút disabled + alert                   │
│   // "Chưa liên kết ngân hàng"             │
│   // "Vui lòng cập nhật trong Hồ sơ"       │
│ }                                           │
│                                             │
│ if (balance >= 50000 && hasBank) {           │
│   // Nút ENABLED                            │
│   // → Bottom Sheet rút tiền                │
│ }                                           │
└─────────────────────────────────────────────┘
```

### 7.2. Luồng rút tiền chi tiết

```
Bottom Sheet Rút Tiền mở
         │
         ▼
① Nhập số tiền
   - Input với formatter tự động thêm dấu chấm
   - Nút chọn nhanh: "50K" | "100K" | "200K" | "500K" | "Tất cả"
   - Tap "Tất cả" → điền balance vào input
         │
         ▼
② Validation client-side (trước khi gửi request)
   │
   ├─► amount == null hoặc 0
   │   → Error: "Vui lòng nhập số tiền"
   │
   ├─► amount < 50000
   │   → Error: "Số tiền tối thiểu: 50.000đ"
   │
   ├─► amount > balance
   │   → Error: "Số dư không đủ"
   │
   ├─► bankAccountNumber == null
   │   → Error: "Bạn chưa liên kết ngân hàng."
   │   → Nút "Cập nhật ngân hàng" → ProfileScreen
   │
   └─► PASS → bước tiếp
         │
         ▼
③ Hiển thị chi tiết
   Số tiền rút: {amount}đ
   Phí rút: 0đ
   Số tiền nhận: {amount}đ
   Ngân hàng: {bankName}
   STK: •••• •••• •••• {last4}
   Tên: {bankAccountName}
         │
         ▼
④ Nhấn "Xác nhận rút tiền"
         │
         ▼
⑤ POST /api/drivers/withdraw
   Body: { "amount": 50000 }
         │
         ├─► 200 SUCCESS
         │   Backend tự động:
         │   - Tạo TransactionDTO
         │     type = 2 (withdrawal)
         │     status = 0 (pending)
         │     amount = requested
         │     walletId = this_wallet
         │   - Cập nhật WalletDTO
         │     balance -= amount
         │     pendingBalance += amount
         │
         │   Dialog thành công:
         │     "Yêu cầu rút tiền thành công!"
         │     "Số tiền: {amount}đ"
         │     "Ngân hàng: {bankName}"
         │     "Sẽ xử lý trong 1-3 ngày làm việc."
         │     "Trạng thái: Đang chờ xử lý"
         │     └─► "Đóng" → refresh ví + giao dịch
         │
         │   Snackbar: "+{amount}đ đang chờ xử lý."
         │
         ├─► 400 BAD_REQUEST
         │   "Số dư không đủ" / "Vượt giới hạn rút"
         │   Snackbar lỗi
         │
         └─► 404 NOT_FOUND
             "Không tìm thấy ví"
             Snackbar lỗi → điều hướng HomeScreen
```

### 7.3. Luồng xem lịch sử giao dịch

```
Màn Lịch sử Giao dịch
         │
         ▼
① GET /api/drivers/transactions?page=0&size=20
    │
    ├─► SUCCESS → Hiển thị ListView
    │
    │   Mỗi TransactionItem:
    │   ┌──────────────────────────────────────────┐
    │   │ ↑ delivery_income    │ ↓ withdrawal      │
    │   │   màu xanh lá            màu đỏ         │
    │   │ ↩ refund             │                  │
    │   │   màu cam                 │             │
    │   │                                       │
    │   │ Mô tả: "Thu nhập đơn #{mã}"          │
    │   │ Số tiền: +{amount}đ hoặc -{amount}đ  │
    │   │ Thời gian: "Hôm nay 14:30"            │
    │   │ Status badge: pending/xanh/đỏ         │
    │   └──────────────────────────────────────────┘
    │
    │   Pull-to-refresh → reload page 0
    │   Infinite scroll → page++ khi cuộn đến cuối
    │
    └─► FAIL → Snackbar lỗi
         │
         ▼
Tap transaction item
         │
         ▼
Bottom Sheet chi tiết giao dịch
   Mô tả: {description}
   Số tiền: {amount}đ
   Phí: {fee}đ
   Thực nhận: {netAmount}đ  ← = amount - fee
   Trạng thái: {status_badge}
   Thời gian: {formatted_createdAt}
   Mã đơn: {orderId} (nếu là delivery_income, tap để xem đơn)
```

---

## 8. Luồng 7 — Từ chối đơn hàng

### 8.1. Từ chối đơn khả dụng (chưa nhận)

```
AvailableOrdersScreen — Tài xế nhìn thấy đơn nhưng không muốn nhận
         │
         ▼
Nhấn "Từ chối" trên AvailableOrderCard
         │
         ▼
Dialog nhỏ
  "Bạn có chắc từ chối đơn hàng #{mã}?"
  ├─► "Hủy" → Đóng
  └─► "Xác nhận từ chối" → bước tiếp
         │
         ▼
POST /api/drivers/orders/{id}/decline
         │
         ├─► 200 SUCCESS
         │   Backend ghi log decline
         │   (Không tự động gán tài xế khác)
         │
         │   App:
         │   - Card biến mất với animation slide-out
         │   - Snackbar: "Đã từ chối đơn hàng."
         │
         └─► FAIL → Snackbar lỗi
```

---

## 9. Luồng 8 — GPS Realtime

### 9.1. Sơ đồ GPS khi online

```
Tài xế bật Online
         │
         ▼
Bắt đầu GPS Service (foreground/background)
         │
         ▼
┌──────────────────────────────────────────────────────┐
│                 VÒNG LẶP GPS                         │
│                                                      │
│  ① Lấy vị trí hiện tại                              │
│     geolocator.getCurrentPosition()                   │
│     → lat, lng, heading, speed                       │
│                                                      │
│  ② Kiểm tra: có di chuyển đủ (> 5m) so với lần trước│
│     ├─► KHÔNG di chuyển đủ → Bỏ qua, chờ lần kế tiếp│
│     └─► CÓ di chuyển đủ → bước ③                    │
│                                                      │
│  ③ POST /api/drivers/location                        │
│     Body: { lat, lng, heading, speed }               │
│     ├─► SUCCESS → Cập nhật vào RTDB                  │
│     └─► FAIL → Retry tối đa 3 lần, sau đó bỏ qua    │
│                                                      │
│  ④ Gửi lên Realtime Database:                       │
│     /active_drivers/{driverId}                       │
│     {                                                │
│       lat: 10.85,                                    │
│       lng: 106.79,                                    │
│       heading: 90,                                    │
│       lastUpdate: System.currentTimeMillis()         │
│     }                                                │
│                                                      │
│  Chờ interval 5-10 giây → lặp lại bước ①            │
└──────────────────────────────────────────────────────┘
```

### 9.2. DriverLocationMonitorService (Backend — phía server)

```
@Scheduled(fixedRate = 30000)  // 30 giây
         │
         ▼
① Đọc /active_drivers từ Realtime Database
         │
         ▼
② Với mỗi driver trong active_drivers:
         │
         ▼
③ Kiểm tra lastUpdate
   │
   ├─► lastUpdate > 60000ms (60 giây) trước
   │   │
   │   │   Backend thực hiện:
   │   │   - DriverProfile.isActive = false
   │   │   - Xóa /active_drivers/{driverId}
   │   │   - Log: "Driver {id} tự động offline do không cập nhật GPS"
   │   │
   │   │   Tài xế nhận notification:
   │   │   "Bạn đã bị offline do không cập nhật vị trí quá 60 giây."
   │   │   "Vui lòng bật lại online để tiếp tục nhận đơn."
   │   │
   │   └─► App: Snackbar cảnh báo + auto-offline
   │
   └─► lastUpdate <= 60 giây → Bỏ qua, driver vẫn online
```

---

## 10. Bảng mã trạng thái & loại

### 10.1. Mã trạng thái đơn hàng

| Giá trị | Label | Màu sắc | Khi nào |
|---|---|---|---|
| 0 | PENDING | Cam | Khách đặt, chờ cửa hàng |
| 1 | PREPARING | Vàng | Cửa hàng xác nhận, đang chuẩn bị |
| 2 | DELIVERING | Xanh dương | Tài xế đang giao |
| 3 | COMPLETED | Xanh lá | Giao thành công |
| 4 | CANCELLED | Đỏ | Bị hủy |

### 10.2. Mã loại notification

| Giá trị | Label | Màu icon | Mô tả |
|---|---|---|---|
| 11 | ORDER_ASSIGNMENT | Xanh dương 🛵 | Hệ thống gán đơn, cần phản hồi |
| 12 | ORDER_STATUS_UPDATE | Xanh lá 📦 | Cập nhật trạng thái đơn |
| 13 | ORDER_TAKEN_BY_OTHER | Đỏ ⚠️ | Đơn đã được tài xế khác nhận |

### 10.3. Mã loại giao dịch

| Giá trị | Label | Icon | Màu | Mô tả |
|---|---|---|---|---|
| 1 | DELIVERY_INCOME | ↑ | Xanh lá | Thu nhập từ giao hàng |
| 2 | WITHDRAWAL | ↓ | Đỏ | Rút tiền về ngân hàng |
| 3 | REFUND | ↩ | Cam | Hoàn tiền |

### 10.4. Mã trạng thái giao dịch

| Giá trị | Label | Màu |
|---|---|---|
| 0 | PENDING | Xám |
| 1 | COMPLETED | Xanh lá |
| 2 | FAILED | Đỏ |

### 10.5. Mã phương thức thanh toán

| Giá trị | Label | Mô tả |
|---|---|---|
| 1 | CASH | Tiền mặt (COD) |
| 2 | MOMO | Ví MoMo |
| 3 | ZALO | ZaloPay |
| 4 | VNPAY | VNPay |

### 10.6. Mã trạng thái thanh toán

| Giá trị | Label | Mô tả |
|---|---|---|
| 1 | UNPAID | Chưa thanh toán |
| 2 | PAID | Đã thanh toán |
