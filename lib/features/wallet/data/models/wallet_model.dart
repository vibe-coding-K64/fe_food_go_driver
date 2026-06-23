import '../../domain/entities/wallet.dart';

class WalletModel extends Wallet {
  const WalletModel({
    required super.userId,
    required super.role,
    required super.balance,
    required super.totalEarned,
    required super.totalWithdrawn,
    required super.pendingBalance,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'DRIVER',
      balance: (json['balance'] ?? 0.0).toDouble(),
      totalEarned: (json['totalEarned'] ?? json['total_earned'] ?? 0.0).toDouble(),
      totalWithdrawn: (json['totalWithdrawn'] ?? json['total_withdrawn'] ?? 0.0).toDouble(),
      pendingBalance: (json['pendingBalance'] ?? json['pending_balance'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role,
      'balance': balance,
      'totalEarned': totalEarned,
      'totalWithdrawn': totalWithdrawn,
      'pendingBalance': pendingBalance,
    };
  }
}
