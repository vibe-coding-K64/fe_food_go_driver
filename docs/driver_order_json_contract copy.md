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
  "orderCode": "FG12345",
  "storeId": "store_001",
  "storeName": "Com Tam Phuc Loc Tho",
  "storeAddress": "123 Le Van Viet, TP. Thu Duc",
  "storeLat": 10.85,
  "storeLng": 106.79,
  "customerName": "Tran Thi B",
  "customerPhone": "0901234567",
  "customerAvatarUrl": "https://...",
  "recipientName": "Tran Thi B",
  "recipientPhone": "0901234567",
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
  "itemsSubtotal": 90000,
  "optionsSubtotal": 10000,
  "totalAmount": 100000,
  "discountAmount": 0,
  "deliveryFee": 15000,
  "finalAmount": 115000,
  "driverCollectAmount": 115000,
  "status": 1,
  "paymentStatus": 1,
  "deliveryAddress": "Ky tuc xa UTC2, Thu Duc",
  "deliveryLat": 10.8455,
  "deliveryLng": 106.7939,
  "distance": 3.5,
  "pickupDistanceKm": 1.2,
  "deliveryDistanceKm": 3.5,
  "estimatedDurationMinutes": 18,
  "paymentMethod": 1,
  "driverId": null,
  "driverName": null,
  "driverPhone": null,
  "vehiclePlate": null,
  "arrivedAtStoreAt": null,
  "pickedUpAt": null,
  "deliveredAt": null,
  "createdAt": "2026-06-05T14:00:00Z",
  "updatedAt": "2026-06-05T14:00:10Z",
  "note": "Giao gap",
  "requestId": "req_456",
  "estimatedEarning": 15000,
  "expiresAt": "2026-06-05T14:05:10Z",
  "expiresInSeconds": 10
}
```

### 4.1. Nhóm field FE yêu cầu đang có hoặc nên có

#### Thông tin đơn

- `id`
- `orderCode`
- `status`
- `createdAt`
- `updatedAt`

#### Thông tin quán

- `storeName`
- `storeAddress`
- `storeLat`
- `storeLng`

#### Thông tin khách / người nhận

- `customerName`
- `customerPhone`
- `customerAvatarUrl`
- `recipientName`
- `recipientPhone`

#### Thông tin giao hàng

- `deliveryAddress`
- `deliveryLat`
- `deliveryLng`
- `distance`
- `pickupDistanceKm`
- `deliveryDistanceKm`
- `estimatedDurationMinutes`
- `note`

#### Danh sách món

- `items`
- `items[].options`

#### Thông tin tiền

- `itemsSubtotal`
- `optionsSubtotal`
- `totalAmount`
- `discountAmount`
- `deliveryFee`
- `finalAmount`
- `driverCollectAmount`

#### Thanh toán

- `paymentMethod`
- `paymentStatus`

#### Thông tin tài xế

- `driverId`
- `driverName`
- `driverPhone`
- `vehiclePlate`

#### Mốc hành trình / giao nhận

- `arrivedAtStoreAt`
- `pickedUpAt`
- `deliveredAt`

#### Dữ liệu realtime popup

- `requestId`
- `estimatedEarning`
- `expiresAt`
- `expiresInSeconds`

### 4.2. Trạng thái hỗ trợ hiện tại

#### Đã có trong backend hiện tại

- `id`
- `userId`
- `storeId`
- `storeName`
- `storeAddress`
- `storeLat`
- `storeLng`
- `items`
- `items[].options`
- `totalAmount`
- `deliveryFee`
- `status`
- `paymentStatus`
- `deliveryAddress`
- `deliveryLat`
- `deliveryLng`
- `distance`
- `paymentMethod`
- `driverId`
- `driverName`
- `driverPhone`
- `vehiclePlate`
- `createdAt`
- `updatedAt`
- `note`
- `requestId`
- `estimatedEarning`
- `expiresAt`

#### Chưa có hoặc chưa chuẩn hóa trong backend hiện tại

- `orderCode`
- `customerName`
- `customerPhone`
- `customerAvatarUrl`
- `recipientName`
- `recipientPhone`
- `itemsSubtotal`
- `optionsSubtotal`
- `discountAmount`
- `finalAmount`
- `driverCollectAmount`
- `arrivedAtStoreAt`
- `pickedUpAt`
- `deliveredAt`
- `expiresInSeconds`
- `pickupDistanceKm`
- `deliveryDistanceKm`
- `estimatedDurationMinutes`

### 4.3. Lưu ý quan trọng cho FE

- Với REST GET thông thường, các field realtime như `requestId`, `estimatedEarning`, `expiresAt` có thể là `null`.
- Với popup realtime `ORDER_REQUEST`, các field trên sẽ có giá trị.
- `distance` hiện backend đang dùng theo nghĩa khoảng cách từ quán tới điểm giao nếu tính được từ dữ liệu đơn.
- `estimatedEarning` hiện đang được backend tính theo `deliveryFee`.
- Nếu team FE cần đủ UX cho màn hình đang giao, backend nên bổ sung thêm block khách hàng và breakdown tiền.

---

## 5. Làm rõ semantics các field còn mơ hồ

## 5.1. Ý nghĩa `totalAmount`

Hiện backend đang trả `totalAmount`, nhưng FE cần lưu ý:

- contract hiện tại **chưa chốt tuyệt đối** `totalAmount` là tổng tiền món hay tổng khách phải trả
- backend hiện cũng có `deliveryFee`
- vì vậy FE **không nên tự suy diễn** nếu cần UI chi tiết thanh toán

### Khuyến nghị chuẩn hóa sau này

Backend nên chốt đầy đủ:

```json
{
  "itemsSubtotal": 90000,
  "optionsSubtotal": 10000,
  "totalAmount": 100000,
  "discountAmount": 5000,
  "deliveryFee": 15000,
  "finalAmount": 110000,
  "driverCollectAmount": 110000
}
```

### Trước khi backend bổ sung

FE nên hiểu tạm thời:

- `deliveryFee`: phí giao hàng
- `totalAmount`: tổng tiền backend đang lưu cho đơn
- chưa có guarantee rằng `totalAmount` đã gồm hay chưa gồm `deliveryFee`

## 5.2. Ý nghĩa `distance`

Hiện backend đang map `distance` theo dữ liệu có sẵn trong order; nếu không có thì backend tự tính từ:

- `storeLat/storeLng`
- `deliveryLat/deliveryLng`

Vì vậy FE nên hiểu tạm thời:

- `distance` = khoảng cách từ quán tới điểm giao
- không phải khoảng cách từ tài xế tới quán
- không phải tổng toàn hành trình

Nếu FE cần UI chi tiết hơn, backend nên bổ sung:

- `pickupDistanceKm`
- `deliveryDistanceKm`
- `estimatedDurationMinutes`

## 5.3. Người đặt và người nhận

Hiện backend có `userId` nhưng chưa có block khách hàng hoàn chỉnh.

Cho đến khi backend bổ sung thêm field, FE nên hiểu:

- chưa có cam kết rằng người đặt luôn là người nhận
- chưa có đủ dữ liệu để render card khách hàng đầy đủ ngay trên màn hình đang giao
- nếu UI bắt buộc phải hiện người nhận, backend cần bổ sung `recipientName` và `recipientPhone`

---

## 6. Contract cho các API GET

## 6.1. `GET /api/drivers/orders/{id}`

### Response thành công hiện tại

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

### Dữ liệu FE mong muốn trong tương lai gần

```json
{
  "id": "order_123",
  "orderCode": "FG12345",
  "customerName": "Tran Thi B",
  "customerPhone": "0901234567",
  "customerAvatarUrl": "https://...",
  "recipientName": "Tran Thi B",
  "recipientPhone": "0901234567",
  "itemsSubtotal": 90000,
  "optionsSubtotal": 10000,
  "discountAmount": 0,
  "finalAmount": 115000,
  "driverCollectAmount": 115000,
  "pickupDistanceKm": 1.2,
  "deliveryDistanceKm": 3.5,
  "estimatedDurationMinutes": 18,
  "arrivedAtStoreAt": null,
  "pickedUpAt": null,
  "deliveredAt": null
}
```

---

## 6.2. `GET /api/drivers/orders/available`

### Response thành công hiện tại

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

## 6.3. `GET /api/drivers/orders/current`

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

### Kết luận cho FE

- API này hiện trả **array**, không phải object đơn.
- FE nên parse `data` là `List<DeliveryOrderDTO>`.
- Tuy nhiên về UX, tên `current` thường ngụ ý một đơn duy nhất.

### Khuyến nghị chuẩn hóa backend

Backend nên chọn một trong hai hướng:

#### Hướng A - khuyến nghị hơn

`GET /current` trả:

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Lay don hien tai thanh cong.",
  "data": {
    "id": "order_123",
    "status": 2
  },
  "timestamp": "2026-06-05T14:05:10Z",
  "errors": null
}
```

