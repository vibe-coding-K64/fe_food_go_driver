import '../../domain/entities/order.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.userId,
    required super.storeId,
    required super.storeName,
    super.storeAddress,
    required super.items,
    required super.totalAmount,
    required super.deliveryFee,
    required super.status,
    required super.deliveryAddress,
    required super.paymentMethod,
    super.driverId,
    super.driverName,
    super.driverPhone,
    super.vehiclePlate,
    super.storeLat,
    super.storeLng,
    super.deliveryLat,
    super.deliveryLng,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.receiverName,
    super.receiverPhone,
    super.code,
    super.note,
    super.estimatedEarning,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      storeId: json['storeId']?.toString() ?? '',
      storeName: json['storeName']?.toString() ?? '',
      storeAddress: json['storeAddress']?.toString(),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      status: json['status'] ?? 0,
      deliveryAddress: json['deliveryAddress']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? 'CASH',
      driverId: json['driverId']?.toString(),
      driverName: json['driverName']?.toString(),
      driverPhone: json['driverPhone']?.toString(),
      vehiclePlate: json['vehiclePlate']?.toString(),
      storeLat: json['storeLat']?.toDouble(),
      storeLng: json['storeLng']?.toDouble(),
      deliveryLat: json['deliveryLat']?.toDouble(),
      deliveryLng: json['deliveryLng']?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'].toString())
          : null,
      receiverName: json['receiverName']?.toString(),
      receiverPhone: json['receiverPhone']?.toString(),
      code: json['code']?.toString(),
      note: json['note']?.toString(),
      estimatedEarning: json['estimatedEarning']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'storeId': storeId,
      'storeName': storeName,
      'storeAddress': storeAddress,
      'items': items.map((e) => (e as OrderItemModel).toJson()).toList(),
      'totalAmount': totalAmount,
      'deliveryFee': deliveryFee,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehiclePlate': vehiclePlate,
      'storeLat': storeLat,
      'storeLng': storeLng,
      'deliveryLat': deliveryLat,
      'deliveryLng': deliveryLng,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'code': code,
      'note': note,
      'estimatedEarning': estimatedEarning,
    };
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
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
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
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'price': price};
  }
}
