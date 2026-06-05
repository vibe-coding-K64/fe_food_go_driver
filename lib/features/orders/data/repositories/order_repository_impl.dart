import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../data/models/order_request_model.dart';
import '../datasources/order_remote_datasource.dart';
import '../datasources/order_request_firebase_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;
  final OrderRequestFirebaseDataSource _requestFirebaseDataSource;

  OrderRepositoryImpl(
    this._remoteDataSource, {
    OrderRequestFirebaseDataSource? requestFirebaseDataSource,
  }) : _requestFirebaseDataSource =
           requestFirebaseDataSource ?? OrderRequestFirebaseDataSource();

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
  Future<void> acceptOrder(String driverId, String orderId) async {
    await _remoteDataSource.acceptOrderApi(driverId, orderId);
  }

  @override
  Future<void> updateOrderStatus(
    String driverId,
    String orderId,
    int status,
  ) async {
    await _remoteDataSource.updateOrderStatusApi(driverId, orderId, status);
  }

  @override
  Future<List<Order>> getRecentOrders(String driverId, {int limit = 10}) async {
    return _remoteDataSource.getRecentOrders(driverId, limit: limit);
  }

  @override
  Stream<List<OrderRequestModel>> watchOrderRequests(String driverId) {
    return _requestFirebaseDataSource.watchOrderRequests(driverId);
  }

  @override
  Future<void> respondOrder(String orderId, String action) async {
    await _remoteDataSource.respondOrderApi(orderId, action);
  }

  @override
  Future<void> deleteOrderRequest(String driverId, String requestId) async {
    await _requestFirebaseDataSource.deleteOrderRequest(driverId, requestId);
  }
}
