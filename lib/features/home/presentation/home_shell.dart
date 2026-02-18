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
import 'widgets/home_tab.dart';

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

  // State for Vehicle Selection
  String? _preSelectedVehicle;

  // ... (existing methods)

  void _onVehicleSelected(String vehicle) {
    setState(() {
      _preSelectedVehicle = vehicle;
    });
    // Just update state, let user tap "Where to?" to proceed.
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
        preSelectedVehicle: _preSelectedVehicle, // Pass the vehicle
        onConfirm: () {
          Navigator.pop(context); 
          _showFindingDriverSheet();
        },
      ),
    ).whenComplete(() {
      setState(() {
         // Reset pre-selection after flow
         // _preSelectedVehicle = null; 
      });
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

  void _openSidebar() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return material.Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.colorScheme.background, // Explicitly set background
      drawer: material.Drawer(
        width: 75.w,
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
                  // HOME TAB (No Map)
                  HomeTab(
                    onMenuTap: _openSidebar,
                    onNotificationTap: () => setState(() => _currentIndex = 3), // Navigate to Notifs
                    onSearchTap: _onSearchTap,
                    onVehicleSelected: _onVehicleSelected,
                  ),
                  const ActivityScreen(), 
                  const AccountScreen(),
                  NotificationScreen(),
                ],
              ),
              
              // Blur Overlay when booking/sheet is active
              if (_isBooking)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        color: material.Colors.black.withOpacity(0.1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
    );
  }
  
  // Deleted _buildMapTab as it is no longer used.
}
