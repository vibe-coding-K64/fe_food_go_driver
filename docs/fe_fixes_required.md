# Những Thứ FE Cần Sửa

> Tổng hợp từ báo cáo `docs/websocket_fe_review_report.md`. Ghi lại những chỗ tài liệu cũ chưa đúng so với FE thực tế và những gì FE cần điều chỉnh.

---

## 1. Package trong `pubspec.yaml`

### Hiện tại (tài liệu cũ)

```yaml
flutter_stomp_dart: ^2.1.0
```

### Cần sửa thành

```yaml
stomp_dart_client: ^3.0.1
```

---

## 2. Endpoint WebSocket

### Hiện tại (tài liệu cũ)

```dart
wss://be-foodgo.canluaz.io.vn/ws
```

### Cần sửa thành

```dart
https://be-foodgo.canluaz.io.vn/ws
```

### Lý do

- Đây là **SockJS endpoint**, không phải WebSocket thuần.
- FE hiện dùng `stomp_dart_client` với SockJS transport.
- Cấu hình kiểu `wss://` chỉ phù hợp nếu client kết nối WebSocket thuần, không đúng với cách FE hiện tại đang cài bằng `StompConfig.sockJS()`.

---

## 3. Code WebSocket Service

### Hiện tại (tài liệu cũ — dùng `flutter_stomp_dart`)

```dart
import 'package:flutter_stomp_dart/flutter_stomp_dart.dart';

_client = SockJsClient(
  [_wsUrl],
  onConnect: _onConnect,
  ...
);
```

### Cần sửa thành (dùng `stomp_dart_client`)

```dart
import 'package:stomp_dart_client/stomp_dart_client.dart';

_client = StompClient(
  config: StompConfig.sockJS(
    url: 'https://be-foodgo.canluaz.io.vn/ws',
    stompConnectHeaders: {
      'Authorization': 'Bearer $jwtToken',
    },
    webSocketConnectHeaders: {
      'Authorization': 'Bearer $jwtToken',
    },
    onConnect: _onConnect,
    onDisconnect: _onDisconnect,
    onWebSocketError: (error) => debugPrint('[WS] Error: $error'),
    onStompError: (frame) => debugPrint('[WS] STOMP Error: ${frame.body}'),
  ),
);

_client!.activate();
```

### Điểm khác biệt chính

| | Tài liệu cũ | Cần sửa |
|---|---|---|
| package | `flutter_stomp_dart` | `stomp_dart_client` |
| client class | `SockJsClient` | `StompClient` |
| config | tạo `SockJsClient` trực tiếp | dùng `StompConfig.sockJS()` |
| activate | gọi `.connect()` | gọi `.activate()` |
| disconnect | `.disconnect()` | `.deactivate()` |

---

## 4. Mô Hình Phản Hồi Đơn

### Hiện tại (tài liệu cũ)

Tài liệu cũ mô tả có 3 cách phản hồi đơn khác nhau, gây nhầm lẫn.

### Cần phân biệt rõ 2 ngữ cảnh

#### Ngữ cảnh 1: Luồng order request realtime (popup nhận đơn)

Đây là luồng khi tài xế nhận thông báo có đơn mới qua WebSocket.

**Thứ tự thực hiện:**

1. Tài xế nhận được `ORDER_REQUEST` qua WebSocket
2. FE hiện popup nhận đơn
3. Tài xế bấm **Nhận** hoặc **Từ chối**
4. FE gửi **STOMP trước**:
   - Nhận đơn → `/app/driver/accept`
   - Từ chối đơn → `/app/driver/decline`
5. Sau đó FE gọi **REST backup**:
   - `POST /api/drivers/orders/{orderId}/respond`
   - body: `{"action": "accept"}` hoặc `{"action": "decline"}`

#### Ngữ cảnh 2: Luồng danh sách đơn khả dụng

Đây là luồng khi tài xế vào màn hình danh sách đơn và chọn đơn để nhận.

**Thứ tự thực hiện:**

FE không dùng WebSocket cho thao tác này.

FE gọi trực tiếp REST:

- Nhận đơn → `POST /api/drivers/orders/{orderId}/accept`
- Từ chối đơn → `POST /api/drivers/orders/{orderId}/decline`

### Tóm tắt

| Ngữ cảnh | Kênh dùng |
|---|---|
| Realtime popup (`ORDER_REQUEST`) | STOMP trước + REST `/respond` sau |
| Available orders list | REST trực tiếp `/accept` hoặc `/decline` |

---

