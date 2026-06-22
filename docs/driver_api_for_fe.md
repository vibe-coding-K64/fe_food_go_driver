# API Documentation — Driver Order (BE -> FE Integration)

> **Base URL:** `https://be-foodgo.canluaz.io.vn/api`
>
> **Auth:** Tất cả endpoint yêu cầu `Authorization: Bearer <jwt_token>` trong header.
>
> **File này dành cho FE sửa theo — không thay đổi backend.**

---

## Driver Order Endpoints

### 1. Lấy danh sách đơn chờ tài xế (khả dụng)

```
GET /api/drivers/orders/available
```

**Response:** `ApiResponse<List<DeliveryOrderDTO>>`

| HTTP Code | Ý nghĩa |
|---|---|
| 200 | Thành công |
| 401 | Chưa xác thực |
| 500 | Lỗi server |

---

### 2. Lấy đơn đang giao

```
GET /api/drivers/orders/active
```

**Response:** `ApiResponse<List<DeliveryOrderDTO>>`

Lấy tất cả đơn có `status == 2` và `driverId == driver hiện tại`.

---

### 3. Lấy đơn đang giao hiện tại

```
GET /api/drivers/orders/current
```

**Response:** `ApiResponse<DeliveryOrderDTO>` (hoặc `ApiResponse<List<DeliveryOrderDTO>>`)

Trả về đơn `status == 2` hiện tại của tài xế. Response body nằm trong field `data` của ApiResponse wrapper.

---

### 4. Lấy lịch sử đơn gần đây

```
GET /api/drivers/orders/history?limit={n}
```

**Query Parameters:**

| Param | Type | Mặc định | Mô tả |
|---|---|---|---|
| `limit` | Integer | 10 | Số lượng đơn trả về |

**Response:** `ApiResponse<List<DeliveryOrderDTO>>`

Trả về các đơn `status == 3` (đã hoàn thành), sắp xếp theo `createdAt` giảm dần.

---

### 5. Nhận đơn hàng

```
POST /api/drivers/orders/{orderId}/accept
```

**Path Parameters:**

| Param | Type | Mô tả |
|---|---|---|
| `orderId` | String | ID đơn hàng |

**Response:** `ApiResponse<DeliveryOrderDTO>`

| HTTP Code | Ý nghĩa |
|---|---|
| 200 | Nhận đơn thành công |
| 401 | Chưa xác thực |
| 404 | Không tìm thấy đơn hàng |
| 409 | Đơn đã có tài xế khác nhận |

**Body:** Không cần body.

---

### 6. Từ chối đơn

```
POST /api/drivers/orders/{orderId}/decline
```

**Path Parameters:**

| Param | Type | Mô tả |
|---|---|---|
| `orderId` | String | ID đơn hàng |

**Response:** `ApiResponse<Void>` (data = null)

---

### 7. Phản hồi yêu cầu đơn (accept/decline)

> **Chỉ dùng cho WebSocket notification.** Không dùng cho cập nhật trạng thái giao hàng.

```
POST /api/drivers/orders/{orderId}/respond
```

**Path Parameters:**

| Param | Type | Mô tả |
|---|---|---|
| `orderId` | String | ID đơn hàng |

**Request Body:**

```json
{
  "action": "accept"
}
```

| `action` value | Ý nghĩa |
|---|---|
| `"accept"` | Chấp nhận đơn — trả về `DeliveryOrderDTO` |
| `"decline"` | Từ chối đơn — trả về `null` |

**Response:** `ApiResponse<DeliveryOrderDTO>` hoặc `ApiResponse<Void>`

---

### 8. Cập nhật trạng thái đơn

```
PUT /api/drivers/orders/{orderId}/status
```

**Path Parameters:**

| Param | Type | Mô tả |
|---|---|---|
| `orderId` | String | ID đơn hàng |

**Request Body:**

```json
{
  "status": 3
}
```

| `status` | Ý nghĩa |
|---|---|
| `3` | Hoàn thành đơn — tài xế nhận tiền cuốc (`deliveryFee`), đơn chuyển sang COMPLETED |
| `4` | Hủy đơn — đơn reset về `status=1`, tài xế được rảnh |

**Response:** `ApiResponse<DeliveryOrderDTO>`

