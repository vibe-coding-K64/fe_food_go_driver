# Hướng Dẫn FE Tài Xế — Nhận Thông Báo Realtime, Nhận Đơn, Từ Chối Đơn

> Tài liệu này dành cho FE app tài xế. Mục tiêu là cấu hình nhận thông báo realtime qua WebSocket/STOMP, đồng thời xử lý thao tác nhận đơn và từ chối đơn.

---

## 1. Tổng Quan

Backend hiện hỗ trợ realtime qua WebSocket/STOMP cho app tài xế.

### FE cần dùng các kênh sau

- **WebSocket endpoint:** `https://be-foodgo.canluaz.io.vn/ws` (SockJS endpoint; nếu backend hỗ trợ upgrade đầy đủ thì client sẽ tự nâng lên WebSocket)
- **Subscribe để nhận realtime:**
  - `/user/queue/order-request`
  - `/user/queue/order-status`
- **Send phản hồi realtime lên backend qua STOMP:**
  - `/app/driver/accept`
  - `/app/driver/decline`
- **REST backup để xác nhận/truy vết phản hồi đơn:**
  - `POST /api/drivers/orders/{orderId}/respond`

### Ý nghĩa từng kênh

- `/user/queue/order-request`: backend đẩy đơn mới cho đúng tài xế.
- `/user/queue/order-status`: backend đẩy trạng thái đơn như bị hủy hoặc đã bị tài xế khác nhận.
- `/app/driver/accept`: FE gửi khi tài xế bấm nhận đơn realtime.
- `/app/driver/decline`: FE gửi khi tài xế bấm từ chối đơn realtime.
- `POST /api/drivers/orders/{orderId}/respond`: REST backup để đồng bộ trạng thái phản hồi accept/decline.

### Source of truth trong FE hiện tại

FE hiện đang triển khai theo mô hình **WS trước, REST sau** cho luồng order request realtime:

1. Nhận request qua WebSocket.
2. Tài xế thao tác accept/decline.
3. FE gửi STOMP `/app/driver/accept` hoặc `/app/driver/decline` để ưu tiên độ trễ thấp.
4. FE gọi tiếp `POST /api/drivers/orders/{orderId}/respond` với body `{ "action": "accept" | "decline" }` để backup và đồng bộ trạng thái.

Luồng này chỉ áp dụng cho **order request realtime**. Với màn hình danh sách đơn khả dụng, FE vẫn có thể gọi REST trực tiếp:

- `POST /api/drivers/orders/{orderId}/accept`
- `POST /api/drivers/orders/{orderId}/decline`

---

## 2. Luồng Hoạt Động Khuyến Nghị

### Khi app đang mở

1. Tài xế đăng nhập thành công và lấy được `jwtToken`
2. FE kết nối WebSocket tới `wss://be-foodgo.canluaz.io.vn/ws`
3. FE subscribe 2 kênh:
   - `/user/queue/order-request`
   - `/user/queue/order-status`
4. Khi có đơn mới, backend push realtime qua `/user/queue/order-request`
5. FE hiện popup hoặc bottom sheet cho tài xế chọn:
   - Nhận đơn
   - Từ chối đơn
6. Khi tài xế thao tác:
   - Nhận đơn → gửi `/app/driver/accept`
   - Từ chối đơn → gửi `/app/driver/decline`
7. Sau khi gửi, FE nên gọi lại REST API để đồng bộ UI

### Khi app background hoặc mất socket

Nên dùng thêm polling dữ liệu để đồng bộ lại danh sách đơn.

---

## 3. Dependencies Flutter

### `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  stomp_dart_client: ^3.0.1
```

### Android permission

Thêm vào `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

---

## 4. Format Dữ Liệu Realtime

FE sẽ nhận JSON dạng tổng quát như sau:

```json
{
  "type": "ORDER_REQUEST",
  "data": {
    "orderId": "abc123",
    "storeName": "Com Tam A",
    "storeAddress": "123 ABC",
    "storeLat": 10.8,
    "storeLng": 106.7,
    "deliveryLat": 10.81,
    "deliveryLng": 106.71,
    "estimatedEarning": 15000,
    "expiresAt": 1717570000
  },
  "message": "Bạn có yêu cầu nhận đơn hàng mới",
  "timestamp": 1717570000
}
```

