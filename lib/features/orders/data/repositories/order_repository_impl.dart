import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;

  OrderRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<Order>> getAvailableOrders() async* {
    while (true) {
      try {
        final orders = await _remoteDataSource.getAvailableOrders();
        yield orders;
      } catch (_) {
        yield [];
      }
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  @override
  Stream<List<Order>> getDriverActiveOrders() async* {
    while (true) {
      try {
        final orders = await _remoteDataSource.getDriverActiveOrders();
        yield orders;
      } catch (_) {
        yield [];
      }
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  @override
  Stream<Order?> watchSingleActiveOrder() async* {
    while (true) {
      try {
        final order = await _remoteDataSource.getSingleActiveOrder();
        yield order;
      } catch (_) {
        yield null;
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    return _remoteDataSource.getOrderById(orderId);
  }

  @override
  Future<Order?> acceptOrder(String driverId, String orderId) async {
    return _remoteDataSource.acceptOrderApi(driverId, orderId);
  }

  @override
  Future<Order?> updateOrderStatus(
    String driverId,
    String orderId,
    int status,
  ) async {
    return _remoteDataSource.updateOrderStatusApi(driverId, orderId, status);
  }

  @override
  Future<List<Order>> getRecentOrders(String driverId, {int limit = 10}) async {
    return _remoteDataSource.getRecentOrders(driverId, limit: limit);
  }

  @override
  Future<dynamic> respondOrder(
    String orderId,
    String action,
    String requestId,
  ) async {
    return _remoteDataSource.respondOrderApi(orderId, action, requestId);
  }
}
