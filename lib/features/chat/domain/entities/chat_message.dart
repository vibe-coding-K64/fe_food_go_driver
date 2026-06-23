import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String content;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessage({
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

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderId': senderId,
    'senderName': senderName,
    'senderRole': senderRole,
    'content': content,
    'type': type,
    'isRead': isRead,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  bool get isFromDriver => senderRole == '2';

  @override
  List<Object?> get props => [id, conversationId, senderId, senderName, senderRole, content, type, isRead, createdAt];
}

class Conversation extends Equatable {
  final String id;
  final String orderId;
  final String customerId;
  final String customerName;
  final String driverId;
  final String driverName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCustomer;
  final int unreadDriver;
  final String status;
  final DateTime createdAt;

  const Conversation({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.driverId,
    required this.driverName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCustomer,
    required this.unreadDriver,
    required this.status,
    required this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? '',
      driverName: json['driverName']?.toString() ?? '',
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageAt: _parseDateTime(json['lastMessageAt']),
      unreadCustomer: _parseInt(json['unreadCustomer']),
      unreadDriver: _parseInt(json['unreadDriver']),
      status: json['status']?.toString() ?? 'active',
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  String getOtherPartyName(String currentUserId) {
    return currentUserId == customerId ? customerName : driverName;
  }

  String getOtherPartyId(String currentUserId) {
    return currentUserId == customerId ? customerId : driverId;
  }

  int getUnreadCount(String currentUserId) {
    return currentUserId == customerId ? unreadCustomer : unreadDriver;
  }

  @override
  List<Object?> get props => [id, orderId, customerId, customerName, driverId, driverName, lastMessage, lastMessageAt, unreadCustomer, unreadDriver, status, createdAt];
}
