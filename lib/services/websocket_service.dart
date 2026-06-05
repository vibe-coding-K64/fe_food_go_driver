import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../models/order_request_data.dart';
import '../models/websocket_response.dart';

class WebSocketService {
  static const String _wsUrl = 'https://be-foodgo.canluaz.io.vn/ws';

  StompClient? _client;
  String? _currentToken;
  bool _isConnecting = false;

  final _orderRequestController =
      StreamController<OrderRequestNotification>.broadcast();
  final _orderStatusController =
      StreamController<WebSocketResponse<String>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<OrderRequestNotification> get orderRequestStream =>
      _orderRequestController.stream;
  Stream<WebSocketResponse<String>> get orderStatusStream =>
      _orderStatusController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _client?.connected ?? false;
  bool get isConnecting => _isConnecting;

  void connect(String jwtToken) {
    if (jwtToken.isEmpty) {
      debugPrint('[WS] Missing JWT token, skip connect');
      return;
    }

    if (isConnected && _currentToken == jwtToken) {
      debugPrint('[WS] Already connected');
      return;
    }

    if (_isConnecting && _currentToken == jwtToken) {
      debugPrint('[WS] Connection already in progress');
      return;
    }

    if (_client != null && (_currentToken != jwtToken || isConnected)) {
      disconnect();
    }

    _currentToken = jwtToken;
    _isConnecting = true;

    _client = StompClient(
      config: StompConfig.sockJS(
        url: _wsUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $jwtToken'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $jwtToken'},
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
    debugPrint('[WS] Connecting to $_wsUrl');
  }

  void _onConnect(StompFrame frame) {
    debugPrint('[WS] Connected');
    _isConnecting = false;
    _connectionController.add(true);

    _client?.subscribe(
      destination: '/user/queue/order-request',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final payload = jsonDecode(frame.body!) as Map<String, dynamic>;
          final notification = OrderRequestNotification.fromJson(payload);
          _orderRequestController.add(notification);
        } catch (e) {
          debugPrint('[WS] Failed to parse order-request: $e');
        }
      },
    );

    _client?.subscribe(
      destination: '/user/queue/order-status',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final payload = jsonDecode(frame.body!) as Map<String, dynamic>;
          final response = WebSocketResponse<String>.fromJson(
            payload,
            (rawData) => rawData?.toString(),
          );
          _orderStatusController.add(response);
        } catch (e) {
          debugPrint('[WS] Failed to parse order-status: $e');
        }
      },
    );

    debugPrint(
      '[WS] Subscribed to /user/queue/order-request and /user/queue/order-status',
    );
  }

  void _onDisconnect(StompFrame frame) {
    debugPrint('[WS] Disconnected');
    _isConnecting = false;
    _connectionController.add(false);
  }

  void sendAccept(String orderId) {
    if (!isConnected) {
      debugPrint('[WS] Cannot send accept while disconnected');
      return;
    }

    _client?.send(
      destination: '/app/driver/accept',
      body: jsonEncode({'orderId': orderId}),
    );
    debugPrint('[WS] Sent accept for order [$orderId]');
  }

  void sendDecline(String orderId) {
    if (!isConnected) {
      debugPrint('[WS] Cannot send decline while disconnected');
      return;
    }

    _client?.send(
      destination: '/app/driver/decline',
      body: jsonEncode({'orderId': orderId}),
    );
    debugPrint('[WS] Sent decline for order [$orderId]');
  }

  void disconnect() {
    _isConnecting = false;
    _currentToken = null;
    _client?.deactivate();
    _client = null;
    _connectionController.add(false);
    debugPrint('[WS] Disconnected manually');
  }

  void dispose() {
    disconnect();
    _orderRequestController.close();
    _orderStatusController.close();
    _connectionController.close();
  }
}
