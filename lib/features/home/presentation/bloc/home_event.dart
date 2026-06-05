import 'package:equatable/equatable.dart';

import '../../../../models/driver_realtime_payloads.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

final class HomeLoadRequested extends HomeEvent {
  final bool resetStreams;

  const HomeLoadRequested({this.resetStreams = true});

  @override
  List<Object?> get props => [resetStreams];
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

final class ClearSuccessMessage extends HomeEvent {
  const ClearSuccessMessage();
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

final class LoadWalletRequested extends HomeEvent {
  const LoadWalletRequested();
}

final class LoadStatsRequested extends HomeEvent {
  const LoadStatsRequested();
}

final class ForegroundFcmOrderSignalReceived extends HomeEvent {
  final String orderId;
  final String? requestId;

  const ForegroundFcmOrderSignalReceived(this.orderId, {this.requestId});

  @override
  List<Object?> get props => [orderId, requestId];
}

final class DismissOrderRequestPrompt extends HomeEvent {
  final String orderId;

  const DismissOrderRequestPrompt(this.orderId);

  @override
  List<Object?> get props => [orderId];
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

  bool get hasValidRequestId => requestId.isNotEmpty;

  @override
  List<Object?> get props => [requestId, orderId, action];
}

final class RealtimeOrderStatusReceived extends HomeEvent {
  final DriverRealtimeOrderStatus payload;

  const RealtimeOrderStatusReceived(this.payload);

  @override
  List<Object?> get props => [payload];
}

final class RealtimeOrderRequestReceived extends HomeEvent {
  final DriverRealtimeOrderRequest payload;

  const RealtimeOrderRequestReceived(this.payload);

  @override
  List<Object?> get props => [payload];
}

