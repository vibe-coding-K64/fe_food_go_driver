import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  String? _driverId;

  NotificationBloc() : super(const NotificationState()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationRead>(_onMarkRead);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
    on<DeleteNotification>(_onDelete);
  }

  Future<void> _onLoadNotifications(
      LoadNotifications event, Emitter<NotificationState> emit) async {
    emit(state.copyWith(status: NotificationLoadStatus.loading));
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(state.copyWith(
          status: NotificationLoadStatus.loaded,
          notifications: const [],
        ));
        return;
      }
      _driverId = user.uid;

      final snap = await FirebaseFirestore.instance
          .collection('driver_profiles')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final notifications = snap.docs.map((doc) {
        final data = doc.data();
        return DriverNotification(
          id: doc.id,
          type: data['type'] as int? ?? 0,
          title: data['title'] as String? ?? '',
          body: data['body'] as String? ?? '',
          orderId: data['orderId'] as String?,
          referenceId: data['referenceId'] as String?,
          isRead: data['isRead'] as bool? ?? false,
          imageUrl: data['imageUrl'] as String?,
          createdAt: _parseTimestamp(data['createdAt']),
        );
      }).toList();

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
    if (_driverId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('driver_profiles')
          .doc(_driverId)
          .collection('notifications')
          .doc(event.notificationId)
          .update({'isRead': true});

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
    if (_driverId == null) return;
    try {
      final unreadIds =
          state.notifications.where((n) => !n.isRead).map((n) => n.id).toList();

      final batch = FirebaseFirestore.instance.batch();
      for (final id in unreadIds) {
        final ref = FirebaseFirestore.instance
            .collection('driver_profiles')
            .doc(_driverId)
            .collection('notifications')
            .doc(id);
        batch.update(ref, {'isRead': true});
      }
      await batch.commit();

      final updated =
          state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      emit(state.copyWith(notifications: updated));
    } catch (_) {}
  }

  Future<void> _onDelete(
      DeleteNotification event, Emitter<NotificationState> emit) async {
    if (_driverId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('driver_profiles')
          .doc(_driverId)
          .collection('notifications')
          .doc(event.notificationId)
          .delete();

      final updated = state.notifications
          .where((n) => n.id != event.notificationId)
          .toList();
      emit(state.copyWith(notifications: updated));
    } catch (_) {}
  }

  DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Map) {
      final seconds = value['_seconds'] as int?;
      final nanos = value['_nanoseconds'] as int?;
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanos ?? 0) ~/ 1000000,
        );
      }
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
