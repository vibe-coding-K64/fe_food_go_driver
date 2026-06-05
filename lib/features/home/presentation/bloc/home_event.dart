import 'package:equatable/equatable.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

final class HomeLoadRequested extends HomeEvent {
  const HomeLoadRequested();
}

final class HomeStopListening extends HomeEvent {
  const HomeStopListening();
}

final class ToggleDriverStatus extends HomeEvent {
  const ToggleDriverStatus();
}

final class SetDriverOnlineRequested extends HomeEvent {
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;

  const SetDriverOnlineRequested({
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speed,
  });

  @override
  List<Object?> get props => [latitude, longitude, heading, speed];
}

final class SetDriverOfflineRequested extends HomeEvent {
  const SetDriverOfflineRequested();
}

final class ClearErrorMessage extends HomeEvent {
  const ClearErrorMessage();
}

final class ClearLocationPermissionRequest extends HomeEvent {
  const ClearLocationPermissionRequest();
}

final class TriggerReLogin extends HomeEvent {
  const TriggerReLogin();
}

final class AcceptOrderRequested extends HomeEvent {
  final String orderId;

  const AcceptOrderRequested({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

final class CompleteOrderPressed extends HomeEvent {
  final String orderId;

  const CompleteOrderPressed(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

final class ConfirmPickupPressed extends HomeEvent {
  final String orderId;

  const ConfirmPickupPressed(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

final class CancelOrderPressed extends HomeEvent {
  final String orderId;

  const CancelOrderPressed(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

// Internal events for Firebase stream updates - must be in same file as sealed class
class ProfileUpdated extends HomeEvent {
  final dynamic profile;
  const ProfileUpdated(this.profile);
}

class ActiveOrderUpdated extends HomeEvent {
  final dynamic order;
  const ActiveOrderUpdated(this.order);
}

class RecentOrdersUpdated extends HomeEvent {
  final List<dynamic> orders;
  const RecentOrdersUpdated(this.orders);
}

class StatsUpdated extends HomeEvent {
  final dynamic stats;
  const StatsUpdated(this.stats);
}

class WalletUpdated extends HomeEvent {
  final dynamic wallet;
  const WalletUpdated(this.wallet);
}

final class OrderRequestsUpdated extends HomeEvent {
  final List<dynamic> requests;
  const OrderRequestsUpdated(this.requests);
}

final class RespondToOrderRequest extends HomeEvent {
  final String requestId;
  final String orderId;
  final String action;

  const RespondToOrderRequest({
    required this.requestId,
    required this.orderId,
    required this.action,
  });

  @override
  List<Object?> get props => [requestId, orderId, action];
}

final class WsOrderRequestReceived extends HomeEvent {
  final String orderId;
  final String? orderCode;
  final String? message;
  final String? storeName;
  final String? storeAddress;
  final double? storeLat;
  final double? storeLng;
  final String? deliveryAddress;
  final String? receiverName;
  final String? receiverPhone;
  final double? deliveryLat;
  final double? deliveryLng;
  final double? deliveryHeading;
  final double? deliveryFee;
  final double? totalAmount;
  final double? finalAmount;
  final String? paymentMethod;
  final String? note;
  final double? estimatedEarning;
  final int? expiresAt;
  final int? requestType;

  const WsOrderRequestReceived({
    required this.orderId,
    this.orderCode,
    this.message,
    this.storeName,
    this.storeAddress,
    this.storeLat,
    this.storeLng,
    this.deliveryAddress,
    this.receiverName,
    this.receiverPhone,
    this.deliveryLat,
    this.deliveryLng,
    this.deliveryHeading,
    this.deliveryFee,
    this.totalAmount,
    this.finalAmount,
    this.paymentMethod,
    this.note,
    this.estimatedEarning,
    this.expiresAt,
    this.requestType,
  });

  @override
  List<Object?> get props => [
        orderId,
        orderCode,
        message,
        storeName,
        storeAddress,
        storeLat,
        storeLng,
        deliveryAddress,
        receiverName,
        receiverPhone,
        deliveryLat,
        deliveryLng,
        deliveryHeading,
        deliveryFee,
        totalAmount,
        finalAmount,
        paymentMethod,
        note,
        estimatedEarning,
        expiresAt,
        requestType,
      ];
}

final class WsOrderStatusReceived extends HomeEvent {
  final String type;
  final String? orderId;
  final String? message;

  const WsOrderStatusReceived({
    required this.type,
    this.orderId,
    this.message,
  });

  @override
  List<Object?> get props => [type, orderId, message];
}
