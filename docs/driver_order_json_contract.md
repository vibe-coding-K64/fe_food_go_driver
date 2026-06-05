# Driver Order JSON Contract For Frontend

> Tài liệu contract JSON chính thức để team frontend app tài xế dùng ngay cho REST API và WebSocket realtime.

---

## 1. Phạm vi áp dụng

Tài liệu này áp dụng cho các luồng của tài xế liên quan đến đơn hàng:

- lấy danh sách đơn có thể nhận
- lấy chi tiết đơn hàng
- lấy đơn hiện tại / active / history
- nhận đơn / từ chối đơn
- nhận popup realtime order request
- nhận event realtime sau khi accept / decline

---

## 2. Các endpoint FE đang dùng

### REST

Base path:

```text
/api/drivers/orders
```

Các endpoint hiện có:

- `GET /api/drivers/orders/{id}`
- `GET /api/drivers/orders/available`
- `GET /api/drivers/orders/current`
- `GET /api/drivers/orders/active`
- `GET /api/drivers/orders/history`
- `POST /api/drivers/orders/{id}/accept`
- `POST /api/drivers/orders/{id}/decline`
- `POST /api/drivers/orders/{id}/respond`
- `PUT /api/drivers/orders/{id}/status`

### WebSocket / STOMP

- connect: `wss://be-foodgo.canluaz.io.vn/ws`
- subscribe:
  - `/user/queue/order-request`
  - `/user/queue/order-status`
- send:
  - `/app/driver/accept`
  - `/app/driver/decline`

---

## 3. Response wrapper chuẩn cho REST

Tất cả REST API của nhóm tài xế - đơn hàng trả theo wrapper sau:

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Lay chi tiet don hang thanh cong.",
  "data": {},
  "timestamp": "2026-06-05T14:05:10Z",
  "errors": null
}
```

### Ý nghĩa các field wrapper

- `success`: `true` nếu request thành công, `false` nếu lỗi
- `statusCode`: mã trạng thái nghiệp vụ backend trả về
- `message`: thông điệp hiển thị hoặc log cho FE
- `data`: dữ liệu chính của API
- `timestamp`: thời điểm backend trả response
- `errors`: danh sách lỗi field-level nếu có validate error

### Error response mẫu

```json
{
  "success": false,
  "statusCode": 404,
  "message": "Không tìm thấy đơn hàng với ID [order_123].",
  "data": null,
  "timestamp": "2026-06-05T14:05:10Z",
  "errors": null
}
```

---

## 4. DeliveryOrderDTO chuẩn FE nên dùng

Đây là model JSON chính FE nên dùng cho mọi màn hình đơn hàng của tài xế.

```json
{
  "id": "order_123",
  "userId": "user_001",
  "storeId": "store_001",
  "storeName": "Com Tam Phuc Loc Tho",
  "storeAddress": "123 Le Van Viet, TP. Thu Duc",
  "storeLat": 10.85,
  "storeLng": 106.79,
  "items": [
    {
      "foodId": "food_001",
      "name": "Com tam suon bi cha",
      "price": 45000,
      "quantity": 2,
      "imageUrl": "https://...",
      "options": [
        {
          "name": "Them trung",
          "price": 5000
        }
      ]
    }
  ],
  "totalAmount": 140000,
  "deliveryFee": 15000,
  "status": 1,
  "paymentStatus": 1,
  "deliveryAddress": "Ky tuc xa UTC2, Thu Duc",
  "deliveryLat": 10.8455,
  "deliveryLng": 106.7939,
  "distance": 3.5,
  "paymentMethod": 1,
  "driverId": null,
  "driverName": null,
  "driverPhone": null,
  "vehiclePlate": null,
  "createdAt": "2026-06-05T14:00:00Z",
  "updatedAt": "2026-06-05T14:00:10Z",
  "note": "Giao gap",
  "requestId": "req_456",
  "estimatedEarning": 15000,
  "expiresAt": "2026-06-05T14:05:10Z"
}
```

### 4.1. Nhóm field FE yêu cầu

#### Thông tin đơn

- `id`
- `status`
- `createdAt`
- `updatedAt`

#### Thông tin quán

- `storeName`
- `storeAddress`
- `storeLat`
- `storeLng`

#### Thông tin giao hàng

- `deliveryAddress`
- `deliveryLat`
- `deliveryLng`
- `distance`
- `note`

#### Danh sách món

- `items`
- `items[].options`

#### Thông tin tiền

- `totalAmount`
- `deliveryFee`

#### Thanh toán

- `paymentMethod`
- `paymentStatus`

#### Thông tin tài xế

- `driverId`
- `driverName`
- `driverPhone`
- `vehiclePlate`

#### Dữ liệu realtime popup

- `requestId`
- `estimatedEarning`
- `expiresAt`

### 4.2. Lưu ý quan trọng cho FE

- Với REST GET thông thường, các field realtime như `requestId`, `estimatedEarning`, `expiresAt` có thể là `null`.
- Với popup realtime `ORDER_REQUEST`, các field trên sẽ có giá trị.
- `distance` là km.
- `estimatedEarning` hiện đang được backend tính theo `deliveryFee`.

---

## 5. Contract cho các API GET

## 5.1. `GET /api/drivers/orders/{id}`

### Response thành công

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Lay chi tiet don hang thanh cong.",
  "data": {
    "id": "order_123",
    "status": 1,
    "createdAt": "2026-06-05T14:00:00Z",
    "updatedAt": "2026-06-05T14:00:10Z",
    "storeName": "Com Tam Phuc Loc Tho",
    "storeAddress": "123 Le Van Viet, TP. Thu Duc",
    "storeLat": 10.85,
    "storeLng": 106.79,
    "deliveryAddress": "Ky tuc xa UTC2, Thu Duc",
    "deliveryLat": 10.8455,
    "deliveryLng": 106.7939,
    "distance": 3.5,
    "note": "Giao gap",
    "items": [],
    "totalAmount": 140000,
    "deliveryFee": 15000,
    "paymentMethod": 1,
    "paymentStatus": 1,
    "driverId": null,
    "driverName": null,
    "driverPhone": null,
    "vehiclePlate": null,
    "requestId": null,
    "estimatedEarning": null,
    "expiresAt": null
  },
  "timestamp": "2026-06-05T14:05:10Z",
  "errors": null
}
```

