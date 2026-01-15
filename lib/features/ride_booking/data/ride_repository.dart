import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class RideRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  Future<String?> createRideRequest({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> dropoff,
    required String vehicleType,
    required double price,
  }) async {
    try {
      final uid = _auth.currentUser!.uid;
      final docRef = _firestore.collection('rides').doc();
      
      await docRef.set({
        'riderId': uid,
        'status': 'requested', // requested, accepted, picked_up, completed, cancelled
        'pickup': pickup, // {lat, lng, address}
        'dropoff': dropoff,
        'vehicleType': vehicleType,
        'price': price,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return docRef.id;
    } catch (e) {
      _logger.e("Create Ride Error: $e");
      return null;
    }
  }

  Stream<DocumentSnapshot> streamRide(String rideId) {
    return _firestore.collection('rides').doc(rideId).snapshots();
  }

  // Driver Methods
  Stream<QuerySnapshot> getAvailableRides() {
    // Basic query: active status. In PROD, use GeoFlutterFire for radius query
    return _firestore.collection('rides')
        .where('status', isEqualTo: 'requested')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> acceptRide(String rideId) async {
    final uid = _auth.currentUser!.uid;
    await _firestore.collection('rides').doc(rideId).update({
      'driverId': uid,
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }
}
