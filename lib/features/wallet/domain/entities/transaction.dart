import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String userId;
  final String type;
  final double amount;
  final double fee;
  final double netAmount;
  final DateTime createdAt;
  final String? description;
  final String status;
  final String? orderId;

  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.fee = 0.0,
    this.netAmount = 0.0,
    this.description,
    this.status = 'COMPLETED',
    this.orderId,
  });

  @override
  List<Object?> get props =>
      [id, userId, type, amount, fee, netAmount, createdAt, description, status, orderId];
}
