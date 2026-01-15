import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:sizer/sizer.dart';
import 'package:uuid/uuid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/places_service.dart';
import 'confirm_location_screen.dart';

class DestinationSearchScreen extends StatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  State<DestinationSearchScreen> createState() => _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final FocusNode _pickupFocus = FocusNode();
  final FocusNode _dropoffFocus = FocusNode();
  
  final PlacesService _placesService = PlacesService();
  final _uuid = const Uuid();
  String _sessionToken = "";
  Timer? _debounce;
  
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = false;
  bool _isPickupFocused = true;
  
  // Confirmed Data
  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  String? _pickupAddress;
  String? _dropoffAddress;
  List<String> _pickupImages = [];

  @override
  void initState() {
    super.initState();
    _sessionToken = _uuid.v4();
    _getCurrentLocationAddress();
    
    _pickupFocus.addListener(() {
      if (_pickupFocus.hasFocus) setState(() => _isPickupFocused = true);
    });
    _dropoffFocus.addListener(() {
      if (_dropoffFocus.hasFocus) setState(() => _isPickupFocused = false);
    });
  }
  
  Future<void> _getCurrentLocationAddress() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      _pickupLatLng = LatLng(position.latitude, position.longitude);
      
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final address = "${p.street}, ${p.subLocality}, ${p.locality}";
        if (mounted) {
          setState(() {
            _pickupAddress = address;
            _pickupController.text = "Current Location ($address)";
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _pickupController.text = "Current Location";
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching current location: $e");
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.isEmpty) {
        setState(() => _predictions = []);
        return;
      }
      
      setState(() => _isLoading = true);
      // Generate new session token if needed or use existing
      final results = await _placesService.searchPlaces(query, _sessionToken);
      if (mounted) {
        setState(() {
          _predictions = results;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _onPredictionSelected(Map<String, dynamic> prediction) async {
    final placeId = prediction['place_id'];
    final description = prediction['description'];
    
    // Get Details (Lat/Lng)
    final details = await _placesService.getPlaceDetails(placeId, _sessionToken);
    if (details != null) {
      final lat = details['geometry']['location']['lat'];
      final lng = details['geometry']['location']['lng'];
      final latLng = LatLng(lat, lng);
      
      if (!mounted) return;

      // Navigate to Map Confirmation
      final result = await Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => ConfirmLocationScreen(
          initialTarget: latLng, 
          initialAddress: description,
          isPickup: _isPickupFocused
        ))
      );
      
      if (result != null && result is Map) {
        _handleConfirmedLocation(result);
      }
    }
    
    // Reset Session Token
    _sessionToken = _uuid.v4();
  }
  
  void _handleConfirmedLocation(Map result) {
    final latLng = result['latLng'] as LatLng;
    final address = result['address'] as String;
    final images = result['images'] as List<String>?;

    setState(() {
      if (_isPickupFocused) {
        _pickupLatLng = latLng;
        _pickupAddress = address;
        _pickupController.text = address;
        _pickupImages = images ?? [];
        // Move focus to dropoff if pickup is done
        FocusScope.of(context).requestFocus(_dropoffFocus);
      } else {
        _dropoffLatLng = latLng;
        _dropoffAddress = address;
        _dropoffController.text = address;
        // If both done, automatically finish? Or wait for user to press Done?
        // User flow usually suggests finishing if both set.
        if (_pickupLatLng != null && _dropoffLatLng != null) {
          _finishSelection();
        }
      }
      _predictions = []; 
    });
  }
  
  void _finishSelection() {
    Navigator.pop(context, {
      'destination': _dropoffAddress,
      'pickup': {
        'lat': _pickupLatLng!.latitude,
        'lng': _pickupLatLng!.longitude,
        'address': _pickupAddress,
        'images': _pickupImages
      },
      'dropoff': {
        'lat': _dropoffLatLng!.latitude,
        'lng': _dropoffLatLng!.longitude,
        'address': _dropoffAddress
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).cardColor;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        elevation: 0,
        leading: BackButton(color: textColor),
        title: Text("Plan your ride", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              children: [
                _buildTextField(
                  controller: _pickupController,
                  focusNode: _pickupFocus,
                  hint: "Pickup Location",
                  icon: Icons.my_location,
                  iconColor: Colors.blue,
                  isDark: isDark,
                  onTap: () => setState(() => _isPickupFocused = true),
                ),
                const Divider(height: 20),
                _buildTextField(
                  controller: _dropoffController,
                  focusNode: _dropoffFocus,
                  hint: "Where to?",
                  icon: Icons.location_on,
                  iconColor: Colors.red,
                  isDark: isDark,
                  onTap: () => setState(() => _isPickupFocused = false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const LinearProgressIndicator(),
            
          Expanded(
            child: ListView.separated(
              itemCount: _predictions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _predictions[index];
                final mainText = item['structured_formatting']?['main_text'] ?? item['description'] ?? "";
                final secondaryText = item['structured_formatting']?['secondary_text'] ?? "";
                
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey, 
                    child: Icon(Icons.place, color: Colors.white)
                  ),
                  title: Text(
                    mainText,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
                  ),
                  subtitle: Text(
                    secondaryText,
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.grey)
                  ),
                  onTap: () => _onPredictionSelected(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        focusNode.requestFocus();
        onTap();
      },
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: _onSearchChanged,
              onTap: onTap,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
