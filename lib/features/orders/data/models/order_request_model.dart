import 'package:equatable/equatable.dart';
import 'order_model.dart';

enum OrderRequestStatus {
  pending,
  accepted,
  declined,
  expired,
}

class OrderRequestModel extends Equatable {
  final String id;
  final String orderId;
  final String driverId;
  final int status;
  final DateTime createdAt;
  final OrderModel? orderData;
  final DateTime? expiresAt;
  final int? expiresInSeconds;

  const OrderRequestModel({
    required this.id,
    required this.orderId,
    required this.driverId,
    required this.status,
    required this.createdAt,
    this.orderData,
    this.expiresAt,
    this.expiresInSeconds,
  });

  OrderRequestStatus get requestStatus {
    switch (status) {
      case 0:
        return OrderRequestStatus.pending;
      case 1:
        return OrderRequestStatus.accepted;
      case 2:
        return OrderRequestStatus.declined;
      case 3:
        return OrderRequestStatus.expired;
      default:
        return OrderRequestStatus.pending;
    }
  }

  bool get isPending => requestStatus == OrderRequestStatus.pending;

  OrderRequestModel copyWith({
    String? id,
    String? orderId,
    String? driverId,
    int? status,
    DateTime? createdAt,
    OrderModel? orderData,
    bool clearOrderData = false,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    int? expiresInSeconds,
    bool clearExpiresInSeconds = false,
  }) {
    return OrderRequestModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      orderData: clearOrderData ? null : (orderData ?? this.orderData),
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
      expiresInSeconds: clearExpiresInSeconds
          ? null
          : (expiresInSeconds ?? this.expiresInSeconds),
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderId,
    driverId,
    status,
    createdAt,
    orderData,
    expiresAt,
    expiresInSeconds,
  ];
}
