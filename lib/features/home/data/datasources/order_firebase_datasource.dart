import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../orders/data/models/order_model.dart';

class OrderFirebaseDataSource {
  OrderFirebaseDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
        .handleError((error, stack) {
          _log('watchAvailableOrders stream error: $error');
        })
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
        .handleError((error, stack) {
          _log('watchDriverActiveOrders stream error: $error');
        })
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
        .where('status', whereIn: [1, 2])
        .where('deletedAt', isNull: true)
        .snapshots()
        .handleError((error, stack) {
          _log('watchSingleActiveOrder stream error: $error');
        })
        .map(
          (snap) => snap.docs.isEmpty
              ? null
              : OrderModel.fromJson(_fromFirestore(snap.docs.first)),
        );
  }

  Stream<List<OrderModel>> watchDriverRecentOrders(
    String driverId, {
    int limit = 20,
  }) {
    _log('watchDriverRecentOrders($driverId, limit=$limit)');

    return _firestore
        .collection('orders')
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: [1, 2, 3, 4])
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((error, stack) {
          _log('watchDriverRecentOrders stream error: $error');
        })
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
      'pickedUpAt': data['pickedUpAt'] is Timestamp
          ? (data['pickedUpAt'] as Timestamp).toDate().toIso8601String()
          : data['pickedUpAt'],
      'arrivedAtStoreAt': data['arrivedAtStoreAt'] is Timestamp
          ? (data['arrivedAtStoreAt'] as Timestamp).toDate().toIso8601String()
          : data['arrivedAtStoreAt'],
      'deliveredAt': data['deliveredAt'] is Timestamp
          ? (data['deliveredAt'] as Timestamp).toDate().toIso8601String()
          : data['deliveredAt'],
    };
  }
}
