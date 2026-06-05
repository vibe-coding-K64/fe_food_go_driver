# Hướng Dẫn Cấu Hình WebSocket - App Tài Xế

> Tài liệu này dành cho developer Flutter. Giải thích cách kết nối app tài xế với backend qua WebSocket/STOMP để nhận thông báo đơn hàng realtime.

---

## 1. Tổng Quan

### Kiến Trúc

```
APP TÀI XẾ                          BACKEND
   │                                    │
   │────── WebSocket (STOMP) ──────────►│
   │      wss://be-foodgo.canluaz.io.vn/ws
   │                                    │
   │◄──── /user/queue/order-request ────│  Khi có đơn mới
   │◄──── /user/queue/order-status ─────│  Khi order bị hủy/taken
   │                                    │
   │────── /app/driver/accept ──────────►│  Tài xế nhấn "Chấp nhận"
   │────── /app/driver/decline ─────────►│  Tài xế nhấn "Từ chối"
```

> **Lưu ý:** WebSocket dùng cùng domain với REST API, chỉ khác protocol: `https` → `wss`, `/api` → `/ws`

### 2 Kênh Nhận Đơn

| Kênh | Điều kiện | Latency |
|---|---|---|
| **WebSocket (STOMP)** | App đang mở | ~10-50ms |
| **Firestore subscription** | App đang mở | ~100-300ms |
| **FCM Push** | App đóng/background | ~1-3s |

Backend gửi đồng thời qua cả 3 kênh. App ưu tiên xử lý theo thứ tự: **WebSocket → Firestore → FCM**.

---

## 2. Cấu Hình Dependencies

### `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter

  # WebSocket STOMP
  flutter_stomp_dart: ^2.1.0

  # Hoặc dùng sockjs_client (alternative)
  # web_socket_channel: ^3.0.1
```

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

---

## 3. DTO Models

```dart
// lib/models/websocket_response.dart
class WebSocketResponse<T> {
  final String type;
  final T? data;
  final String? message;
  final int timestamp;

  factory WebSocketResponse.fromJson(Map<String, dynamic> json) {
    return WebSocketResponse(
      type: json['type'] ?? '',
      data: json['data'],
      message: json['message'],
      timestamp: json['timestamp'] ?? 0,
    );
  }
}

// lib/models/order_request_data.dart
class OrderRequestData {
  final String orderId;
  final String? message;
  final String? storeName;
  final String? storeAddress;
  final double? storeLat;
  final double? storeLng;
  final double? deliveryLat;
  final double? deliveryLng;
  final double? deliveryHeading;
  final double? estimatedEarning;
  final int? expiresAt;

  factory OrderRequestData.fromJson(Map<String, dynamic> json) {
    return OrderRequestData(
      orderId: json['orderId'] ?? '',
      message: json['message'],
      storeName: json['storeName'],
      storeAddress: json['storeAddress'],
      storeLat: _toDouble(json['storeLat']),
      storeLng: _toDouble(json['storeLng']),
      deliveryLat: _toDouble(json['deliveryLat']),
      deliveryLng: _toDouble(json['deliveryLng']),
      deliveryHeading: _toDouble(json['deliveryHeading']),
      estimatedEarning: _toDouble(json['estimatedEarning']),
      expiresAt: json['expiresAt'],
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class OrderRequestNotification {
  final String type;
  final OrderRequestData? data;
  final String? message;

  factory OrderRequestNotification.fromJson(Map<String, dynamic> json) {
    return OrderRequestNotification(
      type: json['type'] ?? '',
      data: json['data'] != null
          ? OrderRequestData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'],
    );
  }
}
```

---

## 4. WebSocket Service

```dart
// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_stomp_dart/flutter_stomp_dart.dart';
import '../models/websocket_response.dart';
import '../models/order_request_data.dart';

class WebSocketService {
  // ✅ Dùng domain thật - cùng domain với REST API
  // REST: https://be-foodgo.canluaz.io.vn/api
  // WS:   wss://be-foodgo.canluaz.io.vn/ws
  static const String _wsUrl = 'wss://be-foodgo.canluaz.io.vn/ws';

  SockJsClient? _client;
  String? _token;

  final _orderRequestController =
      StreamController<OrderRequestNotification>.broadcast();
  final _orderStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<OrderRequestNotification> get orderRequestStream =>
      _orderRequestController.stream;
  Stream<Map<String, dynamic>> get orderStatusStream =>
      _orderStatusController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _client != null;

  /// Kết nối WebSocket
  /// Gọi sau khi đăng nhập thành công
  void connect(String jwtToken) {
    _token = jwtToken;

    _client = SockJsClient(
      [_wsUrl],
      onConnect: _onConnect,
      onDisconnect: _onDisconnect,
      onWebSocketError: (e) => debugPrint('[WS] Error: $e'),
      onStompError: (f) => debugPrint('[WS] STOMP Error: ${f.body}'),
      stompConnectHeaders: {
        'Authorization': 'Bearer $jwtToken',
      },
      webSocketConnectHeaders: {
        'Authorization': 'Bearer $jwtToken',
      },
    );

    _client!.connect();
    debugPrint('[WS] Đang kết nối đến $_wsUrl');
  }

  void _onConnect(StompFrame frame) {
    debugPrint('[WS] Đã kết nối!');
    _connectionController.add(true);

    // Subscribe nhận ORDER REQUEST
    _client!.subscribe(
      destination: '/user/queue/order-request',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final json = jsonDecode(frame.body!);
          final notification = OrderRequestNotification.fromJson(json);
          _orderRequestController.add(notification);
        } catch (e) {
          debugPrint('[WS] Lỗi parse order-request: $e');
        }
      },
    );

    // Subscribe nhận ORDER STATUS
    _client!.subscribe(
      destination: '/user/queue/order-status',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final json = jsonDecode(frame.body!);
          _orderStatusController.add(json);
        } catch (e) {
          debugPrint('[WS] Lỗi parse order-status: $e');
        }
      },
    );

