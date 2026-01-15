import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sizer/sizer.dart';
import '../../activity/presentation/activity_screen.dart';
import '../../account/presentation/account_screen.dart';
import '../../ride_booking/presentation/ride_estimation_sheet.dart';
import '../../ride_booking/presentation/finding_driver_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(20.5937, 78.9629); // Default to India
  bool _isLoadingMap = true;

  // State for Booking Flow
  String? _destination;
  bool _isBooking = false;
  Map<String, dynamic>? _rideData;

  // User Data
  User? _currentUser;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _determinePosition();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userData = doc.data();
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _isLoadingMap = false;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_initialPosition));
    }
  }

  void _onSearchTap() async {
    final result = await context.push('/destination-search');
    if (result != null && result is Map) {
      setState(() {
        _destination = result['destination'];
        _rideData = result as Map<String, dynamic>;
        _isBooking = true;
      });
      _showEstimationSheet();
    }
  }

  void _showEstimationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RideEstimationSheet(
        destination: _destination!, 
        onConfirm: () {
          Navigator.pop(context); // Close estimation
          _showFindingDriverSheet();
        },
      ),
    ).whenComplete(() {
      // Ensure specific state logic depending on if we moved to next step or cancelled
      // However, since onConfirm pops then shows next sheet, we must discriminate.
      // But simpler: if no driver sheet shown, we reset. 
      // Actually, standard way: if user dismissed, reset. 
      // But finding driver sheet is modal too.
      // Let's rely on _isBooking reset only if we truly cancelled.
      // For now, user wants "don't hide where to ui component never" if closed.
      // So if this sheet closes, we should reset _isBooking ONLY IF we didn't proceed.
      // But for simplicity, let's reset _isBooking = false when the flow ends or is cancelled.
      // If we proceed to Finding Driver, that's a new sheet.
      // Wait, standard bottom sheet flow: one replaces another.
      // If finding driver is shown, _isBooking is still true?
      // Let's set _isBooking = false explicitly if we are just dismissing the estimation.
      // But how do we know if we proceeded? 
      // Refactor: make onConfirm set a flag or handle transition within the sheet logic.
      // EASIEST: Just set _isBooking = false here. If finding driver opens, it blocks interaction anyway map is visible but finding driver sheet is up.
      // Actually, if Finding Driver is up, we probably want _isBooking true/false?
      // User said: "if you accident closed the book popup component... home screen don't have any ui only map showing".
      // This means when sheet is closed, _isBooking must be false.
      if (!_isFindingDriverVisible) {
         setState(() {
           _isBooking = false;
         });
      }
    });
  }

  bool _isFindingDriverVisible = false;

  void _showFindingDriverSheet() {
    _isFindingDriverVisible = true;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => const FindingDriverScreen(),
    ).whenComplete(() {
      _isFindingDriverVisible = false;
      setState(() {
        _isBooking = false;
      });
    });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawer: _buildDrawer(context, isDark),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              _buildMapTab(),
              ActivityScreen(onBack: () => setState(() => _currentIndex = 0)), 
              AccountScreen(onBack: () => setState(() => _currentIndex = 0)),
            ],
          ),
          
          if (_currentIndex == 0 && !_isBooking) // Hide Menu button when booking? Or maybe keep it? User didn't specify. Keeping hidden during booking is standard.
          Positioned(
            top: 6.h,
            left: 5.w,
            child: CircleAvatar(
              backgroundColor: isDark ? Colors.black54 : Colors.white,
              child: IconButton(
                icon: const Icon(Icons.menu),
                color: isDark ? Colors.white : Colors.black,
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    final backgroundColor = (isDark ? Colors.black : Colors.white).withValues(alpha: 0.9);
    final inactiveColor = isDark ? Colors.white : Colors.black;
    
    // Parse user data
    final name = _userData?['name'] as String? ?? _currentUser?.displayName ?? "User Name";
    final phone = _userData?['phone'] as String? ?? _currentUser?.phoneNumber ?? "";
    final photoUrl = _userData?['profile_pic'] as String?;

    return Drawer(
      backgroundColor: backgroundColor,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.grey[200],
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: (photoUrl == null || photoUrl.isEmpty) 
                    ? const Icon(Icons.person, color: Colors.grey, size: 40) 
                    : null,
              ),
              accountName: Text(name, style: TextStyle(color: inactiveColor, fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text(phone, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
            ),
            _buildDrawerItem(context, "Home", Icons.home_outlined, 0, isDark),
            _buildDrawerItem(context, "Activity", Icons.history, 1, isDark),
            _buildDrawerItem(context, "Account", Icons.person_outline, 2, isDark),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                 Navigator.pop(context);
                 FirebaseAuth.instance.signOut();
                 context.go('/auth');
              },
            ),
            SizedBox(height: 5.h),
          ],
        ),
      ),
    );
  }



  Widget _buildMapTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Greeting Logic
    final hour = DateTime.now().hour;
    String greeting = "Good Morning";
    if (hour >= 12 && hour < 17) greeting = "Good Afternoon";
    if (hour >= 17) greeting = "Good Evening";
    
    // Name Logic
    final fullName = _userData?['name'] as String? ?? _currentUser?.displayName ?? "User";
    final firstName = fullName.split(' ').first;

    // Minimal Dark Mode Style
    const String darkMapStyle = '''[{"elementType":"geometry","stylers":[{"color":"#242f3e"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},{"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263c3f"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6b9a76"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},{"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#746855"}]},{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f2835"}]},{"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"}]},{"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},{"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}]''';

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 14),
          onMapCreated: (controller) {
            _mapController = controller;
            if (isDark) {
               controller.setMapStyle(darkMapStyle);
            }
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false, // We use custom button
          zoomControlsEnabled: false,
          compassEnabled: false,
        ),
        
        // Layout for bottom sheet and FAB
        if (!_isBooking) ...[
          // Recenter Button
          Positioned(
            bottom: 30.h, 
            right: 5.w,
            child: FloatingActionButton(
              heroTag: "recenter_btn",
              mini: true,
              backgroundColor: Theme.of(context).cardColor,
              onPressed: _determinePosition,
              child: const Icon(Icons.my_location, color: Colors.red),
            ),
          ),
          
          DraggableScrollableSheet(
            initialChildSize: 0.25, 
            minChildSize: 0.15,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                   boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5)),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                  children: [
                     Center(
                      child: Container(
                        width: 40, 
                        height: 5, 
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))
                      )
                    ),
                    SizedBox(height: 2.h),
                    Text("$greeting, $firstName", style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 2.h),
                    InkWell(
                      onTap: _onSearchTap,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, size: 28, color: Theme.of(context).iconTheme.color),
                            const SizedBox(width: 16),
                            Text(
                              "Where to?",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Container(
                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                               decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
                               child: Text("Now", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              );
            },
          ),
        ]
      ],
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, int index, bool isDark) {
    final isSelected = _currentIndex == index;
    final inactiveColor = isDark ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: isSelected 
          ? const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]) 
          : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon, 
          color: isSelected ? Colors.white : inactiveColor,
        ),
        title: Text(
          title, 
          style: TextStyle(
            color: isSelected ? Colors.white : inactiveColor, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          )
        ),
        onTap: () {
          setState(() => _currentIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }

  // Helper widget can remain if needed, but unused for now
  Widget _buildRecentLocation(String title, String subtitle) {
     // ... implementation ...
     return const SizedBox.shrink(); 
  }
}