---

## 5.2. `GET /api/drivers/orders/available`

### Response thành công

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Lay danh sach don hang kha dung thanh cong.",
  "data": [
    {
      "id": "order_123",
      "status": 1,
      "createdAt": "2026-06-05T14:00:00Z",
      "updatedAt": "2026-06-05T14:00:10Z",
      "storeName": "Com Tam Phuc Loc Tho",
      "storeAddress": "123 Le Van Viet, TP. Thu Duc",
      "storeLat": 10.85,
      "storeLng": 106.79,
      "deliveryAddress": "Ky tuc xa UTC2, Thu Duc",
      "deliveryLat": 10.8455,
      "deliveryLng": 106.7939,
      "distance": 3.5,
      "note": "Giao gap",
      "items": [],
      "totalAmount": 140000,
      "deliveryFee": 15000,
      "paymentMethod": 1,
      "paymentStatus": 1,
      "driverId": null,
      "driverName": null,
      "driverPhone": null,
      "vehiclePlate": null,
      "requestId": null,
      "estimatedEarning": null,
      "expiresAt": null
    }
  ],
  "timestamp": "2026-06-05T14:05:10Z",
  "errors": null
}
```

---

## 5.3. `GET /api/drivers/orders/current`

### Response hiện tại

Backend hiện trả `List<DeliveryOrderDTO>`.

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Lay don hien tai thanh cong.",
  "data": [
    {
      "id": "order_123",
      "status": 2,
      "storeName": "Com Tam Phuc Loc Tho"
    }
  ],
  "timestamp": "2026-06-05T14:05:10Z",
  "errors": null
}
```

### Lưu ý cho FE

- API này hiện trả **array**, không phải object đơn.
- FE nên parse `data` là `List<DeliveryOrderDTO>`.

---

## 5.4. `GET /api/drivers/orders/active`

### Response hiện tại

Backend hiện trả `List<DeliveryOrderDTO>`.

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Lay danh sach don hang hoat dong thanh cong.",
  "data": [
    {
      "id": "order_123",
      "status": 2,
      "storeName": "Com Tam Phuc Loc Tho"
    }
  ],
  "timestamp": "2026-06-05T14:05:10Z",
  "errors": null
}
```

---

## 5.5. `GET /api/drivers/orders/history`

### Response thành công

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Lay lich su don hang thanh cong.",
  "data": [
    {
      "id": "order_789",
      "status": 3,
      "createdAt": "2026-06-01T09:00:00Z",
      "updatedAt": "2026-06-01T09:35:00Z",
      "storeName": "Pho Thin",
      "storeAddress": "456 Xa Lo Ha Noi",
      "storeLat": 10.84,
      "storeLng": 106.78,
      "deliveryAddress": "Thu Duc",
      "deliveryLat": 10.82,
      "deliveryLng": 106.80,
      "distance": 2.7,
      "note": "Khong lay muong",
      "items": [],
      "totalAmount": 95000,
      "deliveryFee": 18000,
      "paymentMethod": 2,
      "paymentStatus": 2,
      "driverId": "driver_001",
      "driverName": "Nguyen Van A",
      "driverPhone": "0912345678",
      "vehiclePlate": "59A1-12345",
      "requestId": null,
      "estimatedEarning": null,
      "expiresAt": null
    }
  ],
  "timestamp": "2026-06-05T14:05:10Z",
  "errors": null
}
```

