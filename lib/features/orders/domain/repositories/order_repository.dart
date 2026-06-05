import '../entities/order.dart';
import '../../data/models/order_request_model.dart';

abstract class OrderRepository {
  Stream<List<Order>> getAvailableOrders();

  Stream<List<Order>> getDriverActiveOrders();

  Stream<Order?> watchSingleActiveOrder();

  Future<void> acceptOrder(String driverId, String orderId);

  Future<void> updateOrderStatus(String driverId, String orderId, int status);

  Future<List<Order>> getRecentOrders(String driverId, {int limit = 10});

  Stream<List<OrderRequestModel>> watchOrderRequests(String driverId);

  Future<void> respondOrder(String orderId, String action);

  Future<void> deleteOrderRequest(String driverId, String requestId);
}
