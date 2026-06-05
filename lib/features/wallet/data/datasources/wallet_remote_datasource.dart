import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/errors/failures.dart';
import '../../../../core/network/base_remote_datasource.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

class WalletRemoteDataSource extends BaseRemoteDataSource {
  WalletRemoteDataSource({
    http.Client? httpClient,
    String? baseApiUrl,
    required Future<String> Function() getToken,
    required FlutterSecureStorage secureStorage,
  }) : super(
          httpClient: httpClient,
          baseApiUrl: baseApiUrl,
          getToken: getToken,
          secureStorage: secureStorage,
        );

  Future<WalletModel> getWalletApi(String driverId) async {
    log('GET /wallet/$driverId');
    try {
      final response = await requestGet('/wallet/$driverId');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return WalletModel.fromJson(decoded as Map<String, dynamic>);
      }
      throw mapFailure(response, '/wallet/$driverId');
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to fetch wallet');
    }
  }

  Future<List<TransactionModel>> getTransactionsApi(String driverId) async {
    log('GET /wallet/$driverId/transactions');
    try {
      final response = await requestGet('/wallet/$driverId/transactions');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded is List ? decoded : (decoded['data'] ?? []);
        return list.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw mapFailure(response, '/wallet/$driverId/transactions');
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to fetch transactions');
    }
  }

  Future<void> withdrawApi(String driverId, double amount) async {
    log('POST /wallet/$driverId/withdraw - amount=$amount');
    try {
      final response = await requestPost(
        '/wallet/$driverId/withdraw',
        body: {'amount': amount},
      );

      if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
        throw mapFailure(response, '/wallet/$driverId/withdraw');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to withdraw');
    }
  }
}