    debugPrint('[WS] Đã subscribe /user/queue/order-request và /user/queue/order-status');
  }

  void _onDisconnect(StompFrame? frame) {
    debugPrint('[WS] Đã ngắt kết nối');
    _connectionController.add(false);
  }

  /// Gửi phản hồi CHẤP NHẬN đơn hàng
  void sendAccept(String orderId) {
    if (_client == null) {
      debugPrint('[WS] Chưa kết nối, không thể gửi accept');
      return;
    }
    _client!.send(
      destination: '/app/driver/accept',
      body: jsonEncode({'orderId': orderId}),
    );
    debugPrint('[WS] Đã gửi accept cho order [$orderId]');
  }

  /// Gửi phản hồi TỪ CHỐI đơn hàng
  void sendDecline(String orderId) {
    if (_client == null) {
      debugPrint('[WS] Chưa kết nối, không thể gửi decline');
      return;
    }
    _client!.send(
      destination: '/app/driver/decline',
      body: jsonEncode({'orderId': orderId}),
    );
    debugPrint('[WS] Đã gửi decline cho order [$orderId]');
  }

  /// Ping giữ kết nối
  void sendPing() {
    _client?.send(destination: '/app/driver/ping', body: '');
  }

  void disconnect() {
    _client?.disconnect();
    _client = null;
    debugPrint('[WS] Đã ngắt kết nối');
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

## 5. Kết Nối Trong Bloc/Provider

### Thêm vào `HomeBloc`

```dart
// lib/features/home/presentation/bloc/home_bloc.dart

// Trong constructor hoặc init:
_websocketService = WebSocketService();

// Sau khi đăng nhập thành công, gọi:
_websocketService.connect(jwtToken);

// Lắng nghe order request từ WebSocket
_websocketService.orderRequestStream.listen((notification) {
  if (notification.data != null) {
    // Hiển thị OrderRequestModal popup
    _showOrderRequestPopup(context, notification.data!);
  }
});

// Lắng nghe trạng thái đơn hàng
_websocketService.orderStatusStream.listen((data) {
  final type = data['type'] as String?;
  final orderId = data['data']?.toString() ?? '';

  switch (type) {
    case 'ORDER_ACCEPTED':
      // Đơn đã được chấp nhận bởi tài xế khác
      break;
    case 'ORDER_CANCELLED':
      // Đơn bị hủy bởi khách
      break;
    case 'ORDER_TAKEN_BY_OTHER':
      // Đơn đã được tài xế khác nhận
      break;
  }
});

// Theo dõi trạng thái kết nối
_websocketService.connectionStream.listen((connected) {
  debugPrint('[WS] Trạng thái kết nối: $connected');
});

// Đăng xuất
_websocketService.disconnect();
```

---

## 6. Hiển Thị Popup Order Request

```dart
void _showOrderRequestPopup(BuildContext context, OrderRequestData data) {
  final remainingSeconds = data.expiresAt != null
      ? ((data.expiresAt! - DateTime.now().millisecondsSinceEpoch) / 1000).ceil()
      : 10;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => OrderRequestSheet(
      data: data,
      initialSeconds: remainingSeconds.clamp(0, 10),
      onAccept: () {
        _websocketService.sendAccept(data.orderId);
        Navigator.pop(ctx);
      },
      onDecline: () {
        _websocketService.sendDecline(data.orderId);
        Navigator.pop(ctx);
      },
    ),
  );
}
```

---

## 7. Checklist Triển Khai

```
PHÍA FLUTTER:
[ ] Thêm flutter_stomp_dart vào pubspec.yaml
[ ] Thêm quyền INTERNET trong AndroidManifest.xml
[ ] Tạo models: WebSocketResponse, OrderRequestData
[ ] Tạo WebSocketService (lib/services/)
[ ] Kết nối WS trong HomeBloc sau khi đăng nhập
[ ] Ngắt kết nối WS khi đăng xuất
[ ] Subscribe /user/queue/order-request → hiển thị popup
[ ] Subscribe /user/queue/order-status → xử lý trạng thái
[ ] Implement sendAccept() + sendDecline()
[ ] Test với Postman/WebSocket client

PHÍA BACKEND:
[x] pom.xml - thêm spring-boot-starter-websocket
[x] WebSocketSecurityConfig - STOMP broker + JWT auth
[x] WebSocketController - nhận accept/decline
[x] DeliveryController - POST /api/drivers/orders/{id}/respond
[x] OrderAssignmentService - gửi notification + CompletableFuture
[x] SecurityConfig - cho phép /ws/**
[x] application.properties - WebSocket config (port 8086)
```

---

## 8. Test Với Postman / WebSocket Client

### Cách 1: Postman

1. New Request → loại **WebSocket**
2. URL: `wss://be-foodgo.canluaz.io.vn/ws`
3. Headers: `Authorization: Bearer <your_jwt_token>`
4. Subscribe: `/user/queue/order-request`
5. Send message: `{"orderId": "test-order-123"}`

### Cách 2: Dùng `wscat`

```bash
npm install -g wscat

# Kết nối
wscat -c wss://be-foodgo.canluaz.io.vn/ws \
  -H "Authorization:Bearer <token>"

# Subscribe
CONNECT
accept-version:1.2
host:localhost
Authorization:Bearer <token>

# Sau khi CONNECTED:
SUBSCRIBE
id:sub-order-request
destination:/user/queue/order-request

SUBSCRIBE
id:sub-order-status
destination:/user/queue/order-status

# Gửi accept
SEND
destination:/app/driver/accept
content-type:application/json

{"orderId":"test-123"}
```

---

## 9. Các Endpoint Quan Trọng

| Mục | Giá trị |
|---|---|
| **WebSocket URL** | `wss://be-foodgo.canluaz.io.vn/ws` |
| REST API Base | `https://be-foodgo.canluaz.io.vn/api` |
| Subscribe - Order Request | `/user/queue/order-request` |
| Subscribe - Order Status | `/user/queue/order-status` |
| Send - Accept | `/app/driver/accept` `{orderId: "..."}` |
| Send - Decline | `/app/driver/decline` `{orderId: "..."}` |
| Auth Header | `Authorization: Bearer <jwt_token>` |
| Timeout đơn | 10 giây |

---

## 10. Xử Lý Lỗi Thường Gặp

| Lỗi | Nguyên nhân | Cách xử lý |
|---|---|---|
| `401 Unauthorized` | JWT hết hạn | Refresh token hoặc đăng nhập lại |
| `WebSocket connection failed` | Server không chạy / sai URL | Kiểm tra server đang listen trên port đúng |
| Không nhận được message | Chưa subscribe đúng destination | Kiểm tra đường dẫn subscribe có `/user/` prefix không |
| STOMP ERROR frame | Lỗi server-side | Xem log backend |
| App không nhận khi đóng | WebSocket bị close | Dùng FCM push notification thay thế |

---

## 11. Cấu Hình Server Thật (Deploy)

```dart
// ✅ Cấu hình hiện tại - dùng domain thật
static const String _wsUrl = 'wss://be-foodgo.canluaz.io.vn/ws';

// Khi deploy lên server khác, đổi URL:
static const String _wsUrl = 'wss://your-domain.com/ws';
```

> **Lưu ý:** Dùng `wss://` (WebSocket Secure) trong production thay vì `ws://` để hỗ trợ SSL.
