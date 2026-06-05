import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../core/constants/app_constants.dart';
import '../models/driver_realtime_payloads.dart';

class DriverRealtimeService {
  DriverRealtimeService({required FlutterSecureStorage secureStorage})
    : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;

  StompClient? _client;
  StreamController<DriverRealtimeOrderRequest>? _orderRequestController;
  StreamController<DriverRealtimeOrderStatus>? _orderStatusController;
  StreamController<String>? _connectionStateController;
  int _connectAttempt = 0;
  DateTime? _lastConnectStartedAt;
  DateTime? _lastConnectedAt;
  String? _lastSocketUrl;

  Stream<DriverRealtimeOrderRequest> get orderRequests {
    _orderRequestController ??=
        StreamController<DriverRealtimeOrderRequest>.broadcast();
    return _orderRequestController!.stream;
  }

  Stream<DriverRealtimeOrderStatus> get orderStatuses {
    _orderStatusController ??=
        StreamController<DriverRealtimeOrderStatus>.broadcast();
    return _orderStatusController!.stream;
  }

  Stream<String> get connectionStates {
    _connectionStateController ??= StreamController<String>.broadcast();
    return _connectionStateController!.stream;
  }

  bool get isConnected => _client?.connected ?? false;

  Future<void> connect() async {
    if (isConnected) {
      debugPrint('[DriverRealtimeService] connect() skipped because client is already connected');
      return;
    }

    final token = await _secureStorage.read(key: AppConstants.driverTokenKey);
    if (token == null || token.isEmpty) {
      throw StateError('Missing driver access token for websocket connection');
    }
    final storedDriverId =
        await _secureStorage.read(key: AppConstants.driverIdKey) ?? '';

    await disconnect();

    final headers = <String, String>{'Authorization': 'Bearer $token'};
    final websocketUrl = _buildWebsocketUrl();
    final maskedToken = _maskToken(token);
    _connectAttempt += 1;
    _lastConnectStartedAt = DateTime.now().toUtc();
    _lastSocketUrl = websocketUrl;

    debugPrint(
      '[DriverRealtimeService] Activating realtime - attempt=$_connectAttempt, url=$websocketUrl, token=$maskedToken, authHeaderPresent=${headers.containsKey('Authorization')}, storedDriverId=$storedDriverId',
    );

    _client = StompClient(
      config: StompConfig.sockJS(
        url: websocketUrl,
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) {
          debugPrint(
            '[DriverRealtimeService] WebSocket error - attempt=$_connectAttempt, url=$_lastSocketUrl, error=$error',
          );
          _emitConnectionState('error');
        },
        onStompError: (frame) {
          debugPrint(
            '[DriverRealtimeService] STOMP error - attempt=$_connectAttempt, headers=${frame.headers}, body=${frame.body}',
          );
          _emitConnectionState('error');
        },
        onDisconnect: (frame) {
          final connectedAt = _lastConnectedAt;
          final connectedFor = connectedAt == null
              ? 'unknown'
              : DateTime.now().toUtc().difference(connectedAt).inSeconds;
          debugPrint(
            '[DriverRealtimeService] Disconnected - receipt=${frame.headers['receipt']}, connectedForSeconds=$connectedFor',
          );
          _emitConnectionState('disconnected');
        },
        onUnhandledMessage: _handleUnhandledMessage,
        reconnectDelay: const Duration(seconds: 5),
        connectionTimeout: const Duration(seconds: 15),
      ),
    );

