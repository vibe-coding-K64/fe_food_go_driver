import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../driver/domain/entities/driver_location.dart';
import '../../../driver/domain/entities/driver_profile.dart';
import '../../../wallet/domain/entities/wallet.dart';
import '../datasources/home_remote_datasource.dart';
import '../../../driver/data/datasources/driver_remote_datasource.dart';
import '../../../wallet/data/datasources/wallet_remote_datasource.dart';

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
  final HomeRemoteDataSource _homeRemote;
  final DriverRemoteDataSource _driverRemote;
  final WalletRemoteDataSource _walletRemote;

  HomeRepository({
    required HomeRemoteDataSource homeRemote,
    required DriverRemoteDataSource driverRemote,
    required WalletRemoteDataSource walletRemote,
  })  : _homeRemote = homeRemote,
        _driverRemote = driverRemote,
        _walletRemote = walletRemote;

  Future<DriverProfile> fetchDriverProfile(String driverId) async {
    return await _driverRemote.getDriverProfileApi(driverId);
  }

  Future<Map<String, dynamic>> fetchDriverStats() async {
    return await _homeRemote.getDriverStats();
  }

  Future<List<Order>> fetchActiveOrders() async {
    return await _homeRemote.getActiveOrders();
  }

  Future<List<Order>> fetchRecentOrders({int limit = 20}) async {
    return await _homeRemote.getRecentOrders(limit: limit);
  }

  Future<List<Order>> fetchAvailableOrders() async {
    return await _homeRemote.getAvailableOrders();
  }

  Future<void> declineAvailableOrder(String orderId, String driverId) async {
    await _homeRemote.declineAvailableOrder(orderId, driverId);
  }

  Future<Wallet?> fetchWallet(String driverId) async {
    return await _walletRemote.getWallet(driverId);
  }

  Future<DriverLocation?> fetchDriverLocation(String driverId) async {
    return await _homeRemote.getDriverLocation(driverId);
  }

  Stream<DriverLocation?> watchDriverLocation(String driverId) {
    return Stream.periodic(const Duration(seconds: 5), (_) => driverId)
        .asyncMap((id) => fetchDriverLocation(id))
        .handleError((e) => debugPrint('[HomeRepository] watchDriverLocation error: $e'));
  }

  Future<void> dispose() async {}
}
