import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../../../driver/data/models/driver_profile_model.dart';
import '../../../driver/data/models/driver_location_model.dart';

class DriverFirebaseDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _realtimeDb;

  DriverFirebaseDataSource({
    FirebaseFirestore? firestore,
    FirebaseDatabase? realtimeDb,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _realtimeDb = realtimeDb ?? FirebaseDatabase.instance;

  void _log(String message) {
    debugPrint('[DriverFirebaseDataSource] $message');
  }

  Stream<DriverProfileModel?> watchDriverProfile(String driverId) {
    _log('watchDriverProfile($driverId)');

    return _firestore.collection('users').doc(driverId).snapshots().asyncMap((userDoc) async {
      if (!userDoc.exists || userDoc.data() == null) {
        _log('User doc not found for $driverId');
        return null;
      }

      final profileDoc = await _firestore.collection('driver_profiles').doc(driverId).get();

      final userData = userDoc.data()!;
      final profileData = profileDoc.exists ? profileDoc.data() ?? {} : {};

      final combined = <String, dynamic>{
        ...userData,
        ...profileData,
        'id': driverId,
      };

      return DriverProfileModel.fromJson(combined);
    });
  }

  Stream<DriverLocationModel?> watchDriverLocation(String driverId) {
    _log('watchDriverLocation($driverId)');

    return _realtimeDb.ref().child('active_drivers').child(driverId).onValue.map((event) {
      if (event.snapshot.value == null) return null;
      final data = event.snapshot.value as Map<Object?, Object?>;
      return DriverLocationModel.fromJson(Map<String, dynamic>.from(data));
    });
  }

  Stream<Map<String, dynamic>> watchDriverStats(String driverId) {
    _log('watchDriverStats($driverId)');

    return _firestore
        .collection('driver_profiles')
        .doc(driverId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        return <String, dynamic>{
          'totalTrips': 0,
          'ordersToday': 0,
          'earningsToday': 0.0,
          'balance': 0.0,
        };
      }
      final data = doc.data()!;
      return <String, dynamic>{
        'totalTrips': data['totalTrips'] ?? data['total_trips'] ?? 0,
        'totalOrders': data['totalTrips'] ?? data['total_trips'] ?? 0,
        'ordersToday': data['ordersToday'] ?? data['orders_today'] ?? 0,
        'earningsToday': data['earningsToday'] ?? data['earnings_today'] ?? 0.0,
        'balance': data['balance'] ?? 0.0,
        'rating': data['rating']?.toDouble() ?? 0.0,
      };
    });
  }
}
