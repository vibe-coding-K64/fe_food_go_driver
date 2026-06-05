import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final String userId;
  final String role;
  final double balance;
  final double totalEarned;
  final double totalWithdrawn;
  final double pendingBalance;

  const Wallet({
    required this.userId,
    required this.role,
    required this.balance,
    required this.totalEarned,
    required this.totalWithdrawn,
    required this.pendingBalance,
  });

  @override
  List<Object?> get props => [userId, role, balance, totalEarned, totalWithdrawn, pendingBalance];
}
