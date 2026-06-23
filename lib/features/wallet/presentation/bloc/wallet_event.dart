import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class LoadWallet extends WalletEvent {
  const LoadWallet();
}

class LoadWalletTransactionsOnly extends WalletEvent {
  final String filter;

  const LoadWalletTransactionsOnly({this.filter = 'all'});

  @override
  List<Object?> get props => [filter];
}

class LoadTransactions extends WalletEvent {
  final int page;
  final int size;

  const LoadTransactions({this.page = 0, this.size = 20});

  @override
  List<Object?> get props => [page, size];
}

class WithdrawRequested extends WalletEvent {
  final double amount;

  const WithdrawRequested(this.amount);

  @override
  List<Object?> get props => [amount];
}

class FilterTransactions extends WalletEvent {
  final String filter;

  const FilterTransactions(this.filter);

  @override
  List<Object?> get props => [filter];
}
