import 'dart:io';
import '../entities/order.dart';

abstract class OrderRepository {
  Stream<List<Order>> getAvailableOrders();

  Stream<List<Order>> getDriverActiveOrders();

  Stream<Order?> watchSingleActiveOrder();

  Future<Order?> getOrderById(String orderId);

  Future<Order?> acceptOrder(String driverId, String orderId);

  Future<Order?> updateOrderStatus(String driverId, String orderId, int status);

  Future<List<Order>> getRecentOrders(String driverId, {int limit = 10});

  Future<dynamic> respondOrder(String orderId, String action, String requestId);

  Future<Order?> confirmDeliveryWithPhoto(String orderId, File photo);

  Future<bool> reportOrderIssue(String orderId, String reason, String? additionalNote);
}
