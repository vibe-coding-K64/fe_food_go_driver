import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.amount,
    required super.createdAt,
    super.description,
    super.status,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'EARNING',
      amount: (json['amount'] ?? 0.0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      description: json['description']?.toString() ?? json['note']?.toString(),
      status: json['status']?.toString() ?? 'COMPLETED',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'status': status,
    };
  }
}
