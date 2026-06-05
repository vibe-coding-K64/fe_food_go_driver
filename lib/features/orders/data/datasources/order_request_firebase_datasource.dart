import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order_request_model.dart';

class OrderRequestFirebaseDataSource {
  final FirebaseFirestore _firestore;

  OrderRequestFirebaseDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  void log(String message) {
    debugPrint('[OrderRequestFirebaseDataSource] $message');
  }

  Stream<List<OrderRequestModel>> watchOrderRequests(String driverId) {
    log('watchOrderRequests - driverId: $driverId');

    return _firestore
        .collection('order_requests')
        .doc(driverId)
        .collection('requests')
        .where('status', isEqualTo: 0)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
      log('watchOrderRequests - received ${snap.docChanges.length} changes, docs: ${snap.docs.length}');
      return snap.docs.map((doc) {
        return OrderRequestModel.fromFirestore(doc.id, _fromFirestore(doc));
      }).toList();
    });
  }

  Future<void> deleteOrderRequest(String driverId, String requestId) async {
    log('deleteOrderRequest - driverId: $driverId, requestId: $requestId');
    try {
      await _firestore
          .collection('order_requests')
          .doc(driverId)
          .collection('requests')
          .doc(requestId)
          .delete();
      log('deleteOrderRequest - success');
    } catch (e) {
      log('deleteOrderRequest - error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return {'id': doc.id};
    return {
      ...data,
      'id': doc.id,
      'createdAt': _convertTimestamp(data['createdAt']),
      'updatedAt': _convertTimestamp(data['updatedAt']),
    };
  }

  dynamic _convertTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    return value;
  }
}
