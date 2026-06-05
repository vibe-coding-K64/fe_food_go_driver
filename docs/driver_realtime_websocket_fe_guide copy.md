# Hướng dẫn tích hợp WebSocket Realtime cho Frontend tài xế

Tài liệu này dành cho frontend app tài xế. Mục tiêu là cấu hình nhận đơn realtime qua WebSocket/STOMP, hiển thị popup nhận đơn, và gửi phản hồi accept/decline về backend.

---

## 1. Tổng quan kiến trúc realtime

Sau khi refactor backend:

- Frontend **không dùng RTDB** để nghe đơn mới.
- Frontend nhận đơn mới trực tiếp qua **WebSocket/STOMP**.
- Backend gửi sự kiện cá nhân tới đúng tài xế qua `/user/queue/...`.
- Frontend vẫn cần giữ `requestId` để phản hồi đúng request realtime.
- REST `/respond` vẫn nên được giữ làm fallback nếu WebSocket gửi lỗi.

---

## 2. Endpoint và cấu hình kết nối

### WebSocket endpoint

Frontend kết nối tới endpoint:

```text
/ws
```

Ví dụ nếu backend chạy ở:

```text
http://localhost:8080
```

thì URL kết nối là:

```text
http://localhost:8080/ws
```

Backend hiện dùng SockJS, nên frontend nên khởi tạo SockJS client rồi bọc bằng STOMP.

---

## 3. Message broker và destination prefix

Frontend cần nhớ các prefix sau:

- **Application destination prefix:** `/app`
- **User destination prefix:** `/user`
- **Subscribe queue cho tài xế:** `/user/queue/...`

### Các kênh frontend phải subscribe

- `/user/queue/order-request`
- `/user/queue/order-status`

### Các kênh frontend phải send

- `/app/driver/accept`
- `/app/driver/decline`

---

## 4. Xác thực khi connect WebSocket

Backend hỗ trợ xác thực ở frame `CONNECT` bằng một trong hai kiểu header.

### Cách 1: JWT backend

Gửi header:

```text
Authorization: Bearer <access_token>
```

### Cách 2: Firebase ID token

Gửi header:

```text
X-Firebase-Token: <firebase_id_token>
```

### Khuyến nghị

Nếu app tài xế đang dùng access token backend sau khi login thì dùng cách 1:

```text
Authorization: Bearer <token>
```

---

## 5. Luồng hoạt động frontend

### Khi app mở / tài xế online

1. Login thành công và lấy token.
2. Kết nối WebSocket tới `/ws`.
3. Subscribe:
   - `/user/queue/order-request`
   - `/user/queue/order-status`
4. Khi nhận `ORDER_REQUEST`, hiển thị popup hoặc bottom sheet nhận đơn.
5. Khi tài xế bấm accept/decline, gửi message STOMP về backend.
6. Chờ ack từ `/user/queue/order-status` để cập nhật UI.

### Khi app mất kết nối

- FE nên auto reconnect.
- Sau reconnect phải subscribe lại toàn bộ queue.
- Nếu user đang ở popup nhận đơn, nên kiểm tra `expiresAt` trước khi cho bấm accept.

---

## 6. Payload nhận đơn mới từ backend

Frontend sẽ nhận message tại:

```text
/user/queue/order-request
```

### Event type

```text
ORDER_REQUEST
```

### Payload JSON