| HTTP Code | Ý nghĩa |
|---|---|
| 200 | Cập nhật thành công |
| 400 | Trạng thái không hợp lệ |
| 403 | Tài xế không phải chủ đơn |
| 404 | Không tìm thấy đơn hàng |

---

## Response Format

Tất cả API đều trả về format chuẩn:

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Lay danh sach don hang kha dung thanh cong.",
  "data": [ ... ]
}
```

Khi lỗi:

```json
{
  "success": false,
  "statusCode": 409,
  "message": "Don hang da co tai xe nhan."
}
```

> **Quan trọng:** Response body luôn nằm trong field `data`. Khi parse, cần extract `decoded['data']` trước khi mapping sang model.

---

## DeliveryOrderDTO — Data Model

```json
{
  "id": "67xSOGFo0SS8aEedK5KA",
  "userId": "user_008",
  "storeId": "store_007",
  "storeName": "Com Tam Phuc Loc Tho",
  "storeAddress": "123 Le Van Viet, TP. Thu Duc",
  "storeLat": 10.850579163945532,
  "storeLng": 106.76233520008368,
  "items": [
    {
      "foodId": "food_001",
      "name": "Com tam suon bi cha",
      "price": 45000.0,
      "quantity": 2,
      "imageUrl": "https://...",
      "options": [
        { "name": "Tran chau", "price": 5000.0 }
      ]
    }
  ],
  "totalAmount": 95000.0,
  "deliveryFee": 15000.0,
  "status": 1,
  "paymentStatus": 1,
  "deliveryAddress": "Ky tuc xa UTC2, Quan 9, TP.HCM",
  "deliveryLat": 10.8446312,
  "deliveryLng": 106.7974772,
  "distance": 3.5,
  "paymentMethod": 1,
  "driverId": null,
  "driverName": null,
  "driverPhone": null,
  "vehiclePlate": null,
  "createdAt": "2026-06-05T03:59:25.560Z",
  "updatedAt": "2026-06-05T03:59:25.560Z",
  "note": "Giao gap"
}
```

### Fields

| Field | Type | Nullable | Mô tả |
|---|---|---|---|
| `id` | String | No | ID đơn hàng |
| `userId` | String | Yes | ID khách hàng đặt |
| `storeId` | String | Yes | ID cửa hàng |
| `storeName` | String | Yes | Tên cửa hàng |
| `storeAddress` | String | Yes | Địa chỉ cửa hàng |
| `storeLat` | Double | Yes | Vĩ độ cửa hàng |
| `storeLng` | Double | Yes | Kinh độ cửa hàng |
| `items` | `List<OrderItemData>` | Yes | Danh sách món ăn |
| `totalAmount` | Double | Yes | Tổng tiền đơn (VND) |
| `deliveryFee` | Double | Yes | Phí giao hàng (VND) |
| `status` | Integer | No | Trạng thái đơn hàng |
| `paymentStatus` | Integer | Yes | Trạng thái thanh toán |
| `deliveryAddress` | String | Yes | Địa chỉ giao hàng |
| `deliveryLat` | Double | Yes | Vĩ độ giao hàng |
| `deliveryLng` | Double | Yes | Kinh độ giao hàng |
| `distance` | Double | Yes | Khoảng cách (km) |
| `paymentMethod` | int | Yes | 1=Cash, 2=MoMo, 3=Zalo, 4=VNPay |
| `driverId` | String | Yes | ID tài xế nhận đơn |
| `driverName` | String | Yes | Tên tài xế |
| `driverPhone` | String | Yes | SĐT tài xế |
| `vehiclePlate` | String | Yes | Biển số xe |
| `createdAt` | String (ISO8601) | Yes | Thời điểm tạo đơn |
| `updatedAt` | String (ISO8601) | Yes | Thời điểm cập nhật cuối |
| `note` | String | Yes | Ghi chú đơn hàng |

### OrderItemData

| Field | Type | Nullable | Mô tả |
|---|---|---|---|
| `foodId` | String | Yes | ID món ăn |
| `name` | String | Yes | Tên món ăn |
| `price` | Double | Yes | Đơn giá (VND) |
| `quantity` | Integer | Yes | Số lượng |
| `imageUrl` | String | Yes | URL ảnh món ăn |
| `options` | `List<OptionData>` | Yes | Các tùy chọn (size, topping) |

### OptionData

| Field | Type | Nullable | Mô tả |
|---|---|---|---|
| `name` | String | Yes | Tên tùy chọn |
| `price` | Double | Yes | Giá tùy chọn (VND) |

---

## Order Status Values

| Value | Trạng thái | Mô tả |
|---|---|---|
| 1 | `WAITING_DRIVER` | Đang chờ tài xế nhận |
| 2 | `DELIVERING` | Đang giao |
| 3 | `COMPLETED` | Hoàn thành |
| 4 | `CANCELLED` | Đã hủy |

---

## Payment Status Values

| Value | Trạng thái |
|---|---|
| 1 | Chưa thanh toán |
| 2 | Đã thanh toán |

---

## Payment Method Values

| Value | Phương thức |
|---|---|
| 1 | Cash (Tiền mặt) |
| 2 | MoMo |
| 3 | ZaloPay |
| 4 | VNPay |

---

## Real-time Data

### Collections & Queries

| Collection | Filter | Mô tả |
|---|---|---|
| `orders` | `status == 1, driverId == null` | Đơn chờ tài xế |
| `orders` | `driverId == uid, status == 2` | Đơn đang giao |
| `orders` | `driverId == uid, status == 3` | Lịch sử đơn |

---

## Endpoint Map — Da sua o FE

| # | Cu (sai) | Moi (dung) | File da sua |
|---|---|---|---|
| 1 | `GET /api/delivery/orders?status=1` | `GET /api/drivers/orders/available` | `order_remote_datasource.dart` |
| 2 | `GET /api/delivery/orders?status=2` | `GET /api/drivers/orders/active` | `order_remote_datasource.dart` |
| 3 | `GET /api/delivery/orders/current` | `GET /api/drivers/orders/current` | `order_remote_datasource.dart`, `home_remote_datasource.dart` |
| 4 | `GET /api/delivery/orders?driverId={id}&limit={n}` | `GET /api/drivers/orders/history?limit={n}` | `order_remote_datasource.dart`, `home_remote_datasource.dart` |
| 5 | `POST /api/drivers/orders/{orderId}/respond` (dung cho status update) | `PUT /api/drivers/orders/{orderId}/status` (body: `{"status": 3}` hoac `{"status": 4}`) | `order_remote_datasource.dart` |

> **Luu y:** Endpoint `/api/drivers/orders/{orderId}/respond` chi dung cho WebSocket push response (accept/decline tu notification), KHONG dung de cap nhat trang thai don giao hoan thanh. Dung `PUT /api/drivers/orders/{orderId}/status` de hoan thanh hoac huy don.

---

## Thu tu goi khi nhan don (luong chuan)

```
1. POST /api/drivers/orders/{orderId}/accept     <- Xac nhan nhan don
   |
   v
