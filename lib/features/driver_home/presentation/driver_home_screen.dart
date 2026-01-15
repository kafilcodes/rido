import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../ride_booking/data/ride_repository.dart';

final rideRepoProvider = Provider((ref) => RideRepository());

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  bool _isOnline = false;

  void _toggleOnline(bool value) async {
    setState(() => _isOnline = value);
    // Update user status in Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isOnline': value,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Dashboard"),
        actions: [
          Row(
            children: [
              Text(_isOnline ? "Online" : "Offline", style: TextStyle(fontWeight: FontWeight.bold, color: _isOnline ? Colors.green : Colors.grey)),
              Switch(value: _isOnline, onChanged: _toggleOnline),
            ],
          )
        ],
      ),
      body: _isOnline ? _buildRideList() : _buildOfflineView(),
    );
  }

  Widget _buildOfflineView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          SizedBox(height: 2.h),
          Text("You are offline", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          const Text("Go online to receive ride requests."),
        ],
      ),
    );
  }

  Widget _buildRideList() {
    final ridesStream = ref.watch(rideRepoProvider).getAvailableRides();
    
    return StreamBuilder<QuerySnapshot>(
      stream: ridesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error loading rides"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("Measuring roads... No rides yet."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("New Ride Request", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                        Text("₹${data['price']}", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.my_location, color: Colors.green),
                      title: const Text("Pickup"),
                      subtitle: Text(data['pickup']['address'] ?? "Unknown"),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on, color: Colors.red),
                      title: const Text("Dropoff"),
                      subtitle: Text(data['dropoff']['address'] ?? "Unknown"),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                           ref.read(rideRepoProvider).acceptRide(id);
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ride Accepted!")));
                           // Navigate to Navigation Screen (Not implemented yet)
                        }, 
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                        child: const Text("Accept Ride"),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