```json
{
  "event": "ORDER_REQUEST",
  "message": "Co don hang moi",
  "orderId": "3ZA0xIK3MAaoeOLu6oGp",
  "requestId": "kOp4fydyMUveuhMF4j5j",
  "estimatedEarning": 15000.0,
  "expiresAt": "2026-06-05T14:10:20Z",
  "order": {
    "id": "3ZA0xIK3MAaoeOLu6oGp",
    "userId": "user_001",
    "storeId": "store_001",
    "storeName": "Com tam Phuc Loc Tho",
    "storeAddress": "123 Le Van Viet, TP. Thu Duc",
    "storeLat": 10.85,
    "storeLng": 106.79,
    "items": [
      {
        "foodId": "food_001",
        "name": "Com tam suon",
        "price": 45000.0,
        "quantity": 1,
        "imageUrl": "https://example.com/image.jpg",
        "options": [
          {
            "name": "Them trung",
            "price": 5000.0
          }
        ]
      }
    ],
    "totalAmount": 140000.0,
    "deliveryFee": 15000.0,
    "status": 1,
    "paymentStatus": 1,
    "deliveryAddress": "Ky tuc xa UTC2",
    "deliveryLat": 10.8455,
    "deliveryLng": 106.7939,
    "distance": 3.5,
    "paymentMethod": 1,
    "driverId": null,
    "driverName": null,
    "driverPhone": null,
    "vehiclePlate": null,
    "createdAt": "2026-06-05T14:10:10Z",
    "updatedAt": "2026-06-05T14:10:10Z",
    "note": "Giao gap",
    "requestId": "kOp4fydyMUveuhMF4j5j",
    "estimatedEarning": 15000.0,
    "expiresAt": "2026-06-05T14:10:20Z"
  }
}
```

### Những field FE phải dùng

Ở level ngoài:

- `event`
- `message`
- `orderId`
- `requestId`
- `estimatedEarning`
- `expiresAt`
- `order`

Trong `order`:

- `id`
- `storeName`
- `storeAddress`
- `storeLat`
- `storeLng`
- `deliveryAddress`
- `deliveryLat`
- `deliveryLng`
- `distance`
- `deliveryFee`
- `paymentMethod`
- `items`
- `note`
- `requestId`
- `estimatedEarning`
- `expiresAt`

---

## 7. Payload gửi khi tài xế accept hoặc decline

Frontend gửi tới backend theo DTO sau:

```json
{
  "orderId": "3ZA0xIK3MAaoeOLu6oGp",
  "requestId": "kOp4fydyMUveuhMF4j5j"
}
```

### Accept

Destination:

```text
/app/driver/accept
```

### Decline

Destination:

```text
/app/driver/decline
```

### Lưu ý quan trọng

`requestId` là bắt buộc. Nếu FE không gửi `requestId`, backend sẽ từ chối request.

---

## 8. Payload frontend nhận sau khi phản hồi

Frontend nhận ack/fail tại:

```text
/user/queue/order-status
```

### 8.1 Accept thành công

```json
{
  "event": "ORDER_ACCEPTED",
  "message": "Nhan don hang thanh cong",
  "orderId": "3ZA0xIK3MAaoeOLu6oGp",
  "status": "SUCCESS",
  "order": {
    "id": "3ZA0xIK3MAaoeOLu6oGp"
  }
}
```

### 8.2 Accept thất bại

```json
{
  "event": "ORDER_ACCEPT_FAILED",
  "message": "Don hang da co tai xe nhan hoac request da het han",
  "orderId": "3ZA0xIK3MAaoeOLu6oGp",
  "status": "ERROR",
  "order": null
}
```

### 8.3 Decline thành công

```json
{
  "event": "ORDER_DECLINED",
  "message": "Tu choi don hang thanh cong",
  "orderId": "3ZA0xIK3MAaoeOLu6oGp",
  "status": "SUCCESS",
  "order": null
}
```

### 8.4 Decline thất bại

```json
{
  "event": "ORDER_DECLINE_FAILED",
  "message": "Da xay ra loi khong mong muon. Vui long thu lai sau.",
  "orderId": "3ZA0xIK3MAaoeOLu6oGp",
  "status": "ERROR",
  "order": null
}
```

---

## 9. Khuyến nghị xử lý UI

### Khi nhận `ORDER_REQUEST`

Frontend nên:

1. Lưu `requestId` vào state của popup.
2. Hiển thị thông tin đơn bằng `order`.
3. Tính countdown dựa trên `expiresAt`.
4. Disable nút accept/decline khi hết thời gian.
5. Nếu đang có popup cũ chưa đóng, cần quyết định chiến lược:
   - thay popup cũ bằng popup mới, hoặc
   - queue các request nếu business cho phép.

### Khi nhận `ORDER_ACCEPTED`

Frontend nên:

