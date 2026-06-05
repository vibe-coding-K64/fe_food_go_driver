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

enum NotificationLoadStatus { initial, loading, loaded, error }

class NotificationState extends Equatable {
  final NotificationLoadStatus status;
  final List<DriverNotification> notifications;
  final String? errorMessage;

  const NotificationState({
    this.status = NotificationLoadStatus.initial,
    this.notifications = const [],
    this.errorMessage,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    NotificationLoadStatus? status,
    List<DriverNotification>? notifications,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, notifications, errorMessage];
}
