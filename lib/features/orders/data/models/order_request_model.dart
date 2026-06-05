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

  const OrderRequestModel({
    required this.id,
    required this.orderId,
    required this.driverId,
    required this.status,
    required this.createdAt,
    this.orderData,
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

  @override
  List<Object?> get props => [id, orderId, driverId, status, createdAt];
}
