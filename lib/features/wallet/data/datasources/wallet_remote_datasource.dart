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
    log('GET /drivers/wallet');
    try {
      final response = await requestGet('/drivers/wallet');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'] ?? decoded;
          return WalletModel.fromJson(data as Map<String, dynamic>);
        }
        throw const ServerFailure('Invalid wallet response format');
      }
      throw mapFailure(response, '/drivers/wallet');
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to fetch wallet');
    }
  }

  Future<List<TransactionModel>> getTransactionsApi(String driverId) async {
    log('GET /drivers/transactions');
    try {
      final response = await requestGet(
        '/drivers/transactions',
        queryParams: {'page': '0', 'size': '50'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] ?? decoded : decoded;
        final list = data is List ? data : [];
        return list.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw mapFailure(response, '/drivers/transactions');
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to fetch transactions');
    }
  }

  Future<void> withdrawApi(String driverId, double amount) async {
    log('POST /drivers/withdraw - amount=$amount');
    try {
      final response = await requestPost(
        '/drivers/withdraw',
        body: {'amount': amount},
      );

      if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
        throw mapFailure(response, '/drivers/withdraw');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      log('Exception: $e');
      throw const ServerFailure('Failed to withdraw');
    }
  }
}
