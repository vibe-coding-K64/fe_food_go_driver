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
  final String? source;
  final DateTime? expiresAt;
  final int? expiresInSeconds;

  const OrderRequestModel({
    required this.id,
    required this.orderId,
    required this.driverId,
    required this.status,
    required this.createdAt,
    this.orderData,
    this.source,
    this.expiresAt,
    this.expiresInSeconds,
  });

  factory OrderRequestModel.fromFirestore(String docId, Map<String, dynamic> data) {
    OrderModel? order;
    if (data['orderData'] != null) {
      order = OrderModel.fromJson(data['orderData'] as Map<String, dynamic>);
    }

    return OrderRequestModel(
      id: docId,
      orderId: data['orderId']?.toString() ?? '',
      driverId: data['driverId']?.toString() ?? '',
      status: data['status'] ?? 0,
      createdAt: _parseDateTime(data['createdAt']),
      orderData: order,
      source: 'firestore',
      expiresAt: _parseNullableDateTime(data['expiresAt']),
      expiresInSeconds: _parseNullableInt(data['expiresInSeconds']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

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
    String? source,
    bool clearSource = false,
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
      source: clearSource ? null : (source ?? this.source),
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
    source,
    expiresAt,
    expiresInSeconds,
  ];
}
