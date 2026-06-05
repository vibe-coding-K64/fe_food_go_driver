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
    final query = _firestore
        .collection('order_requests')
        .doc(driverId)
        .collection('requests')
        .orderBy('createdAt', descending: true);

    log(
      'watchOrderRequests subscribe - path=order_requests/$driverId/requests orderBy=createdAt desc',
    );

    return query.snapshots().map((snapshot) {
      log(
        'watchOrderRequests snapshot - driverId=$driverId docs=${snapshot.docs.length}',
      );

      final requests = snapshot.docs.map((doc) {
        final data = doc.data();
        log(
          'watchOrderRequests doc - requestId=${doc.id}, orderId=${data['orderId']}, driverId=${data['driverId']}, status=${data['status']}, createdAt=${data['createdAt']}',
        );
        return OrderRequestModel.fromFirestore(doc.id, data);
      }).toList();

      log(
        'watchOrderRequests mapped - requestIds=${requests.map((request) => request.id).toList()}',
      );

      return requests;
    });
  }
}
