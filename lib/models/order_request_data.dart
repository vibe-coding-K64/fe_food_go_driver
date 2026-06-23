class OrderRequestData {
  final String orderId;
  final String? requestId;
  final String? driverId;
  final String? event;
  final String? status;
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
  final DateTime? expiresAt;
  final int? requestType;

  OrderRequestData({
    required this.orderId,
    this.requestId,
    this.driverId,
    this.event,
    this.status,
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
      orderId: json['orderId']?.toString() ?? '',
      requestId: json['requestId']?.toString(),
      driverId: json['driverId']?.toString(),
      event: json['event']?.toString(),
      status: json['status']?.toString(),
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
      expiresAt: _toDateTime(json['expiresAt']),
      requestType: _toInt(json['requestType']),
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        final asInt = int.tryParse(value);
        return _toDateTime(asInt);
      }
    }
    if (value is int) {
      final milliseconds = value > 1000000000000 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    }
    return null;
  }
}

class OrderRequestNotification {
  final String type;
  final String? event;
  final OrderRequestData? data;
  final String? message;

  OrderRequestNotification({
    required this.type,
    this.event,
    this.data,
    this.message,
  });

  factory OrderRequestNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final dataMap = rawData is Map<String, dynamic>
        ? rawData
        : rawData is String && rawData.isNotEmpty
            ? <String, dynamic>{'orderId': rawData}
            : null;

    final rootHasOrderRequestFields =
        json['orderId'] != null || json['requestId'] != null || json['driverId'] != null;

    final normalizedPayload = dataMap ??
        (rootHasOrderRequestFields
            ? <String, dynamic>{
                ...json,
                if (json['message'] != null) 'message': json['message'],
              }
            : null);

    return OrderRequestNotification(
      type: json['type']?.toString() ?? json['event']?.toString() ?? '',
      event: json['event']?.toString(),
      data: normalizedPayload != null
          ? OrderRequestData.fromJson(normalizedPayload)
          : null,
      message: json['message']?.toString(),
    );
  }
}
