import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../wallet/data/models/wallet_model.dart';
import '../../../wallet/data/models/transaction_model.dart';

class WalletFirebaseDataSource {
  final FirebaseFirestore _firestore;

  WalletFirebaseDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  void _log(String message) {
    debugPrint('[WalletFirebaseDataSource] $message');
  }

  Stream<WalletModel?> watchWallet(String driverId) {
    _log('watchWallet($driverId)');

    return _firestore.collection('wallets').doc(driverId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return WalletModel(
          userId: driverId,
          role: 'DRIVER',
          balance: 0,
          totalEarned: 0,
          totalWithdrawn: 0,
          pendingBalance: 0,
        );
      }
      return WalletModel.fromJson({...doc.data()!, 'userId': driverId});
    });
  }

  Stream<List<TransactionModel>> watchTransactions(String driverId, {int limit = 50}) {
    _log('watchTransactions($driverId, limit=$limit)');

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return TransactionModel.fromJson({
                ...data,
                'id': doc.id,
                'createdAt': data['createdAt'] is Timestamp
                    ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
                    : data['createdAt'],
              });
            }).toList());
  }
}
