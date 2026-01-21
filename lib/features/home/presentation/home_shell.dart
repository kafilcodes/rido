import 'dart:ui';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart' show Column, Row, SizedBox, Container, Expanded, Spacer, Stack, Positioned, Center, Padding, Align, Icon, IconData, TextStyle, FontWeight, Color, State, StatefulWidget, BuildContext, Widget, MainAxisAlignment, CrossAxisAlignment, EdgeInsets, BorderRadius, BoxDecoration, BoxShadow, Offset, Radius, ImageFilter, NetworkImage, GlobalKey, Key, VoidCallback, Navigator, FloatingActionButton, DraggableScrollableSheet, ListView, InkWell, GestureDetector, IndexedStack; 
import 'package:shadcn_flutter/shadcn_flutter.dart';
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
import '../../notifications/presentation/notifications_screen.dart';
import 'widgets/home_sidebar.dart';
import 'widgets/home_search_card.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(20.5937, 78.9629); 
  bool _isLoadingMap = true;

  // State for Booking Flow
  String? _destination;
  bool _isBooking = false;
  Map<String, dynamic>? _rideData;

  // User Data
  User? _currentUser;
  Map<String, dynamic>? _userData;
  
  // Drawer Key
  final GlobalKey<material.ScaffoldState> _scaffoldKey = GlobalKey<material.ScaffoldState>();

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
    material.showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: material.Colors.transparent,
      builder: (context) => RideEstimationSheet(
        destination: _destination!, 
        onConfirm: () {
          Navigator.pop(context); 
          _showFindingDriverSheet();
        },
      ),
    ).whenComplete(() {
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
    material.showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: material.Colors.transparent,
      builder: (context) => const FindingDriverScreen(),
    ).whenComplete(() {
      _isFindingDriverVisible = false;
      setState(() {
        _isBooking = false;
      });
    });
  }



  @override
  void _openSidebar() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    // Determine greeting
    final hour = DateTime.now().hour;
    String greeting = "Good Morning";
    if (hour >= 12 && hour < 17) greeting = "Good Afternoon";
    if (hour >= 17) greeting = "Good Evening";
    
    final fullName = _userData?['name'] as String? ?? _currentUser?.displayName ?? "User";
    final firstName = fullName.split(' ').first;
    final greetingText = "$greeting, $firstName";

    return material.Scaffold(
      key: _scaffoldKey,
      drawer: material.Drawer(
        width: 75.w, // Sidebar width
        child: HomeSidebar(
          currentUser: _currentUser,
          userData: _userData,
          currentIndex: _currentIndex,
          onIndexChanged: (index) => setState(() => _currentIndex = index),
          onClose: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
           IndexedStack(
            index: _currentIndex,
            children: [
              _buildMapTab(greetingText),
              const ActivityScreen(), 
              const AccountScreen(),
              NotificationScreen(), // New Screen
            ],
          ),
          
          if (_currentIndex == 0 && !_isBooking) 
          Positioned(
            top: 6.h,
            left: 5.w,
            child: GestureDetector(
               onTap: _openSidebar,
               child: Container(
                 width: 48,
                 height: 48,
                 decoration: BoxDecoration(
                   color: Theme.of(context).colorScheme.background,
                   shape: BoxShape.circle,
                   boxShadow: const [BoxShadow(color: material.Colors.black12, blurRadius: 8)],
                 ),
                 child: const Icon(LucideIcons.menu, size: 24),
               ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab(String greeting) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Map Style String ... (omitted for brevity, keep existing)
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
          myLocationButtonEnabled: false, 
          zoomControlsEnabled: false,
          compassEnabled: false,
        ),
        
        if (!_isBooking) ...[
          // Recenter Button
          Positioned(
            bottom: 35.h, 
            right: 5.w,
            child: material.FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.background,
              onPressed: _determinePosition,
              child: const Icon(LucideIcons.locate, color: material.Colors.red, size: 24),
            ),
          ),
          
          // New Search Card
          HomeSearchCard(
             greeting: greeting,
             onTap: _onSearchTap,
          ),
        ]
      ],
    );
  }
}
