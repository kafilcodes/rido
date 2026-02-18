import 'dart:async';
import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:lottie/lottie.dart';
// import 'package:go_router/go_router.dart'; // Unused
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/places_service.dart';
import 'confirm_location_screen.dart';

class DestinationSearchScreen extends material.StatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  material.State<DestinationSearchScreen> createState() => _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends material.State<DestinationSearchScreen> {
  final material.TextEditingController _pickupController = material.TextEditingController();
  final material.TextEditingController _dropoffController = material.TextEditingController();
  final material.FocusNode _pickupFocus = material.FocusNode();
  final material.FocusNode _dropoffFocus = material.FocusNode();
  
  final PlacesService _placesService = PlacesService();
  final _uuid = const Uuid();
  String _sessionToken = "";
  Timer? _debounce;
  
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = false;
  
  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  String? _pickupAddress;
  String? _dropoffAddress;
  List<String> _pickupImages = [];
  bool _isPickupFocused = false;

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
      material.debugPrint("Error fetching current location: $e");
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    // increased debounce to 500ms as requested
    _debounce = Timer(const Duration(milliseconds: 500), () async {
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
      // Validate PIN Code (Strict Restriction)
      if (!_isValidLocation(details)) {
        if (!mounted) return;
        
        // Show Toast/Dialog for invalid location
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Out of Service Area"),
            content: const Text("Rido is currently only available in Dhamtari, Kurud, Nagri, and Magarlod."),
            actions: [
              TextButton(child: const Text("OK"), onPressed: () => Navigator.pop(context))
            ],
          ),
        );
        return;
      }
      
      final lat = details['geometry']['location']['lat'];
      final lng = details['geometry']['location']['lng'];
      final latLng = LatLng(lat, lng);
      
      if (!mounted) return;

