import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _remoteDataSource;
  final FlutterSecureStorage _secureStorage;

  WalletRepositoryImpl(this._remoteDataSource, this._secureStorage);

  Future<String> _getDriverId() async {
    return await _secureStorage.read(key: AppConstants.driverIdKey) ?? '';
  }

  @override
  Future<Wallet> getWallet() async {
    final driverId = await _getDriverId();
    if (driverId.isEmpty) {
      throw Exception('Missing driverId');
    }

    try {
      return await _remoteDataSource.getWalletApi(driverId);
    } catch (_) {
      return Wallet(
        userId: driverId,
        role: 'DRIVER',
        balance: 0,
        totalEarned: 0,
        totalWithdrawn: 0,
        pendingBalance: 0,
      );
    }
  }

  @override
  Future<List<Transaction>> getTransactions(int page, int size) async {
    final driverId = await _getDriverId();
    if (driverId.isEmpty) {
      return [];
    }

    try {
      final all = await _remoteDataSource.getTransactionsApi(driverId);
      final start = page * size;
      if (start >= all.length) return [];
      final end = (start + size).clamp(0, all.length);
      return all.sublist(start, end);
    } catch (_) {
      return [];
    }
  }
}
