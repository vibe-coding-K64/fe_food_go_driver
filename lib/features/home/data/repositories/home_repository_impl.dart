import '../../../orders/domain/entities/order.dart';
import '../../../driver/domain/entities/driver_location.dart';
import '../../../driver/domain/entities/driver_profile.dart';
import '../../../wallet/domain/entities/wallet.dart';
import '../datasources/driver_firebase_datasource.dart';
import '../datasources/order_firebase_datasource.dart';
import '../datasources/wallet_firebase_datasource.dart';
import '../datasources/home_remote_datasource.dart';

import 'package:equatable/equatable.dart';

class TodayStats extends Equatable {
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

  @override
  List<Object?> get props => [
        ordersToday,
        earningsToday,
        balance,
        totalOrders,
        rating,
      ];
}

class HomeRepository {
  final DriverFirebaseDataSource _driverFirebase;
  final OrderFirebaseDataSource _orderFirebase;
  final WalletFirebaseDataSource _walletFirebase;
  final HomeRemoteDataSource _homeRemote;

  HomeRepository({
    required DriverFirebaseDataSource driverFirebase,
    required OrderFirebaseDataSource orderFirebase,
    required WalletFirebaseDataSource walletFirebase,
    required HomeRemoteDataSource homeRemote,
  }) : _driverFirebase = driverFirebase,
       _orderFirebase = orderFirebase,
       _walletFirebase = walletFirebase,
       _homeRemote = homeRemote;

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

  Future<Map<String, dynamic>> getDriverStats() async {
    return await _homeRemote.getDriverStats();
  }
}