## 5. Đồng Bộ UI Sau Khi Accept / Decline

### Hiện tại (tài liệu cũ)

Chỉ ghi chung chung "gọi REST để đồng bộ".

### Cần bổ sung cụ thể

Sau khi tài xế bấm accept hoặc decline, FE nên gọi lại:

#### Với accept

```dart
// sau khi gửi STOMP accept
// gọi REST backup
await api.post('/api/drivers/orders/$orderId/respond', body: {'action': 'accept'});

// sau đó refresh danh sách đơn hiện tại
await api.get('/api/drivers/orders/current');
// hoặc
await api.get('/api/drivers/orders/active');
```

#### Với decline

```dart
// sau khi gửi STOMP decline
// gọi REST backup
await api.post('/api/drivers/orders/$orderId/respond', body: {'action': 'decline'});

// refresh danh sách đơn khả dụng
await api.get('/api/drivers/orders/available');
```

---

## 6. Xử Lý Lỗi WebSocket Production

### Hiện tại

Tài liệu chưa đề cập đến việc xử lý khi WebSocket production lỗi upgrade.

### Cần bổ sung

Runtime app hiện tại đang gặp lỗi:

```text
WebSocketException: Connection to 'https://be-foodgo.canluaz.io.vn:0/ws/.../websocket#'
was not upgraded to websocket, HTTP status code: 500
```

Điều này có nghĩa là khi WebSocket không kết nối được, app vẫn cần hoạt động được.

#### Những gì FE cần thêm vào code

##### Tự động reconnect

```dart
// Có thể dùng reconnectDelay ngay trong StompConfig.sockJS(...)
reconnectDelay: const Duration(seconds: 5),
```

Hoặc nếu cần kiểm soát riêng:

```dart
void _onDisconnect(StompFrame frame) {
  _connectionController.add(false);

  Future.delayed(const Duration(seconds: 3), () {
    if (_token != null) {
      connect(_token!);
    }
  });
}
```

##### Fallback sang polling nhẹ khi mất kết nối

```dart
Timer? _pollingTimer;

void startPolling() {
  _pollingTimer?.cancel();
  _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
    if (!_isConnected) {
      await _refreshAvailableOrders();
    }
  });
}

void stopPolling() {
  _pollingTimer?.cancel();
  _pollingTimer = null;
}

Future<void> _refreshAvailableOrders() async {
  // gọi GET /api/drivers/orders/available
}
```

##### Theo dõi trạng thái kết nối trên UI

```dart
socketService.connectionStream.listen((connected) {
  if (!connected) {
    // hiển thị banner hoặc icon mất realtime
  } else {
    // ẩn banner, bật lại realtime
  }
});
```

---

## 7. Kiểm Tra Lại Các File Tài Liệu Liên Quan

Báo cáo khuyến nghị rà soát lại các file sau để đảm bảo thống nhất:

- `docs/driver_api_for_fe.md`
- `docs/driver_order_flows.md`

Những file này có thể vẫn mô tả luồng phản hồi đơn không đồng bộ với những gì FE thực tế đang làm.

---

## 8. Checklist Sửa Tài Liệu

- [ ] Đổi package từ `flutter_stomp_dart` sang `stomp_dart_client`
- [ ] Đổi endpoint từ `wss://...` sang `https://...` (SockJS)
- [ ] Cập nhật code mẫu WebSocket service theo `StompClient` + `StompConfig.sockJS()`
- [ ] Tách rõ 2 ngữ cảnh phản hồi đơn:
  - realtime popup: STOMP + REST `/respond`
  - available orders: REST trực tiếp `/accept` hoặc `/decline`
- [ ] Bổ sung phần reconnect khi mất kết nối
- [ ] Bổ sung polling fallback khi WebSocket production lỗi
- [ ] Đồng bộ lại các file tài liệu còn lại

---

## 9. Ghi Chú Quan Trọng

### Về WebSocket production

Lỗi upgrade HTTP 500 hiện tại nhiều khả năng nằm ở:

- cấu hình SockJS trên backend
- reverse proxy (Nginx) chặn upgrade
- firewall hoặc load balancer không hỗ trợ WebSocket upgrade

Đây là vấn đề **phía backend/production deployment**, không phải do code FE.

### Về mô hình WS + REST

Mô hình FE đang dùng là hợp lý:

- STOMP để phản hồi nhanh, độ trễ thấp
- REST backup để đồng bộ và xác nhận trạng thái cuối cùng từ backend

Không nên bỏ REST backup vì WebSocket có thể không ổn định ở production.
