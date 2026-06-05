import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository _walletRepository;

  WalletBloc({
    required WalletRepository walletRepository,
  })  : _walletRepository = walletRepository,
        super(const WalletState()) {
    on<LoadWallet>(_onLoadWallet);
    on<LoadWalletTransactionsOnly>(_onLoadWalletTransactionsOnly);
    on<LoadTransactions>(_onLoadTransactions);
    on<WithdrawRequested>(_onWithdrawRequested);
    on<FilterTransactions>(_onFilterTransactions);
  }

  Future<void> _onLoadWallet(LoadWallet event, Emitter<WalletState> emit) async {
    emit(state.copyWith(loadStatus: WalletLoadStatus.loading));
    try {
      final wallet = await _walletRepository.getWallet();
      emit(state.copyWith(
        loadStatus: WalletLoadStatus.loaded,
        wallet: wallet,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadStatus: WalletLoadStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadWalletTransactionsOnly(
    LoadWalletTransactionsOnly event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(
      loadStatus: WalletLoadStatus.loading,
      transactions: const [],
      currentPage: 0,
      hasMoreTransactions: false,
      isLoadingMore: false,
      transactionFilter: event.filter,
      clearErrorMessage: true,
    ));
    try {
      final wallet = await _walletRepository.getWallet();
      final transactions = await _walletRepository.getTransactions(0, 50);
      final filtered = _applyFilter(transactions, event.filter);
      emit(state.copyWith(
        loadStatus: WalletLoadStatus.loaded,
        wallet: wallet,
        transactions: filtered,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadStatus: WalletLoadStatus.error,
        errorMessage: e.toString(),
        transactions: const [],
      ));
    }
  }

  List<Transaction> _applyFilter(List<Transaction> transactions, String filter) {
    switch (filter) {
      case 'earning':
        return transactions.where((t) => t.type == 'DELIVERY_INCOME').toList();
      case 'withdrawal':
        return transactions.where((t) => t.type == 'WITHDRAWAL').toList();
      case 'refund':
        return transactions.where((t) => t.type == 'REFUND' || t.type == 'COD_DEBIT').toList();
      default:
        return transactions;
    }
  }

  Future<void> _onLoadTransactions(
      LoadTransactions event, Emitter<WalletState> emit) async {
    emit(state.copyWith(
      loadStatus: WalletLoadStatus.loading,
      transactions: const [],
      currentPage: event.page,
      hasMoreTransactions: false,
      isLoadingMore: false,
      clearErrorMessage: true,
    ));
    try {
      final wallet = await _walletRepository.getWallet();
      final transactions = await _walletRepository.getTransactions(event.page, event.size);
      final filtered = _applyFilter(transactions, state.transactionFilter);
      emit(state.copyWith(
        loadStatus: WalletLoadStatus.loaded,
        wallet: wallet,
        transactions: filtered,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadStatus: WalletLoadStatus.error,
        errorMessage: e.toString(),
        transactions: const [],
      ));
    }
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
    emit(state.copyWith(loadStatus: WalletLoadStatus.loading));
    try {
      final transactions = await _walletRepository.getTransactions(0, 50);
      final filtered = _applyFilter(transactions, event.filter);
      emit(state.copyWith(
        loadStatus: WalletLoadStatus.loaded,
        transactions: filtered,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadStatus: WalletLoadStatus.error,
        errorMessage: e.toString(),
        transactions: const [],
      ));
    }
  }

  Future<void> _onWithdrawRequested(
      WithdrawRequested event, Emitter<WalletState> emit) async {
    emit(state.copyWith(withdrawStatus: WithdrawStatus.loading));
    try {
      await _walletRepository.withdraw(event.amount);
      emit(state.copyWith(withdrawStatus: WithdrawStatus.success));
      add(LoadWalletTransactionsOnly(filter: state.transactionFilter));
    } catch (e) {
      emit(state.copyWith(
        withdrawStatus: WithdrawStatus.error,
        withdrawErrorMessage: e.toString(),
      ));
    }
  }
}
