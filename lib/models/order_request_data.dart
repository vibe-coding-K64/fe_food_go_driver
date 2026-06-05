class OrderRequestData {
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

  OrderRequestData({
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

  factory OrderRequestData.fromJson(Map<String, dynamic> json) {
    return OrderRequestData(
      orderId: json['orderId'] ?? '',
      orderCode: json['orderCode']?.toString(),
      message: json['message']?.toString(),
      storeName: json['storeName']?.toString(),
      storeAddress: json['storeAddress']?.toString(),
      storeLat: _toDouble(json['storeLat']),
      storeLng: _toDouble(json['storeLng']),
      deliveryAddress: json['deliveryAddress']?.toString(),
      receiverName: json['receiverName']?.toString(),
      receiverPhone: json['receiverPhone']?.toString(),
      deliveryLat: _toDouble(json['deliveryLat']),
      deliveryLng: _toDouble(json['deliveryLng']),
      deliveryHeading: _toDouble(json['deliveryHeading']),
      deliveryFee: _toDouble(json['deliveryFee']),
      totalAmount: _toDouble(json['totalAmount']),
      finalAmount: _toDouble(json['finalAmount']),
      paymentMethod: json['paymentMethod']?.toString(),
      note: json['note']?.toString(),
      estimatedEarning: _toDouble(json['estimatedEarning']),
      expiresAt: json['expiresAt'] is int ? json['expiresAt'] : int.tryParse(json['expiresAt']?.toString() ?? ''),
      requestType: json['requestType'] is int ? json['requestType'] : int.tryParse(json['requestType']?.toString() ?? ''),
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class OrderRequestNotification {
  final String type;
  final OrderRequestData? data;
  final String? message;

  OrderRequestNotification({
    required this.type,
    this.data,
    this.message,
  });

  factory OrderRequestNotification.fromJson(Map<String, dynamic> json) {
    return OrderRequestNotification(
      type: json['type'] ?? '',
      data: json['data'] != null
          ? OrderRequestData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message']?.toString(),
    );
  }
}