    _emitConnectionState('connecting');
    _client!.activate();
  }

  Future<void> disconnect() async {
    final client = _client;
    _client = null;
    if (client != null) {
      debugPrint('[DriverRealtimeService] Deactivating realtime client');
      client.deactivate();
    }
    _emitConnectionState('disconnected');
  }

  Future<bool> sendAccept({
    required String orderId,
    required String requestId,
  }) {
    return _sendResponse(
      destination: '/app/driver/accept',
      orderId: orderId,
      requestId: requestId,
    );
  }

  Future<bool> sendDecline({
    required String orderId,
    required String requestId,
  }) {
    return _sendResponse(
      destination: '/app/driver/decline',
      orderId: orderId,
      requestId: requestId,
    );
  }

  Future<bool> _sendResponse({
    required String destination,
    required String orderId,
    required String requestId,
  }) async {
    final client = _client;
    if (client == null || !client.connected) {
      debugPrint('[DriverRealtimeService] Cannot send to $destination when disconnected');
      return false;
    }

    final payload = jsonEncode({'orderId': orderId, 'requestId': requestId});
    debugPrint(
      '[DriverRealtimeService] Sending response - destination=$destination, body=$payload',
    );

    try {
      client.send(destination: destination, body: payload);
      debugPrint(
        '[DriverRealtimeService] Response sent successfully - destination=$destination, orderId=$orderId, requestId=$requestId',
      );
      return true;
    } catch (e) {
      debugPrint('[DriverRealtimeService] Failed sending to $destination: $e');
      return false;
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _orderRequestController?.close();
    await _orderStatusController?.close();
    await _connectionStateController?.close();
  }

  void _onConnect(StompFrame frame) {
    _lastConnectedAt = DateTime.now().toUtc();
    final startedAt = _lastConnectStartedAt;
    final connectLatencyMs = startedAt == null
        ? 'unknown'
        : DateTime.now().toUtc().difference(startedAt).inMilliseconds;
    debugPrint(
      '[DriverRealtimeService] Connected - attempt=$_connectAttempt, latencyMs=$connectLatencyMs, serverHeaders=${frame.headers}',
    );
    debugPrint(
      '[DriverRealtimeService] Spring user-destination mode active; subscribing with logical destinations /user/queue/order-request and /user/queue/order-status',
    );
    debugPrint('[DriverRealtimeService] Subscribing to /user/queue/order-request');
    _emitConnectionState('connected');

    _client?.subscribe(
      destination: '/user/queue/order-request',
      callback: (frame) {
        final body = frame.body;
        debugPrint(
          '[DriverRealtimeService] Received /user/queue/order-request headers=${frame.headers}',
        );
        if (body == null || body.isEmpty) {
          debugPrint('[DriverRealtimeService] Empty order-request frame body');
          return;
        }
        debugPrint('[DriverRealtimeService] Raw order-request body: $body');
        try {
          final payload = DriverRealtimeOrderRequest.fromRaw(body);
          debugPrint(
            '[DriverRealtimeService] Parsed order-request event=${payload.event}, orderId=${payload.orderId}, requestId=${payload.requestId}, orderModelId=${payload.order.id}, storeLat=${payload.order.storeLat}, storeLng=${payload.order.storeLng}, deliveryLat=${payload.order.deliveryLat}, deliveryLng=${payload.order.deliveryLng}, expiresAt=${payload.expiresAt}, expiresInSeconds=${payload.order.expiresInSeconds}',
          );
          _orderRequestController?.add(payload);
        } catch (e) {
          debugPrint('[DriverRealtimeService] Failed parsing order request: $e');
        }
      },
    );
    debugPrint('[DriverRealtimeService] Subscription active for /user/queue/order-request');

    debugPrint('[DriverRealtimeService] Subscribing to /user/queue/order-status');
    _client?.subscribe(
      destination: '/user/queue/order-status',
      callback: (frame) {
        final body = frame.body;
        debugPrint(
          '[DriverRealtimeService] Received /user/queue/order-status headers=${frame.headers}',
        );
        if (body == null || body.isEmpty) {
          debugPrint('[DriverRealtimeService] Empty order-status frame body');
          return;
        }
        debugPrint('[DriverRealtimeService] Raw order-status body: $body');
        try {
          final payload = DriverRealtimeOrderStatus.fromRaw(body);
          debugPrint(
            '[DriverRealtimeService] Parsed order-status event=${payload.event}, orderId=${payload.orderId}, status=${payload.status}',
          );
          _orderStatusController?.add(payload);
        } catch (e) {
          debugPrint('[DriverRealtimeService] Failed parsing order status: $e');
        }
      },
    );
    debugPrint('[DriverRealtimeService] Subscription active for /user/queue/order-status');
  }

  void _handleUnhandledMessage(StompFrame frame) {
    debugPrint(
      '[DriverRealtimeService] Unhandled message on ${frame.headers['destination']}: headers=${frame.headers}, body=${frame.body}',
    );
  }

  void _emitConnectionState(String state) {
    _connectionStateController ??= StreamController<String>.broadcast();
    if (!(_connectionStateController?.isClosed ?? true)) {
      debugPrint('[DriverRealtimeService] Emitting connection state: $state');
      _connectionStateController?.add(state);
    }
  }

  String _buildWebsocketUrl() {
    final apiUri = Uri.parse(AppConstants.baseApiUrl);
    final websocketScheme = apiUri.scheme == 'https' ? 'https' : 'http';
    final pathSegments = apiUri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (pathSegments.isNotEmpty && pathSegments.last == 'api') {
      pathSegments.removeLast();
    }
    pathSegments.add('ws');

    return apiUri.replace(
      scheme: websocketScheme,
      pathSegments: pathSegments,
      query: null,
      fragment: null,
    ).toString();
  }

  String _maskToken(String token) {
    if (token.length <= 10) return token;
    return '${token.substring(0, 6)}...${token.substring(token.length - 4)}';
  }
}
