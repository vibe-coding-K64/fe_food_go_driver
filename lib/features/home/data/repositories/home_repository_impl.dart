import '../../../orders/domain/entities/order.dart';
import '../../../driver/domain/entities/driver_location.dart';
import '../../../driver/domain/entities/driver_profile.dart';
import '../../../wallet/domain/entities/wallet.dart';
import '../datasources/driver_firebase_datasource.dart';
import '../datasources/order_firebase_datasource.dart';
import '../datasources/wallet_firebase_datasource.dart';

class TodayStats {
  final int ordersToday;
  final double earningsToday;
  final double balance;
  final int totalOrders;
  final double rating;

  const TodayStats({
    this.ordersToday = 0,
    this.earningsToday = 0.0,
    this.balance = 0.0,
    this.totalOrders = 0,
    this.rating = 0.0,
  });
}

class HomeRepository {
  final DriverFirebaseDataSource _driverFirebase;
  final OrderFirebaseDataSource _orderFirebase;
  final WalletFirebaseDataSource _walletFirebase;

  HomeRepository({
    required DriverFirebaseDataSource driverFirebase,
    required OrderFirebaseDataSource orderFirebase,
    required WalletFirebaseDataSource walletFirebase,
  }) : _driverFirebase = driverFirebase,
       _orderFirebase = orderFirebase,
       _walletFirebase = walletFirebase;

  Stream<DriverProfile?> watchDriverProfile(String driverId) {
    return _driverFirebase.watchDriverProfile(driverId);
  }

  Stream<Map<String, dynamic>> watchDriverStats(String driverId) {
    return _driverFirebase.watchDriverStats(driverId).map((data) {
      return {
        'ordersToday': data['ordersToday'] ?? 0,
        'earningsToday': (data['earningsToday'] ?? 0.0).toDouble(),
        'balance': (data['balance'] ?? 0.0).toDouble(),
      };
    });
  }

  Stream<DriverLocation?> watchDriverLocation(String driverId) {
    return _driverFirebase.watchDriverLocation(driverId);
  }

  Stream<Order?> watchCurrentOrder(String driverId) {
    return _orderFirebase.watchSingleActiveOrder(driverId);
  }

  Stream<List<Order>> watchRecentOrders(String driverId, {int limit = 20}) {
    return _orderFirebase.watchDriverRecentOrders(driverId, limit: limit);
  }

  Stream<Wallet?> watchWallet(String driverId) {
    return _walletFirebase.watchWallet(driverId);
  }
}
