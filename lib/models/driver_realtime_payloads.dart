import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../features/orders/data/models/order_model.dart';

class DriverRealtimeOrderRequest extends Equatable {
  final String event;
  final String? message;
  final String orderId;
  final String requestId;
  final double? estimatedEarning;
  final DateTime? expiresAt;
  final OrderModel order;

  const DriverRealtimeOrderRequest({
    required this.event,
    required this.message,
    required this.orderId,
    required this.requestId,
    required this.estimatedEarning,
    required this.expiresAt,
    required this.order,
  });

  factory DriverRealtimeOrderRequest.fromJson(Map<String, dynamic> json) {
    final orderJson = json['order'];
    if (orderJson is! Map<String, dynamic>) {
      throw const FormatException('Missing order payload in websocket request');
    }

    final normalizedOrderJson = <String, dynamic>{
      ...orderJson,
      'id': orderJson['id'] ?? json['orderId'],
      'requestId': orderJson['requestId'] ?? json['requestId'],
      'estimatedEarning':
          orderJson['estimatedEarning'] ?? json['estimatedEarning'],
      'expiresAt': orderJson['expiresAt'] ?? json['expiresAt'],
      'expiresInSeconds':
          orderJson['expiresInSeconds'] ?? json['expiresInSeconds'],
    };

    final order = OrderModel.fromJson(normalizedOrderJson);

    return DriverRealtimeOrderRequest(
      event: json['event']?.toString() ?? '',
      message: json['message']?.toString(),
      orderId: order.id,
      requestId: order.requestId ?? '',
      estimatedEarning: order.estimatedEarning,
      expiresAt: order.expiresAt,
      order: order,
    );
  }

  static DriverRealtimeOrderRequest fromRaw(String rawBody) {
    final decoded = jsonDecode(rawBody);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid websocket request payload');
    }
    return DriverRealtimeOrderRequest.fromJson(decoded);
  }

  bool get hasExpired =>
      expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt!.toUtc());

  DriverRealtimeOrderRequest copyWith({
    String? event,
    String? message,
    String? orderId,
    String? requestId,
    double? estimatedEarning,
    bool clearEstimatedEarning = false,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    OrderModel? order,
  }) {
    return DriverRealtimeOrderRequest(
      event: event ?? this.event,
      message: message ?? this.message,
      orderId: orderId ?? this.orderId,
      requestId: requestId ?? this.requestId,
      estimatedEarning: clearEstimatedEarning
          ? null
          : (estimatedEarning ?? this.estimatedEarning),
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => [
    event,
    message,
    orderId,
    requestId,
    estimatedEarning,
    expiresAt,
    order,
  ];
}

class DriverRealtimeOrderStatus extends Equatable {
  final String event;
  final String? message;
  final String? orderId;
  final String? status;
  final OrderModel? order;

  const DriverRealtimeOrderStatus({
    required this.event,
    required this.message,
    required this.orderId,
    required this.status,
    required this.order,
  });

  factory DriverRealtimeOrderStatus.fromJson(Map<String, dynamic> json) {
    final rawOrder = json['order'];
    return DriverRealtimeOrderStatus(
      event: json['event']?.toString() ?? '',
      message: json['message']?.toString(),
      orderId: json['orderId']?.toString(),
      status: json['status']?.toString(),
      order: rawOrder is Map<String, dynamic> ? OrderModel.fromJson(rawOrder) : null,
    );
  }

  static DriverRealtimeOrderStatus fromRaw(String rawBody) {
    final decoded = jsonDecode(rawBody);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid websocket status payload');
    }
    return DriverRealtimeOrderStatus.fromJson(decoded);
  }

  bool get isSuccess => status?.toUpperCase() == 'SUCCESS';
  bool get isError => status?.toUpperCase() == 'ERROR';
  bool get isAccepted => event == 'ORDER_ACCEPTED';
  bool get isAcceptFailed => event == 'ORDER_ACCEPT_FAILED';
  bool get isDeclined => event == 'ORDER_DECLINED';
  bool get isDeclineFailed => event == 'ORDER_DECLINE_FAILED';

  @override
  List<Object?> get props => [event, message, orderId, status, order];
}