---

## 6. Contract cho realtime order popup

## 6.1. Subscribe `/user/queue/order-request`

Khi backend tìm được đơn phù hợp và gửi popup cho tài xế, FE sẽ nhận event:

```json
{
  "event": "ORDER_REQUEST",
  "message": "Co don hang moi",
  "orderId": "order_123",
  "requestId": "req_456",
  "estimatedEarning": 15000,
  "expiresAt": "2026-06-05T14:05:10Z",
  "order": {
    "id": "order_123",
    "userId": "user_001",
    "storeId": "store_001",
    "storeName": "Com Tam Phuc Loc Tho",
    "storeAddress": "123 Le Van Viet, TP. Thu Duc",
    "storeLat": 10.85,
    "storeLng": 106.79,
    "items": [
      {
        "foodId": "food_001",
        "name": "Com tam suon bi cha",
        "price": 45000,
        "quantity": 2,
        "imageUrl": "https://...",
        "options": [
          {
            "name": "Them trung",
            "price": 5000
          }
        ]
      }
    ],
    "totalAmount": 140000,
    "deliveryFee": 15000,
    "status": 1,
    "paymentStatus": 1,
    "deliveryAddress": "Ky tuc xa UTC2, Thu Duc",
    "deliveryLat": 10.8455,
    "deliveryLng": 106.7939,
    "distance": 3.5,
    "paymentMethod": 1,
    "driverId": null,
    "driverName": null,
    "driverPhone": null,
    "vehiclePlate": null,
    "createdAt": "2026-06-05T14:00:00Z",
    "updatedAt": "2026-06-05T14:00:10Z",
    "note": "Giao gap",
    "requestId": "req_456",
    "estimatedEarning": 15000,
    "expiresAt": "2026-06-05T14:05:10Z"
  }
}
```

### FE nên dùng gì cho popup?

FE có thể chọn một trong hai cách:

#### Cách khuyến nghị

- dùng `event.order` làm source chính để render popup
- dùng `event.orderId`, `event.requestId`, `event.estimatedEarning`, `event.expiresAt` cho thao tác nhanh nếu cần

#### Cách tối giản

- dùng các field top-level:
  - `orderId`
  - `requestId`
  - `estimatedEarning`
  - `expiresAt`
- và dùng `order` để lấy phần chi tiết hiển thị

---

## 6.2. Send `/app/driver/accept`

FE gửi:

```json
{
  "orderId": "order_123",
  "requestId": "req_456"
}
```

## 6.3. Send `/app/driver/decline`

FE gửi:

```json
{
  "orderId": "order_123",
  "requestId": "req_456"
}
```

---

## 7. Contract cho realtime order status

## 7.1. Subscribe `/user/queue/order-status`

### Accept thành công

```json
{
  "event": "ORDER_ACCEPTED",
  "message": "Nhan don hang thanh cong",
  "orderId": "order_123",
  "status": "SUCCESS",
  "order": {
    "id": "order_123",
    "status": 2,
    "storeName": "Com Tam Phuc Loc Tho",
    "storeAddress": "123 Le Van Viet, TP. Thu Duc",
    "storeLat": 10.85,
    "storeLng": 106.79,
    "deliveryAddress": "Ky tuc xa UTC2, Thu Duc",
    "deliveryLat": 10.8455,
    "deliveryLng": 106.7939,
    "distance": 3.5,
    "note": "Giao gap",
    "items": [],
    "totalAmount": 140000,
    "deliveryFee": 15000,
    "paymentMethod": 1,
    "paymentStatus": 1,
    "driverId": "driver_001",
    "driverName": "Nguyen Van A",
    "driverPhone": "0912345678",
    "vehiclePlate": "59A1-12345",
    "createdAt": "2026-06-05T14:00:00Z",
    "updatedAt": "2026-06-05T14:02:00Z"
  }
}
```

