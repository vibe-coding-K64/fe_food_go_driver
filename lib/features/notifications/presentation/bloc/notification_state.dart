import 'package:equatable/equatable.dart';
import '../../domain/entities/driver_notification.dart';

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