hoặc `data: null` nếu không có đơn hiện tại.

#### Hướng B

Giữ array nhưng đổi semantics hoặc tên endpoint để FE không hiểu nhầm.

---

## 6.4. `GET /api/drivers/orders/active`

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

## 6.5. `GET /api/drivers/orders/history`

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

## 7. Contract cho realtime order popup

## 7.1. Subscribe `/user/queue/order-request`

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

### Ghi chú cho FE

- Event realtime hiện **đã có đủ** `orderId`, `requestId`, `estimatedEarning`, `expiresAt`.
- Event realtime hiện **chưa có** `expiresInSeconds`.
- FE nên tự tính countdown từ `expiresAt` cho đến khi backend bổ sung `expiresInSeconds`.

### FE nên dùng gì cho popup?

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

## 7.2. Send `/app/driver/accept`

FE gửi:

```json
{
  "orderId": "order_123",
  "requestId": "req_456"
}
```

## 7.3. Send `/app/driver/decline`

FE gửi:

```json
{
  "orderId": "order_123",
  "requestId": "req_456"
}
```

---

## 8. Contract cho realtime order status

## 8.1. Subscribe `/user/queue/order-status`

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

### Khuyến nghị chuẩn hóa thêm cho backend

Để FE cập nhật state ngay mà không cần reload nhiều, backend nên chuẩn hóa:

