import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final http.Client _httpClient;

  WalletBloc({
    required WalletRepository walletRepository,
    http.Client? httpClient,
  })  : _httpClient = httpClient ?? http.Client(),
        super(const WalletState()) {
    on<LoadWallet>(_onLoadWallet);
    on<LoadWalletTransactionsOnly>(_onLoadWalletTransactionsOnly);
    on<LoadTransactions>(_onLoadTransactions);
    on<WithdrawRequested>(_onWithdrawRequested);
    on<FilterTransactions>(_onFilterTransactions);
  }

  Future<void> _onLoadWallet(LoadWallet event, Emitter<WalletState> emit) async {
    emit(state.copyWith(loadStatus: WalletLoadStatus.loaded));
  }

  Future<void> _onLoadWalletTransactionsOnly(
    LoadWalletTransactionsOnly event,
    Emitter<WalletState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: WalletLoadStatus.loaded,
        transactions: const [],
        currentPage: 0,
        hasMoreTransactions: false,
        isLoadingMore: false,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> _onLoadTransactions(
      LoadTransactions event, Emitter<WalletState> emit) async {
    emit(
      state.copyWith(
        loadStatus: WalletLoadStatus.loaded,
        transactions: const [],
        currentPage: event.page,
        hasMoreTransactions: false,
        isLoadingMore: false,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> _onFilterTransactions(
      FilterTransactions event, Emitter<WalletState> emit) async {
    emit(state.copyWith(
      transactionFilter: event.filter,
      transactions: const [],
      currentPage: 0,
      hasMoreTransactions: false,
      isLoadingMore: false,
      clearErrorMessage: true,
    ));
  }

  Future<void> _onWithdrawRequested(
      WithdrawRequested event, Emitter<WalletState> emit) async {
    emit(state.copyWith(withdrawStatus: WithdrawStatus.loading));
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(state.copyWith(
          withdrawStatus: WithdrawStatus.error,
          withdrawErrorMessage: 'Not authenticated',
        ));
        return;
      }

      final token = await user.getIdToken();
      final response = await _httpClient.post(
        Uri.parse('${AppConstants.baseApiUrl}/drivers/withdraw'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'amount': event.amount}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        emit(state.copyWith(withdrawStatus: WithdrawStatus.success));
        add(const LoadWalletTransactionsOnly());
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        emit(state.copyWith(
          withdrawStatus: WithdrawStatus.error,
          withdrawErrorMessage: body['message'] ?? 'Withdrawal failed',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        withdrawStatus: WithdrawStatus.error,
        withdrawErrorMessage: e.toString(),
      ));
    }
  }
}
