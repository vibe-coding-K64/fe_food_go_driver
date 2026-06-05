import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String userId;
  final String type;
  final double amount;
  final DateTime createdAt;
  final String? description;
  final String status;

  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.description,
    this.status = 'COMPLETED',
  });

  @override
  List<Object?> get props =>
      [id, userId, type, amount, createdAt, description, status];
}
