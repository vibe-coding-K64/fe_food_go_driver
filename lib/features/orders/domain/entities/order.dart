import 'package:equatable/equatable.dart';

class Order extends Equatable {
  final String id;
  final String orderCode;
  final String userId;
  final String? customerName;
  final String? customerPhone;
  final String? customerAvatarUrl;
  final String? recipientName;
  final String? recipientPhone;
  final String storeId;
  final String storeName;
  final String? storeAddress;
  final List<OrderItem> items;
  final double totalAmount;
  final double itemsSubtotal;
  final double optionsSubtotal;
  final double discountAmount;
  final double deliveryFee;
  final double finalAmount;
  final double driverCollectAmount;
  final int status;
  final String statusCode;
  final String? statusDescription;
  final String deliveryAddress;
  final int paymentMethod;
  final int? paymentStatus;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? vehiclePlate;
  final double? storeLat;
  final double? storeLng;
  final String? storePhone;
  final double? deliveryLat;
  final double? deliveryLng;
  final double? distance;
  final double? pickupDistanceKm;
  final double? deliveryDistanceKm;
  final int? estimatedDurationMinutes;
  final DateTime? arrivedAtStoreAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final String? deliveryStep;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? note;
  final String? requestId;
  final double? estimatedEarning;
  final DateTime? expiresAt;
  final int? expiresInSeconds;
  final String? deliveryPhotoUrl;

  const Order({
    required this.id,
    required this.orderCode,
    required this.userId,
    this.customerName,
    this.customerPhone,
    this.customerAvatarUrl,
    this.recipientName,
    this.recipientPhone,
    required this.storeId,
    required this.storeName,
    this.storeAddress,
    required this.items,
    required this.totalAmount,
    required this.itemsSubtotal,
    required this.optionsSubtotal,
    required this.discountAmount,
    required this.deliveryFee,
    required this.finalAmount,
    required this.driverCollectAmount,
    required this.status,
    required this.statusCode,
    this.statusDescription,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.paymentStatus,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehiclePlate,
    this.storeLat,
    this.storeLng,
    this.storePhone,
    this.deliveryLat,
    this.deliveryLng,
    this.distance,
    this.pickupDistanceKm,
    this.deliveryDistanceKm,
    this.estimatedDurationMinutes,
    this.arrivedAtStoreAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.deliveryStep,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.note,
    this.requestId,
    this.estimatedEarning,
    this.expiresAt,
    this.expiresInSeconds,
    this.deliveryPhotoUrl,
  });

  bool get isPendingStoreConfirmation => statusCode == 'PENDING_STORE_CONFIRMATION';
  bool get isWaitingDriver => statusCode == 'WAITING_DRIVER';
  bool get isDelivering => statusCode == 'DELIVERING';
  bool get isCompleted => statusCode == 'COMPLETED';
  bool get isCancelled => statusCode == 'CANCELLED';
  bool get isPickingUp => status == 1;
  bool get isOnTheWay => status == 2;

  String get displayRecipientName =>
      recipientName?.trim().isNotEmpty == true
          ? recipientName!.trim()
          : customerName?.trim().isNotEmpty == true
          ? customerName!.trim()
          : 'N/A';

  String? get displayRecipientPhone =>
      recipientPhone?.trim().isNotEmpty == true
          ? recipientPhone!.trim()
          : customerPhone?.trim().isNotEmpty == true
          ? customerPhone!.trim()
          : null;

  @override
  List<Object?> get props => [
    id,
    orderCode,
    userId,
    customerName,
    customerPhone,
    customerAvatarUrl,
    recipientName,
    recipientPhone,
    storeId,
    storeName,
    storeAddress,
    items,
    totalAmount,
    itemsSubtotal,
    optionsSubtotal,
    discountAmount,
    deliveryFee,
    finalAmount,
    driverCollectAmount,
    status,
    statusCode,
    statusDescription,
    deliveryAddress,
    paymentMethod,
    paymentStatus,
    driverId,
    driverName,
    driverPhone,
    vehiclePlate,
    storeLat,
    storeLng,
    storePhone,
    storePhone,
    deliveryLat,
    deliveryLng,
    distance,
    pickupDistanceKm,
    deliveryDistanceKm,
    estimatedDurationMinutes,
    arrivedAtStoreAt,
    pickedUpAt,
    deliveredAt,
    deliveryStep,
    createdAt,
    updatedAt,
    deletedAt,
    note,
    requestId,
    estimatedEarning,
    expiresAt,
    expiresInSeconds,
    deliveryPhotoUrl,
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
