import '../../domain/entities/order.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.orderCode,
    required super.userId,
    super.customerName,
    super.customerPhone,
    super.customerAvatarUrl,
    super.recipientName,
    super.recipientPhone,
    required super.storeId,
    required super.storeName,
    super.storeAddress,
    required super.items,
    required super.totalAmount,
    required super.itemsSubtotal,
    required super.optionsSubtotal,
    required super.discountAmount,
    required super.deliveryFee,
    required super.finalAmount,
    required super.driverCollectAmount,
    required super.status,
    required super.statusCode,
    super.statusDescription,
    required super.deliveryAddress,
    required super.paymentMethod,
    super.paymentStatus,
    super.driverId,
    super.driverName,
    super.driverPhone,
    super.vehiclePlate,
    super.storeLat,
    super.storeLng,
    super.storePhone,
    super.deliveryLat,
    super.deliveryLng,
    super.distance,
    super.pickupDistanceKm,
    super.deliveryDistanceKm,
    super.estimatedDurationMinutes,
    super.arrivedAtStoreAt,
    super.pickedUpAt,
    super.deliveredAt,
    super.deliveryStep,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.note,
    super.requestId,
    super.estimatedEarning,
    super.expiresAt,
    super.expiresInSeconds,
    super.deliveryPhotoUrl,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final normalizedStatusCode = json['statusCode']?.toString() ?? _mapStatusCode(json['status']);
    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderCode: json['orderCode']?.toString() ?? json['code']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      customerName: json['customerName']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      customerAvatarUrl: json['customerAvatarUrl']?.toString(),
      recipientName:
          json['recipientName']?.toString() ?? json['receiverName']?.toString(),
      recipientPhone:
          json['recipientPhone']?.toString() ?? json['receiverPhone']?.toString(),
      storeId: json['storeId']?.toString() ?? '',
      storeName: json['storeName']?.toString() ?? '',
      storeAddress: json['storeAddress']?.toString(),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: _toDouble(json['totalAmount']),
      itemsSubtotal: _toDouble(json['itemsSubtotal']),
      optionsSubtotal: _toDouble(json['optionsSubtotal']),
      discountAmount: _toDouble(json['discountAmount']),
      deliveryFee: _toDouble(json['deliveryFee']),
      finalAmount: _toDouble(json['finalAmount']),
      driverCollectAmount: _toDouble(json['driverCollectAmount']),
      status: _toInt(json['status']),
      statusCode: normalizedStatusCode,
      statusDescription: json['statusDescription']?.toString(),
      deliveryAddress: json['deliveryAddress']?.toString() ?? '',
      paymentMethod: _toInt(json['paymentMethod']),
      paymentStatus: _nullableInt(json['paymentStatus']),
      driverId: json['driverId']?.toString(),
      driverName: json['driverName']?.toString(),
      driverPhone: json['driverPhone']?.toString(),
      vehiclePlate: json['vehiclePlate']?.toString(),
      storeLat: _nullableDouble(json['storeLat']),
      storeLng: _nullableDouble(json['storeLng']),
      storePhone: json['storePhone']?.toString(),
      deliveryLat: _nullableDouble(json['deliveryLat']),
      deliveryLng: _nullableDouble(json['deliveryLng']),
      distance: _nullableDouble(json['distance']),
      pickupDistanceKm: _nullableDouble(json['pickupDistanceKm']),
      deliveryDistanceKm: _nullableDouble(json['deliveryDistanceKm']),
      estimatedDurationMinutes: _nullableInt(json['estimatedDurationMinutes']),
      arrivedAtStoreAt: _toDateTime(json['arrivedAtStoreAt']),
      pickedUpAt: _toDateTime(json['pickedUpAt']),
      deliveredAt: _toDateTime(json['deliveredAt']),
      deliveryStep: json['deliveryStep']?.toString(),
      createdAt: _toDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _toDateTime(json['updatedAt']) ?? DateTime.now(),
      deletedAt: _toDateTime(json['deletedAt']),
      note: json['note']?.toString(),
      requestId: json['requestId']?.toString(),
      estimatedEarning: _nullableDouble(json['estimatedEarning']),
      expiresAt: _toDateTime(json['expiresAt']),
      expiresInSeconds: _nullableInt(json['expiresInSeconds']),
      deliveryPhotoUrl: json['deliveryPhotoUrl']?.toString() ?? json['delivery_photo_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderCode': orderCode,
      'userId': userId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAvatarUrl': customerAvatarUrl,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'storeId': storeId,
      'storeName': storeName,
      'storeAddress': storeAddress,
      'items': items.map((e) => (e as OrderItemModel).toJson()).toList(),
      'totalAmount': totalAmount,
      'itemsSubtotal': itemsSubtotal,
      'optionsSubtotal': optionsSubtotal,
      'discountAmount': discountAmount,
      'deliveryFee': deliveryFee,
      'finalAmount': finalAmount,
      'driverCollectAmount': driverCollectAmount,
      'status': status,
      'statusCode': statusCode,
      'statusDescription': statusDescription,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehiclePlate': vehiclePlate,
      'storeLat': storeLat,
      'storeLng': storeLng,
      'storePhone': storePhone,
      'deliveryLat': deliveryLat,
      'deliveryLng': deliveryLng,
      'distance': distance,
      'pickupDistanceKm': pickupDistanceKm,
      'deliveryDistanceKm': deliveryDistanceKm,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'arrivedAtStoreAt': arrivedAtStoreAt?.toIso8601String(),
      'pickedUpAt': pickedUpAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'deliveryStep': deliveryStep,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'note': note,
      'requestId': requestId,
      'estimatedEarning': estimatedEarning,
      'expiresAt': expiresAt?.toIso8601String(),
      'expiresInSeconds': expiresInSeconds,
      'deliveryPhotoUrl': deliveryPhotoUrl,
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    return _toInt(value);
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) return null;
    return _toDouble(value);
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static String _mapStatusCode(dynamic status) {
    switch (_toInt(status)) {
      case 0:
        return 'PENDING_STORE_CONFIRMATION';
      case 1:
        return 'WAITING_DRIVER';
      case 2:
        return 'DELIVERING';
      case 3:
        return 'COMPLETED';
      case 4:
        return 'CANCELLED';
      default:
        return 'UNKNOWN';
    }
  }
}

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.foodId,
    required super.name,
    required super.price,
    required super.quantity,
    super.imageUrl,
    super.options,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      foodId: json['foodId']?.toString() ?? json['food_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: OrderModel._toDouble(json['price']),
      quantity: OrderModel._toInt(json['quantity'] ?? 1),
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => ItemOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'options': options?.map((e) => (e as ItemOptionModel).toJson()).toList(),
    };
  }
}

class ItemOptionModel extends ItemOption {
  const ItemOptionModel({required super.name, required super.price});

  factory ItemOptionModel.fromJson(Map<String, dynamic> json) {
    return ItemOptionModel(
      name: json['name']?.toString() ?? '',
      price: OrderModel._toDouble(json['price']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'price': price};
  }
}
