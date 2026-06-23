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
    super.fee,
    super.netAmount,
    super.orderId,
  });

  static String _mapType(dynamic type) {
    if (type == null) return 'DELIVERY_INCOME';
    // Backend trả về Integer: 2=delivery_income, 3=withdrawal, 4=refund, 5=COD_DEBIT
    final String strVal = type.toString().trim();
    final int? intVal = int.tryParse(strVal);
    final int t = intVal ?? 1;
    switch (t) {
      case 1: return 'ORDER_PAYMENT';
      case 2: return 'DELIVERY_INCOME';
      case 3: return 'WITHDRAWAL';
      case 4: return 'REFUND';
      case 5: return 'COD_DEBIT';
      default: return 'DELIVERY_INCOME';
    }
  }

  static String _mapStatus(dynamic status) {
    if (status == null) return 'COMPLETED';
    final String strVal = status.toString().trim();
    final int? intVal = int.tryParse(strVal);
    final int s = intVal ?? 1;
    switch (s) {
      case 0: return 'PENDING';
      case 1: return 'COMPLETED';
      case 2: return 'FAILED';
      default: return 'COMPLETED';
    }
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final typeVal = json['type'];
    final statusVal = json['status'];
    return TransactionModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      type: _mapType(typeVal),
      amount: (json['amount'] ?? 0.0).toDouble(),
      fee: (json['fee'] ?? 0.0).toDouble(),
      netAmount: (json['netAmount'] ?? json['amount'] ?? 0.0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      description: json['description']?.toString() ?? json['note']?.toString(),
      status: _mapStatus(statusVal),
      orderId: json['orderId']?.toString() ?? json['order_id']?.toString(),
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