### Các `type` FE nên xử lý

- `ORDER_REQUEST`
- `ORDER_ACCEPTED`
- `ORDER_CANCELLED`
- `ORDER_TAKEN_BY_OTHER`

---

## 5. WebSocket Service Mẫu Cho FE

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class DriverSocketService {
  static const String wsUrl = 'https://be-foodgo.canluaz.io.vn/ws';

  StompClient? _client;
  bool _isConnecting = false;

  final _orderRequestController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _orderStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get orderRequestStream =>
      _orderRequestController.stream;
  Stream<Map<String, dynamic>> get orderStatusStream =>
      _orderStatusController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _client?.connected ?? false;
  bool get isConnecting => _isConnecting;

  void connect(String jwtToken) {
    if (jwtToken.isEmpty || isConnected || isConnecting) return;

    _isConnecting = true;

    _client = StompClient(
      config: StompConfig.sockJS(
        url: wsUrl,
        stompConnectHeaders: {
          'Authorization': 'Bearer $jwtToken',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $jwtToken',
        },
        onConnect: _onConnect,
        onDisconnect: _onDisconnect,
        onWebSocketError: (error) {
          debugPrint('[WS] WebSocket error: $error');
          _isConnecting = false;
          _connectionController.add(false);
        },
        onStompError: (frame) {
          debugPrint('[WS] STOMP error: ${frame.body}');
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    debugPrint('[WS] Connected');
    _isConnecting = false;
    _connectionController.add(true);

    _client!.subscribe(
      destination: '/user/queue/order-request',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final json = jsonDecode(frame.body!);
          _orderRequestController.add(json);
        } catch (e) {
          debugPrint('[WS] Parse order-request error: $e');
        }
      },
    );

    _client!.subscribe(
      destination: '/user/queue/order-status',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final json = jsonDecode(frame.body!);
          _orderStatusController.add(json);
        } catch (e) {
          debugPrint('[WS] Parse order-status error: $e');
        }
      },
    );
  }

  void _onDisconnect(StompFrame frame) {
    debugPrint('[WS] Disconnected');
    _isConnecting = false;
    _connectionController.add(false);
  }

  void sendAccept(String orderId) {
    _client?.send(
      destination: '/app/driver/accept',
      body: jsonEncode({'orderId': orderId}),
    );
  }

  void sendDecline(String orderId) {
    _client?.send(
      destination: '/app/driver/decline',
      body: jsonEncode({'orderId': orderId}),
    );
  }

  void disconnect() {
    _isConnecting = false;
    _client?.deactivate();
    _client = null;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _orderRequestController.close();
    _orderStatusController.close();
    _connectionController.close();
  }
}
```

---

## 6. Tích Hợp Sau Khi Đăng Nhập

Sau khi login thành công và có JWT:

```dart
socketService.connect(jwtToken);
```

### Lắng nghe đơn mới

```dart
socketService.orderRequestStream.listen((event) {
  final type = event['type'];
  final data = event['data'];

  if (type == 'ORDER_REQUEST' && data != null) {
    // Hiện popup hoặc bottom sheet nhận đơn
  }
});
```

### Lắng nghe trạng thái đơn

```dart
socketService.orderStatusStream.listen((event) {
  final type = event['type'];
  final orderId = event['data'];

  if (type == 'ORDER_CANCELLED') {
    // Đơn bị khách hủy
  } else if (type == 'ORDER_TAKEN_BY_OTHER') {
    // Đơn đã bị tài xế khác nhận
  } else if (type == 'ORDER_ACCEPTED') {
    // Đơn đã được chấp nhận
  }
});
```

### Theo dõi trạng thái socket

```dart
socketService.connectionStream.listen((connected) {
  if (!connected) {
    // Có thể báo UI hoặc thử reconnect
  }
});
```

---

## 7. Cấu Hình Nút Nhận Đơn

Khi tài xế bấm **Nhận đơn**:

```dart
socketService.acceptOrder(orderId);
```

### Khuyến nghị flow UI

1. Disable nút ngay sau khi bấm
2. Hiển thị loading ngắn
3. Gửi WebSocket `/app/driver/accept`
4. Đóng popup
5. Gọi lại REST API để đồng bộ dữ liệu đơn hiện tại

### REST API nên gọi lại sau accept

- `GET /api/drivers/orders/current`
- hoặc `GET /api/drivers/orders/active`

---

## 8. Cấu Hình Nút Từ Chối Đơn

Khi tài xế bấm **Từ chối đơn**:

```dart
socketService.declineOrder(orderId);
```

### Khuyến nghị flow UI

1. Disable nút ngay sau khi bấm
2. Gửi WebSocket `/app/driver/decline`
3. Đóng popup
4. Gọi lại danh sách đơn khả dụng nếu cần

### REST API nên gọi lại sau decline

- `GET /api/drivers/orders/available`

---

## 9. REST API Đồng Bộ Dữ Liệu

Ngoài realtime, FE nên dùng REST để đồng bộ UI ổn định hơn.

### Danh sách endpoint hữu ích

- `GET /api/drivers/orders/available`
- `GET /api/drivers/orders/active`
- `GET /api/drivers/orders/current`
- `POST /api/drivers/orders/{orderId}/accept`
- `POST /api/drivers/orders/{orderId}/decline`
- `POST /api/drivers/orders/{orderId}/respond`

### Khuyến nghị sử dụng

- Realtime dùng để hiển thị nhanh
- REST dùng để xác nhận trạng thái mới nhất từ backend
- Khi app resume hoặc reconnect, luôn gọi lại `current` hoặc `available`

---

## 10. Mẫu Popup Nhận Đơn

Khi có `ORDER_REQUEST`, FE nên hiển thị:

- tên quán
- địa chỉ quán
- điểm giao hàng
- tiền công dự kiến
- thời gian hết hạn nếu có `expiresAt`
- 2 nút:
  - **Nhận đơn**
  - **Từ chối**

### Gợi ý xử lý

- Nếu có countdown, khi hết thời gian thì tự đóng popup
- Nếu đã accept/decline thì chặn bấm lặp
- Nếu nhận `ORDER_TAKEN_BY_OTHER` thì đóng popup đang mở của đơn đó

---

## 11. Những Lỗi FE Hay Gặp

### Sai endpoint WebSocket

Sai:

```text
wss://be-foodgo.canluaz.io.vn/api/ws
```

Đúng:

```text
wss://be-foodgo.canluaz.io.vn/ws
```

### Quên truyền JWT trong header

Phải có:

```dart
'Authorization': 'Bearer $jwtToken'
```

### Nhầm kênh subscribe và send

- Subscribe:
  - `/user/queue/order-request`
  - `/user/queue/order-status`
- Send:
  - `/app/driver/accept`
  - `/app/driver/decline`

### Connect quá sớm

Chỉ connect sau khi login thành công và có JWT hợp lệ.

### Không disconnect khi logout

Khi logout phải gọi:

```dart
socketService.disconnect();
```

---

## 12. Checklist Triển Khai Nhanh

- [ ] Thêm `flutter_stomp_dart` vào `pubspec.yaml`
- [ ] Thêm quyền `INTERNET` và `ACCESS_NETWORK_STATE`
- [ ] Tạo `DriverSocketService`
- [ ] Connect socket sau khi login thành công
- [ ] Subscribe `/user/queue/order-request`
- [ ] Subscribe `/user/queue/order-status`
- [ ] Hiện popup realtime khi có `ORDER_REQUEST`
- [ ] Nút nhận đơn gửi `/app/driver/accept`
- [ ] Nút từ chối gửi `/app/driver/decline`
- [ ] Gọi lại REST API sau khi accept/decline để đồng bộ UI
- [ ] Disconnect socket khi logout

---

## 13. Kết Luận

Cấu hình tối thiểu bên FE tài xế là:

1. Kết nối `wss://be-foodgo.canluaz.io.vn/ws`
2. Gửi JWT qua header `Authorization`
3. Subscribe:
   - `/user/queue/order-request`
   - `/user/queue/order-status`
4. Khi tài xế thao tác:
   - accept → gửi `/app/driver/accept`
   - decline → gửi `/app/driver/decline`
5. Sau đó gọi lại REST API để sync UI

Cách này giúp app tài xế nhận đơn realtime nhanh, đồng thời vẫn giữ dữ liệu ổn định khi mất kết nối hoặc reconnect.