- mọi action thành công có thay đổi đơn nên trả full `DeliveryOrderDTO`
- với decline thành công, nếu vẫn muốn `order = null` thì nên bổ sung ít nhất:
  - `orderId`
  - `requestId`
  - `status`

---

## 9. Contract cho REST fallback `/respond`

## 9.1. `POST /api/drivers/orders/{orderId}/respond`

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

### Khuyến nghị chuẩn hóa response action

Backend nên hướng tới chuẩn sau:

- `accept`: trả full `DeliveryOrderDTO`
- `status update`: trả full `DeliveryOrderDTO`
- `decline`: có thể trả `null`, nhưng nên có thêm envelope dữ liệu hành động nếu FE cần update local state ngay

Ví dụ shape tốt hơn cho decline:

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Tu choi don hang thanh cong.",
  "data": {
    "orderId": "order_123",
    "requestId": "req_456",
    "status": "DECLINED"
  },
  "timestamp": "2026-06-05T14:05:10Z",
  "errors": null
}
```

---

## 10. Trạng thái đơn và các mốc giao hàng

## 10.1. Status hiện tại FE có thể gặp

Hiện backend đang dùng các giá trị số như sau:

- `0`: chờ xác nhận
- `1`: chờ / chuẩn bị / đang chờ tài xế nhận tùy ngữ cảnh hiện tại của backend
- `2`: đang giao
- `3`: hoàn thành
- `4`: đã hủy

### Lưu ý quan trọng

Status `1` hiện còn cần backend chuẩn hóa semantics rõ hơn vì trong nhiều nơi có mô tả chưa thật sự đồng nhất.

## 10.2. Nếu FE cần pickup/dropoff UX chi tiết

Nếu nghiệp vụ thực tế có các bước:

- đã đến quán
- đã lấy hàng
- đang tới khách
- đã giao thành công

thì backend nên bổ sung một trong hai hướng:

### Hướng A

Mở rộng `status` chi tiết hơn.

### Hướng B

Giữ `status` đơn giản nhưng thêm timestamps:

- `arrivedAtStoreAt`
- `pickedUpAt`
- `deliveredAt`

Trước khi backend bổ sung các field này, FE nên dùng UI đơn giản hơn cho đơn đang giao.

---

## 11. Gợi ý model FE

FE nên tách 2 model chính:

### 11.1. `DeliveryOrder`

Dùng cho:

- available list
- current order
- active orders
- history
- detail order
- dữ liệu `order` bên trong realtime event

### 11.2. `DriverOrderRequestEvent`

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

### 11.3. `DriverOrderStatusEvent`

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

## 12. Checklist backend nên bổ sung tiếp theo

Đây là danh sách ưu tiên cao theo phản hồi mới từ frontend:

### Ưu tiên cao

- [ ] bổ sung `customerName`
- [ ] bổ sung `customerPhone`
- [ ] bổ sung `recipientName`
- [ ] bổ sung `recipientPhone`
- [ ] chuẩn hóa `GET /current` thành object hoặc `null`
- [ ] chuẩn hóa nghĩa của `totalAmount`
- [ ] bổ sung `orderCode`

### Ưu tiên trung bình

- [ ] bổ sung `discountAmount`
- [ ] bổ sung `finalAmount`
- [ ] bổ sung `driverCollectAmount`
- [ ] bổ sung `expiresInSeconds`
- [ ] chuẩn hóa response cho decline/status update

### Ưu tiên mở rộng UX

- [ ] bổ sung `customerAvatarUrl`
- [ ] bổ sung `pickupDistanceKm`
- [ ] bổ sung `deliveryDistanceKm`
- [ ] bổ sung `estimatedDurationMinutes`
- [ ] bổ sung `arrivedAtStoreAt`
- [ ] bổ sung `pickedUpAt`
- [ ] bổ sung `deliveredAt`

---

## 13. Ghi chú tích hợp cho frontend

- FE nên luôn parse `data` trong REST theo wrapper `ApiResponse`.
- FE nên ưu tiên dữ liệu từ `order` trong event realtime thay vì tự map thủ công từ nhiều field rời.
- Khi bấm accept/decline từ popup realtime, FE phải giữ lại `requestId` để gửi lên backend.
- Nếu cần fallback bằng REST `/respond`, FE vẫn dùng đúng `requestId` đã nhận từ event realtime.
- Sau khi accept thành công, FE nên reload lại `current` hoặc `active` để đồng bộ UI.
- Với các field chưa được backend hỗ trợ, FE nên coi đây là roadmap contract, không assume đã có sẵn ở production nếu chưa được release.

---

## 14. File backend liên quan

Nếu team FE cần đối chiếu nhanh với backend, các file liên quan chính là:

- `src/main/java/com/example/be_foodgo/dto/DeliveryOrderDTO.java`
- `src/main/java/com/example/be_foodgo/dto/DriverOrderRequestRealtimeEvent.java`
- `src/main/java/com/example/be_foodgo/dto/DriverRealtimeEvent.java`
- `src/main/java/com/example/be_foodgo/controller/DeliveryOrderController.java`
- `src/main/java/com/example/be_foodgo/controller/DriverRealtimeController.java`
- `src/main/java/com/example/be_foodgo/service/DeliveryOrderService.java`
- `src/main/java/com/example/be_foodgo/service/OrderAssignmentService.java`
