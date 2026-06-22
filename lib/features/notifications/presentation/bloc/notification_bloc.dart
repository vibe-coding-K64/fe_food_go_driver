import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../domain/entities/driver_notification.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationRemoteDataSource? _dataSource;

  NotificationBloc() : super(const NotificationState()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationRead>(_onMarkRead);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
    on<DeleteNotification>(_onDelete);
  }

  NotificationRemoteDataSource _getDataSource() {
    _dataSource ??= NotificationRemoteDataSource(
      getToken: () async {
        final storage = getIt<FlutterSecureStorage>();
        return await storage.read(key: AppConstants.driverTokenKey) ?? '';
      },
      secureStorage: getIt<FlutterSecureStorage>(),
    );
    return _dataSource!;
  }

  Future<void> _onLoadNotifications(
      LoadNotifications event, Emitter<NotificationState> emit) async {
    emit(state.copyWith(status: NotificationLoadStatus.loading));
    try {
      final notifications = await _getDataSource().getNotifications();

      emit(state.copyWith(
        status: NotificationLoadStatus.loaded,
        notifications: notifications,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationLoadStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onMarkRead(
      MarkNotificationRead event, Emitter<NotificationState> emit) async {
    try {
      await _getDataSource().markAsRead(event.notificationId);

      final updated = state.notifications.map((n) {
        if (n.id == event.notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      emit(state.copyWith(notifications: updated));
    } catch (_) {}
  }

  Future<void> _onMarkAllRead(
      MarkAllNotificationsRead event, Emitter<NotificationState> emit) async {
    try {
      await _getDataSource().markAllAsRead();

      final updated =
          state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      emit(state.copyWith(notifications: updated));
    } catch (_) {}
  }

  Future<void> _onDelete(
      DeleteNotification event, Emitter<NotificationState> emit) async {
    try {
      await _getDataSource().deleteNotification(event.notificationId);

      final updated = state.notifications
          .where((n) => n.id != event.notificationId)
          .toList();
      emit(state.copyWith(notifications: updated));
    } catch (_) {}
  }
}
