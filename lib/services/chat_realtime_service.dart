import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../../core/constants/app_constants.dart';

class ChatRealtimeService {
  ChatRealtimeService({required FlutterSecureStorage secureStorage})
    : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;
  StompClient? _client;
  StompUnsubscribe? _chatSubscription;
  StreamController<ChatWsMessage>? _chatController;
  int _connectAttempt = 0;
  DateTime? _lastConnectedAt;

  Stream<ChatWsMessage> get messages {
    _chatController ??= StreamController<ChatWsMessage>.broadcast();
    return _chatController!.stream;
  }

  bool get isConnected => _client?.connected ?? false;

  Future<void> connect() async {
    if (isConnected) {
      debugPrint('[ChatRealtime] Already connected');
      return;
    }

    final token = await _secureStorage.read(key: AppConstants.driverTokenKey);
    if (token == null || token.isEmpty) {
      debugPrint('[ChatRealtime] No token available');
      return;
    }

    await disconnect();

    final headers = <String, String>{'Authorization': 'Bearer $token'};
    final websocketUrl = _buildWebsocketUrl();
    _connectAttempt += 1;

    debugPrint('[ChatRealtime] Connecting - attempt=$_connectAttempt, url=$websocketUrl');

    _client = StompClient(
      config: StompConfig.sockJS(
        url: websocketUrl,
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) {
          debugPrint('[ChatRealtime] WebSocket error: $error');
        },
        onStompError: (frame) {
          debugPrint('[ChatRealtime] STOMP error: ${frame.body}');
        },
        onDisconnect: (frame) {
          debugPrint('[ChatRealtime] Disconnected');
          _lastConnectedAt = null;
        },
        onUnhandledMessage: _handleUnhandled,
        reconnectDelay: const Duration(seconds: 5),
        connectionTimeout: const Duration(seconds: 15),
      ),
    );

    _client!.activate();
  }

  Future<void> disconnect() async {
    _chatSubscription?.call();
    _chatSubscription = null;

    final client = _client;
    _client = null;
    if (client != null) {
      debugPrint('[ChatRealtime] Deactivating');
      client.deactivate();
    }
  }

  Future<void> sendMessage(String orderId, String content) async {
    final client = _client;
    if (client == null || !client.connected) {
      debugPrint('[ChatRealtime] Cannot send - not connected');
      return;
    }

    final payload = jsonEncode({
      'orderId': orderId,
      'content': content,
    });

    debugPrint('[ChatRealtime] Sending message to /app/chat/send');
    client.send(destination: '/app/chat/send', body: payload);
  }

  void _onConnect(StompFrame frame) {
    _lastConnectedAt = DateTime.now();
    debugPrint('[ChatRealtime] Connected - attempt=$_connectAttempt');

    _ensureSubscription();
  }

  void _ensureSubscription() {
    final client = _client;
    if (client == null || !client.connected) return;

    if (_chatSubscription == null) {
      debugPrint('[ChatRealtime] Subscribing to /user/queue/chat');
      _chatSubscription = client.subscribe(
        destination: '/user/queue/chat',
        callback: (frame) {
          final body = frame.body;
          if (body == null || body.isEmpty) return;

          debugPrint('[ChatRealtime] Received message: $body');
          try {
            final decoded = jsonDecode(body) as Map<String, dynamic>;
            final wsMsg = ChatWsMessage.fromJson(decoded);
            _chatController?.add(wsMsg);
          } catch (e) {
            debugPrint('[ChatRealtime] Parse error: $e');
          }
        },
      );
    }
  }

  void _handleUnhandled(StompFrame frame) {
    debugPrint('[ChatRealtime] Unhandled: ${frame.headers['destination']}');
  }

  String _buildWebsocketUrl() {
    final apiUri = Uri.parse(AppConstants.baseApiUrl);
    final websocketScheme = apiUri.scheme == 'https' ? 'https' : 'http';
    final pathSegments = apiUri.pathSegments.where((s) => s.isNotEmpty).toList();
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

  Future<void> dispose() async {
    await disconnect();
    await _chatController?.close();
  }
}

class ChatWsMessage {
  final String event;
  final String conversationId;
  final String orderId;
  final ChatWsMessagePayload message;
  final String senderId;

  const ChatWsMessage({
    required this.event,
    required this.conversationId,
    required this.orderId,
    required this.message,
    required this.senderId,
  });

  factory ChatWsMessage.fromJson(Map<String, dynamic> json) {
    final msgData = json['message'] as Map<String, dynamic>? ?? {};
    return ChatWsMessage(
      event: json['event']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      message: ChatWsMessagePayload.fromJson(msgData),
      senderId: json['senderId']?.toString() ?? '',
    );
  }
}

class ChatWsMessagePayload {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String content;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const ChatWsMessagePayload({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatWsMessagePayload.fromJson(Map<String, dynamic> json) {
    return ChatWsMessagePayload(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'TEXT',
      isRead: json['isRead'] == true || json['isRead'] == 'true',
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