      // Navigate to Map Confirmation
      final result = await material.Navigator.push(
        context, 
        material.MaterialPageRoute(builder: (_) => ConfirmLocationScreen(
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

  // Allowed PIN codes for Dhamtari district
  final _allowedPinCodes = {
    '493773', // Dhamtari
    '493776', // Rudri
    '493663', // Kurud
    '493662', // Magarlod
    '493778', // Nagri
  };

  bool _isValidLocation(Map<String, dynamic> details) {
    final components = details['address_components'] as List<dynamic>?;
    if (components == null) return false; // Fail safe if no components

    for (var c in components) {
      final types = (c['types'] as List).cast<String>();
      if (types.contains('postal_code')) {
        final postalCode = c['text'] ?? c['longText'] ?? ""; 
        // New API uses 'text', legacy used 'long_name'. 
        // My PlacesService maps response directly, but New API has 'longText' inside component object?
        // Actually New API returns { "type": "postal_code", "longText": "493773" ... }
        // Wait, I am passing raw list from service. 
        // New API 'addressComponents' items have 'longText', 'shortText', 'types'.
        
        // Let's print to debug if needed, but safe access:
        final code = c['longText'] ?? c['shortText'];
        if (_allowedPinCodes.contains(code)) {
          return true;
        }
      }
    }
    // If no postal code found, or not in list... 
    // Maybe we should allow if likely inside bounds? But strict was requested.
    // Let's adhere to strict PIN list.
    return false;
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
        material.FocusScope.of(context).requestFocus(_dropoffFocus);
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
    material.Navigator.pop(context, {
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
  material.Widget build(material.BuildContext context) {
    // USE SHADCN THEME
    final theme = Theme.of(context);
    final scaffoldColor = theme.colorScheme.background;
    final cardColor = theme.colorScheme.card;
    final textColor = theme.colorScheme.foreground;
    final mutedColor = theme.colorScheme.mutedForeground;
    
    // Fix undefined variables
    final backgroundColor = theme.colorScheme.card;
    final isDark = theme.brightness == Brightness.dark;

    return material.Scaffold(
      backgroundColor: scaffoldColor,
      appBar: material.AppBar(
        backgroundColor: scaffoldColor,
        elevation: 0,
        leading: material.BackButton(color: textColor),
        title: material.Text("Plan your ride", style: material.TextStyle(color: textColor, fontWeight: material.FontWeight.bold)),
      ),
      body: material.Column(
        children: [
          material.Container(
            padding: const material.EdgeInsets.all(16),
            margin: const material.EdgeInsets.symmetric(horizontal: 16),
            decoration: material.BoxDecoration(
              color: backgroundColor,
              borderRadius: material.BorderRadius.circular(16),
              boxShadow: isDark ? [] : [material.BoxShadow(color: material.Colors.black12, blurRadius: 10)],
            ),
            child: material.Column(
              children: [
                _buildTextField(
                  controller: _pickupController,
                  focusNode: _pickupFocus,
                  hint: "Pickup Location",
                  icon: material.Icons.my_location,
                  iconColor: material.Colors.blue,
                  isDark: isDark,
                  textColor: textColor,
                  hintColor: mutedColor,
                  onTap: () => setState(() => _isPickupFocused = true),
                ),
                const material.Divider(height: 20),
                _buildTextField(
                  controller: _dropoffController,
                  focusNode: _dropoffFocus,
                  hint: "Where to?",
                  icon: material.Icons.location_on,
                  iconColor: material.Colors.red,
                  isDark: isDark,
                  textColor: textColor,
                  hintColor: mutedColor,
                  onTap: () => setState(() => _isPickupFocused = false),
                ),
              ],
            ),
          ),
          const material.SizedBox(height: 16),
          if (_isLoading)
            const material.LinearProgressIndicator(),
            
          material.Expanded(
            child: _predictions.isEmpty && !_isLoading 
              ? material.Center(
             child: Padding(
               padding: const EdgeInsets.only(bottom: 10, top: 10),
               child: material.Image.asset(
                 'assets/lottie/lovefordhamatari.gif',
                 height: 500,
                 width: 500,
                 gaplessPlayback: true,
               ),
             ),
          )
              : material.ListView.separated(
                  itemCount: _predictions.length,
                  separatorBuilder: (_, __) => const material.Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _predictions[index];
                    final mainText = item['structured_formatting']?['main_text'] ?? item['description'] ?? "";
                    final secondaryText = item['structured_formatting']?['secondary_text'] ?? "";
                    
                    return material.ListTile(
                      leading: const material.CircleAvatar(
                        backgroundColor: material.Colors.grey, 
                        child: material.Icon(material.Icons.place, color: material.Colors.white)
                      ),
                      title: material.Text(
                        mainText,
                        style: material.TextStyle(color: textColor, fontWeight: material.FontWeight.bold)
                      ),
                      subtitle: material.Text(
                        secondaryText,
                        style: material.TextStyle(color: mutedColor)
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

  material.Widget _buildTextField({
    required material.TextEditingController controller,
    required material.FocusNode focusNode,
    required String hint,
    required material.IconData icon,
    required material.Color iconColor,
    required bool isDark,
    required material.Color textColor,
    required material.Color hintColor,
    required material.VoidCallback onTap,
  }) {
    // keeping custom text field as requested
            // Pickup Field
            return material.Container(
               decoration: material.BoxDecoration(
                 color: isDark ? material.Colors.white.withOpacity(0.05) : material.Colors.grey.withOpacity(0.05),
                 borderRadius: material.BorderRadius.circular(8),
               ),
               child: material.TextField(
                 controller: controller,
                 focusNode: focusNode,
                 style: material.TextStyle(color: textColor),
                 decoration: material.InputDecoration(
                   hintText: hint,
                   hintStyle: material.TextStyle(color: hintColor),
                   border: material.InputBorder.none,
                   prefixIcon: material.Icon(icon, color: iconColor),
                   contentPadding: const material.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                 ),
                 onChanged: (val) => _onSearchChanged(val),
                 onTap: onTap,
               ),
            );
  }
}
