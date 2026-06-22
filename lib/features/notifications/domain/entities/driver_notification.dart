import 'package:equatable/equatable.dart';

class DriverNotification extends Equatable {
  final String id;
  final int type;
  final String title;
  final String body;
  final String? orderId;
  final String? referenceId;
  final bool isRead;
  final String? imageUrl;
  final DateTime createdAt;

  const DriverNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.orderId,
    this.referenceId,
    this.isRead = false,
    this.imageUrl,
    required this.createdAt,
  });

  factory DriverNotification.fromJson(Map<String, dynamic> json) {
    return DriverNotification(
      id: json['id']?.toString() ?? json['notificationId']?.toString() ?? '',
      type: json['type'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      orderId: json['orderId']?.toString(),
      referenceId: json['referenceId']?.toString(),
      isRead: json['isRead'] as bool? ?? json['is_read'] as bool? ?? false,
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is Map) {
      final seconds = value['_seconds'] as int?;
      final nanos = value['_nanoseconds'] as int?;
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanos ?? 0) ~/ 1000000,
        );
      }
    }
    return DateTime.now();
  }

  DriverNotification copyWith({bool? isRead}) {
    return DriverNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      orderId: orderId,
      referenceId: referenceId,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, type, title, body, orderId, referenceId, isRead, imageUrl, createdAt];
}
