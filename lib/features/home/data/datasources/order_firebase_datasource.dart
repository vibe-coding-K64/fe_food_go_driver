import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../orders/data/models/order_model.dart';

class OrderFirebaseDataSource {
  final FirebaseFirestore _firestore;

  OrderFirebaseDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  void _log(String message) {
    debugPrint('[OrderFirebaseDataSource] $message');
  }

  Stream<List<OrderModel>> watchAvailableOrders() {
    _log('watchAvailableOrders()');

    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 1)
        .where('driverId', isNull: true)
        .where('deletedAt', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => OrderModel.fromJson(_fromFirestore(doc)))
              .toList(),
        );
  }

  Stream<List<OrderModel>> watchDriverActiveOrders(String driverId) {
    _log('watchDriverActiveOrders($driverId)');

    return _firestore
        .collection('orders')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 2)
        .where('deletedAt', isNull: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => OrderModel.fromJson(_fromFirestore(doc)))
              .toList(),
        );
  }

  Stream<OrderModel?> watchSingleActiveOrder(String driverId) {
    _log('watchSingleActiveOrder($driverId)');

    return _firestore
        .collection('orders')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 2)
        .where('deletedAt', isNull: true)
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          return OrderModel.fromJson(_fromFirestore(snap.docs.first));
        });
  }

  Stream<List<OrderModel>> watchDriverRecentOrders(
    String driverId, {
    int limit = 20,
  }) {
    _log('watchDriverRecentOrders($driverId, limit=$limit)');

    return _firestore
        .collection('orders')
        .where('driverId', isEqualTo: driverId)
        .where('deletedAt', isNull: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => OrderModel.fromJson(_fromFirestore(doc)))
              .toList(),
        );
  }

  Map<String, dynamic> _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return {'id': doc.id};

    return {
      ...data,
      'id': doc.id,
      'createdAt': data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
          : data['createdAt'],
      'updatedAt': data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate().toIso8601String()
          : data['updatedAt'],
      'deletedAt': data['deletedAt'] is Timestamp
          ? (data['deletedAt'] as Timestamp).toDate().toIso8601String()
          : data['deletedAt'],
    };
  }
}
