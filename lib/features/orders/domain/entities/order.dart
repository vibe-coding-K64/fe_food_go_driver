import 'package:equatable/equatable.dart';

class Order extends Equatable {
  final String id;
  final String userId;
  final String storeId;
  final String storeName;
  final String? storeAddress;
  final List<OrderItem> items;
  final double totalAmount;
  final double deliveryFee;
  final int status;
  final String deliveryAddress;
  final String paymentMethod;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? vehiclePlate;
  final double? storeLat;
  final double? storeLng;
  final double? deliveryLat;
  final double? deliveryLng;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? receiverName;
  final String? receiverPhone;
  final String? code;
  final String? note;
  final double? estimatedEarning;

  const Order({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.storeName,
    this.storeAddress,
    required this.items,
    required this.totalAmount,
    required this.deliveryFee,
    required this.status,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehiclePlate,
    this.storeLat,
    this.storeLng,
    this.deliveryLat,
    this.deliveryLng,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.receiverName,
    this.receiverPhone,
    this.code,
    this.note,
    this.estimatedEarning,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    storeId,
    storeName,
    storeAddress,
    items,
    totalAmount,
    deliveryFee,
    status,
    deliveryAddress,
    paymentMethod,
    driverId,
    driverName,
    driverPhone,
    vehiclePlate,
    storeLat,
    storeLng,
    deliveryLat,
    deliveryLng,
    createdAt,
    updatedAt,
    deletedAt,
    receiverName,
    receiverPhone,
    code,
    note,
    estimatedEarning,
  ];
}

class OrderItem extends Equatable {
  final String foodId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;
  final List<ItemOption>? options;

  const OrderItem({
    required this.foodId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.options,
  });

  @override
  List<Object?> get props => [foodId, name, price, quantity, imageUrl, options];
}

class ItemOption extends Equatable {
  final String name;
  final double price;

  const ItemOption({required this.name, required this.price});

  @override
  List<Object?> get props => [name, price];
}
