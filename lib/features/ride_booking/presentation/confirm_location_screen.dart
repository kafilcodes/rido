import 'dart:io';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
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
      if (mounted) setState(() => _isLoadingAddress = false);
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
    Navigator.of(context).pop({
      'latLng': _currentPosition,
      'address': _currentAddress,
      'images': _capturedImages.map((e) => e.path).toList(), // Return paths
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return material.Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: widget.initialTarget, zoom: 18),
            onMapCreated: (c) {
              _mapController = c;
              if (theme.brightness == Brightness.dark) {
                // Apply dark style if available (optional enhancement)
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
              child: Icon(material.Icons.location_on, size: 45, color: theme.colorScheme.primary),
            ),
          ),
          
          // Back Button
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.background, // Adaptive background
                shape: BoxShape.circle,
                boxShadow: [
                   BoxShadow(blurRadius: 8, color: material.Colors.black12)
                ]
              ),
              child: const material.BackButton(),
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
                color: theme.colorScheme.card, // Adaptive card color
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: const [BoxShadow(blurRadius: 10, color: material.Colors.black12)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                     widget.isPickup ? "Confirm Pickup Location" : "Confirm Dropoff Location",
                     style: theme.typography.small.copyWith(color: theme.colorScheme.mutedForeground),
                   ),
                   const SizedBox(height: 8),
                   Row(
                     children: [
                       Icon(material.Icons.location_on, color: theme.colorScheme.primary),
                       const SizedBox(width: 10),
                       Expanded(
                         child: _isLoadingAddress 
                           ? const material.LinearProgressIndicator() 
                           : Text(_currentAddress).medium().foreground(),
                       ),
                     ],
                   ),
                   const SizedBox(height: 20),
                   
                   // Images Section
                   if (widget.isPickup) ...[
                     Row(
                       children: [
                         Button.outline(
                           onPressed: _capturedImages.length < 2 ? _captureImage : null, 
                           child: Row(
                             children: [
                               const Icon(LucideIcons.camera, size: 16),
                               const SizedBox(width: 8),
                               const Text("Surround Photo"),
                             ],
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
                     child: Button.primary(
                       onPressed: _isLoadingAddress ? null : _confirm,
                       child: const Text("Confirm Location"),
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