### Accept thất bại

```json
{
  "event": "ORDER_ACCEPT_FAILED",
  "message": "Đơn hàng [order_123] đã được assign cho tài xế khác.",
  "orderId": "order_123",
  "status": "ERROR",
  "order": null
}
```

### Decline thành công

```json
{
  "event": "ORDER_DECLINED",
  "message": "Tu choi don hang thanh cong",
  "orderId": "order_123",
  "status": "SUCCESS",
  "order": null
}
```

### Decline thất bại

```json
{
  "event": "ORDER_DECLINE_FAILED",
  "message": "Khong tim thay request tam cua tai xe",
  "orderId": "order_123",
  "status": "ERROR",
  "order": null
}
```

---

## 8. Contract cho REST fallback `/respond`

## 8.1. `POST /api/drivers/orders/{orderId}/respond`

### Accept

Request body:

```json
{
  "action": "accept",
  "requestId": "req_456"
}
```

Response thành công:

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Nhan don hang thanh cong.",
  "data": {
    "id": "order_123",
    "status": 2,
    "storeName": "Com Tam Phuc Loc Tho"
  },
  "timestamp": "2026-06-05T14:05:10Z",
  "errors": null
}
```

### Decline

Request body:

```json
{
  "action": "decline",
  "requestId": "req_456"
}
```

Response thành công:

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Tu choi don hang thanh cong.",
  "data": null,
  "timestamp": "2026-06-05T14:05:10Z",
  "errors": null
}
```

---

## 9. Gợi ý model FE

FE nên tách 2 model chính:

### 9.1. `DeliveryOrder`

Dùng cho:

- available list
- current order
- active orders
- history
- detail order
- dữ liệu `order` bên trong realtime event

### 9.2. `DriverOrderRequestEvent`

Dùng cho popup realtime:

```json
{
  "event": "ORDER_REQUEST",
  "message": "Co don hang moi",
  "orderId": "order_123",
  "requestId": "req_456",
  "estimatedEarning": 15000,
  "expiresAt": "2026-06-05T14:05:10Z",
  "order": {}
}
```

### 9.3. `DriverOrderStatusEvent`

Dùng cho `/user/queue/order-status`:

```json
{
  "event": "ORDER_ACCEPTED",
  "message": "Nhan don hang thanh cong",
  "orderId": "order_123",
  "status": "SUCCESS",
  "order": {}
}
```

---

## 10. Ghi chú tích hợp cho frontend

- FE nên luôn parse `data` trong REST theo wrapper `ApiResponse`.
- FE nên ưu tiên dữ liệu từ `order` trong event realtime thay vì tự map thủ công từ nhiều field rời.
- Khi bấm accept/decline từ popup realtime, FE phải giữ lại `requestId` để gửi lên backend.
- Nếu cần fallback bằng REST `/respond`, FE vẫn dùng đúng `requestId` đã nhận từ event realtime.
- Sau khi accept thành công, FE nên reload lại `current` hoặc `active` để đồng bộ UI.

---

## 11. Tóm tắt field bắt buộc FE cần quan tâm

### Bắt buộc cho mọi màn hình đơn hàng

- `id`
- `status`
- `createdAt`
- `updatedAt`
- `storeName`
- `storeAddress`
- `storeLat`
- `storeLng`
- `deliveryAddress`
- `deliveryLat`
- `deliveryLng`
- `distance`
- `note`
- `items`
- `totalAmount`
- `deliveryFee`
- `paymentMethod`
- `paymentStatus`
- `driverId`
- `driverName`
- `driverPhone`
- `vehiclePlate`

### Bắt buộc cho popup realtime

- `orderId`
- `requestId`
- `estimatedEarning`
- `expiresAt`
- `order`

---

## 12. File backend liên quan

Nếu team FE cần đối chiếu nhanh với backend, các file liên quan chính là:

- `src/main/java/com/example/be_foodgo/dto/DeliveryOrderDTO.java`
- `src/main/java/com/example/be_foodgo/dto/DriverOrderRequestRealtimeEvent.java`
- `src/main/java/com/example/be_foodgo/dto/DriverRealtimeEvent.java`
- `src/main/java/com/example/be_foodgo/controller/DeliveryOrderController.java`
- `src/main/java/com/example/be_foodgo/controller/DriverRealtimeController.java`
- `src/main/java/com/example/be_foodgo/service/DeliveryOrderService.java`
- `src/main/java/com/example/be_foodgo/service/OrderAssignmentService.java`