1. Đóng popup nhận đơn.
2. Hiển thị toast/snackbar thành công.
3. Điều hướng sang màn hình đơn hiện tại hoặc active order.
4. Đồng bộ state bằng object `order` từ backend.

### Khi nhận `ORDER_ACCEPT_FAILED`

Frontend nên:

1. Đóng popup hoặc chuyển popup sang trạng thái thất bại.
2. Hiển thị `message` từ backend.
3. Không retry bằng `requestId` cũ.

### Khi nhận `ORDER_DECLINED`

Frontend nên:

1. Đóng popup.
2. Xóa request đang active khỏi state local.

### Khi nhận `ORDER_DECLINE_FAILED`

Frontend nên:

1. Hiển thị lỗi.
2. Có thể đóng popup nếu request đã hết hạn hoặc backend báo invalid.

---

## 10. REST fallback nên giữ

Ngoài WebSocket, frontend nên giữ REST fallback trong trường hợp:

- WebSocket vừa disconnect
- STOMP send lỗi
- app vừa reconnect nhưng user thao tác quá nhanh

### Endpoint fallback

```text
POST /api/drivers/orders/{id}/respond
```

### Request body

Accept:

```json
{
  "action": "accept",
  "requestId": "kOp4fydyMUveuhMF4j5j"
}
```

Decline:

```json
{
  "action": "decline",
  "requestId": "kOp4fydyMUveuhMF4j5j"
}
```

---

## 11. Sample cấu hình frontend

Ví dụ TypeScript dùng SockJS + STOMP:

```ts
import SockJS from 'sockjs-client';
import { Client } from '@stomp/stompjs';

const socket = new SockJS(`${BASE_URL}/ws`);

const client = new Client({
  webSocketFactory: () => socket,
  connectHeaders: {
    Authorization: `Bearer ${token}`,
  },
  reconnectDelay: 5000,
  onConnect: () => {
    client.subscribe('/user/queue/order-request', (message) => {
      const payload = JSON.parse(message.body);
      console.log('ORDER_REQUEST', payload);
    });

    client.subscribe('/user/queue/order-status', (message) => {
      const payload = JSON.parse(message.body);
      console.log('ORDER_STATUS', payload);
    });
  },
});

client.activate();
```

### Gửi accept

```ts
client.publish({
  destination: '/app/driver/accept',
  body: JSON.stringify({
    orderId,
    requestId,
  }),
});
```

### Gửi decline

```ts
client.publish({
  destination: '/app/driver/decline',
  body: JSON.stringify({
    orderId,
    requestId,
  }),
});
```

---

## 12. Checklist bàn giao cho frontend

Frontend cần triển khai tối thiểu:

- [ ] Kết nối WebSocket tới `/ws`
- [ ] Gửi header `Authorization: Bearer <token>` khi CONNECT
- [ ] Subscribe `/user/queue/order-request`
- [ ] Subscribe `/user/queue/order-status`
- [ ] Parse event `ORDER_REQUEST`
- [ ] Parse event `ORDER_ACCEPTED`
- [ ] Parse event `ORDER_ACCEPT_FAILED`
- [ ] Parse event `ORDER_DECLINED`
- [ ] Parse event `ORDER_DECLINE_FAILED`
- [ ] Hiển thị popup nhận đơn theo `order` + `expiresAt`
- [ ] Gửi accept tới `/app/driver/accept`
- [ ] Gửi decline tới `/app/driver/decline`
- [ ] Luôn gửi kèm `requestId`
- [ ] Có reconnect logic
- [ ] Có REST fallback `/api/drivers/orders/{id}/respond`

---

## 13. Kết luận

Frontend tài xế hiện chỉ cần tích hợp WebSocket/STOMP là có thể nhận đơn realtime mà không cần cấu hình RTDB. Điều quan trọng nhất là:

- subscribe đúng queue cá nhân
- gửi đúng auth header khi connect
- giữ `requestId` trong suốt vòng đời popup realtime
- xử lý ack/fail từ `/user/queue/order-status`

Nếu cần, bước tiếp theo có thể bổ sung thêm:

- sample Flutter hoàn chỉnh
- sample React Native hoàn chỉnh
- sơ đồ state machine cho popup nhận đơn realtime
