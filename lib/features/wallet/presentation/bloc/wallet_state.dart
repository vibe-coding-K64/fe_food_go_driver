import 'package:equatable/equatable.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/transaction.dart';

enum WalletLoadStatus { initial, loading, loaded, error }

enum WithdrawStatus { initial, loading, success, error }

class WalletState extends Equatable {
  final WalletLoadStatus loadStatus;
  final WithdrawStatus withdrawStatus;
  final Wallet? wallet;
  final List<Transaction> transactions;
  final String? errorMessage;
  final String? withdrawErrorMessage;
  final String transactionFilter;
  final int currentPage;
  final bool hasMoreTransactions;
  final bool isLoadingMore;

  const WalletState({
    this.loadStatus = WalletLoadStatus.initial,
    this.withdrawStatus = WithdrawStatus.initial,
    this.wallet,
    this.transactions = const [],
    this.errorMessage,
    this.withdrawErrorMessage,
    this.transactionFilter = 'all',
    this.currentPage = 0,
    this.hasMoreTransactions = true,
    this.isLoadingMore = false,
  });

  WalletState copyWith({
    WalletLoadStatus? loadStatus,
    WithdrawStatus? withdrawStatus,
    Wallet? wallet,
    List<Transaction>? transactions,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? withdrawErrorMessage,
    bool clearWithdrawErrorMessage = false,
    String? transactionFilter,
    int? currentPage,
    bool? hasMoreTransactions,
    bool? isLoadingMore,
  }) {
    return WalletState(
      loadStatus: loadStatus ?? this.loadStatus,
      withdrawStatus: withdrawStatus ?? this.withdrawStatus,
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      withdrawErrorMessage: clearWithdrawErrorMessage ? null : (withdrawErrorMessage ?? this.withdrawErrorMessage),
      transactionFilter: transactionFilter ?? this.transactionFilter,
      currentPage: currentPage ?? this.currentPage,
      hasMoreTransactions: hasMoreTransactions ?? this.hasMoreTransactions,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        loadStatus,
        withdrawStatus,
        wallet,
        transactions,
        errorMessage,
        withdrawErrorMessage,
        transactionFilter,
        currentPage,
        hasMoreTransactions,
        isLoadingMore,
      ];
}
