import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:geocoding/geocoding.dart';

class ConfirmLocationScreen extends StatefulWidget {
  final LatLng initialTarget;
  final String initialAddress;
  final bool isPickup;

  const ConfirmLocationScreen({
    super.key,
    required this.initialTarget,
    required this.initialAddress,
    this.isPickup = true,
  });

  @override
  State<ConfirmLocationScreen> createState() => _ConfirmLocationScreenState();
}

class _ConfirmLocationScreenState extends State<ConfirmLocationScreen> {
  late GoogleMapController _mapController;
  late LatLng _currentPosition;
  String _currentAddress = "";
  bool _isLoadingAddress = false;
  final List<XFile> _capturedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialTarget;
    _currentAddress = widget.initialAddress;
  }

  void _onCameraMove(CameraPosition position) {
    _currentPosition = position.target;
  }

  void _onCameraIdle() async {
    setState(() => _isLoadingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition.latitude, 
        _currentPosition.longitude
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _currentAddress = "${p.street}, ${p.subLocality}, ${p.locality}";
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _captureImage() async {
    if (_capturedImages.length >= 2) return;
    
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _capturedImages.add(photo);
      });
    }
  }

  void _confirm() {
    Navigator.pop(context, {
      'latLng': _currentPosition,
      'address': _currentAddress,
      'images': _capturedImages.map((e) => e.path).toList(), // Return paths
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: widget.initialTarget, zoom: 18),
            onMapCreated: (c) {
              _mapController = c;
              if (isDark) {
                // Apply dark style if available
              }
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
          ),
          
          // Center Pin
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35), // Adjust for pin tip
              child: Icon(Icons.location_on, size: 45, color: Theme.of(context).primaryColor),
            ),
          ),
          
          // Back Button
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Theme.of(context).cardColor,
              child: BackButton(color: isDark ? Colors.white : Colors.black),
            ),
          ),

          // Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                     widget.isPickup ? "Confirm Pickup Location" : "Confirm Dropoff Location",
                     style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                   ),
                   const SizedBox(height: 8),
                   Row(
                     children: [
                       Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                       const SizedBox(width: 10),
                       Expanded(
                         child: _isLoadingAddress 
                           ? const LinearProgressIndicator() 
                           : Text(_currentAddress, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                       ),
                     ],
                   ),
                   const SizedBox(height: 20),
                   
                   // Images Section
                   if (widget.isPickup) ...[
                     Row(
                       children: [
                         ElevatedButton.icon(
                           onPressed: _capturedImages.length < 2 ? _captureImage : null, 
                           icon: const Icon(Icons.camera_alt),
                           label: const Text("Surround Photo"),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                             foregroundColor: isDark ? Colors.white : Colors.black,
                           ),
                         ),
                         const SizedBox(width: 10),
                         ..._capturedImages.map((img) => Padding(
                           padding: const EdgeInsets.only(right: 8.0),
                           child: ClipRRect(
                             borderRadius: BorderRadius.circular(8),
                             child: Image.file(File(img.path), width: 40, height: 40, fit: BoxFit.cover),
                           ),
                         )),
                       ],
                     ),
                     const SizedBox(height: 20),
                   ],

                   SizedBox(
                     width: double.infinity,
                     height: 50,
                     child: Container(
                       decoration: BoxDecoration(
                         gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                         borderRadius: BorderRadius.circular(12)
                       ),
                       child: ElevatedButton(
                         onPressed: _isLoadingAddress ? null : _confirm,
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.transparent,
                           foregroundColor: Colors.white,
                           shadowColor: Colors.transparent,
                         ),
                         child: const Text("Confirm Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       ),
                     ),
                   )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