2. WS STOMP SEND /app/driver/accept              <- Low-latency (optional, co the dung thay POST)
   |
   v
3. GET /api/drivers/orders/current                <- Lay don vua nhan
   |
   v
4. WebSocket subscription cap nhat UI            <- Real-time
```

## Thu tu goi khi hoan thanh don

```
PUT /api/drivers/orders/{orderId}/status
Body: { "status": 3 }
   |
   v
GET /api/drivers/orders/history?limit={n}         <- Don chuyen vao lich su
```

## Thu tu goi khi huy don

```
PUT /api/drivers/orders/{orderId}/status
Body: { "status": 4 }
   |
   v
Don bi reset ve status=1, tai xe duoc rảnh
```

---

## WebSocket STOMP

| Type | Destination | Body | Mo ta |
|---|---|---|---|
| SUBSCRIBE | `/user/queue/order-request` | - | Nhan thong bao don moi |
| SUBSCRIBE | `/user/queue/order-status` | - | Nhan cap nhat trang thai don |
| SEND | `/app/driver/accept` | `{"orderId": "..."}` | Gui accept (low-latency) |
| SEND | `/app/driver/decline` | `{"orderId": "..."}` | Gui decline (low-latency) |

**WS Base URL:** `wss://be-foodgo.canluaz.io.vn/ws`
