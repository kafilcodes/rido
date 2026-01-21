import 'dart:io';
import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

class ProfileFormScreen extends ConsumerStatefulWidget {
  final String role; 

  const ProfileFormScreen({super.key, required this.role});

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _formKey = material.GlobalKey<material.FormState>();
  final _nameController = material.TextEditingController();
  final _pincodeController = material.TextEditingController();
  final _cityController = material.TextEditingController();
  
  File? _imageFile;
  DateTime? _dob;
  bool _isLoading = false;
  final Logger _logger = Logger();

  static const allowedPincodes = ['493773', '493776', '493663', '493662', '493778'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_imageFile == null) {
       material.ScaffoldMessenger.of(context).showSnackBar(const material.SnackBar(content: Text("Profile picture required")));
       return;
    }
    if (_dob == null) {
       material.ScaffoldMessenger.of(context).showSnackBar(const material.SnackBar(content: Text("Date of Birth required")));
       return;
    }
    
    final age = DateTime.now().year - _dob!.year;
    if (widget.role == 'driver' && age < 18) {
       material.ScaffoldMessenger.of(context).showSnackBar(const material.SnackBar(content: Text("Drivers must be 18+")));
       return;
    }
    if (widget.role == 'rider' && age < 16) {
       material.ScaffoldMessenger.of(context).showSnackBar(const material.SnackBar(content: Text("Riders must be 16+")));
       return;
    }

    if (!allowedPincodes.contains(_pincodeController.text)) {
      material.ScaffoldMessenger.of(context).showSnackBar(const material.SnackBar(content: Text("Service Unavailable: Rido is not yet available in your area.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = auth.FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No user logged in");

      // Upload Image
      final ref = FirebaseStorage.instance.ref().child('profiles/${user.uid}.jpg');
      await ref.putFile(_imageFile!);
      final imageUrl = await ref.getDownloadURL();

      // Write Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text,
        'role': widget.role,
        'profile_pic': imageUrl,
        'dob': _dob!.toIso8601String(),
        'city': _cityController.text,
        'pincode': _pincodeController.text,
        'phone': user.phoneNumber,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (widget.role == 'driver') {
        if (mounted) context.go('/verified-docs');
      } else {
        if (mounted) context.go('/home');
      }

    } catch (e) {
      _logger.e("Profile save failed: $e");
      setState(() => _isLoading = false);
      if(mounted) material.ScaffoldMessenger.of(context).showSnackBar(material.SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  material.Widget build(material.BuildContext context) {
    return material.Scaffold( // Material Scaffold
      appBar: material.AppBar(title: Text("Complete Profile (${widget.role.toUpperCase()})")),
      body: material.SingleChildScrollView(
        padding: const material.EdgeInsets.all(24),
        child: material.Form( // Material Form
          key: _formKey,
          child: material.Column(
            crossAxisAlignment: material.CrossAxisAlignment.stretch,
            children: [
              // Avatar
              material.Center(
                child: material.GestureDetector(
                  onTap: _pickImage,
                  child: material.CircleAvatar(
                     radius: 50,
                     backgroundColor: material.Colors.grey[200],
                     backgroundImage: _imageFile != null ? material.FileImage(_imageFile!) : null,
                     child: _imageFile == null ? const material.Icon(LucideIcons.camera, size: 32, color: material.Colors.grey) : null,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Name
              const Text('Full Name').h4(),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                placeholder: const Text("Enter your name"),
              ),
              
              const SizedBox(height: 16),
              
              // DOB
              const Text('Date of Birth').h4(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Button.outline(
                  onPressed: () async {
                     final d = await material.showDatePicker(
                      context: context,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _dob = d);
                  },
                  child: material.Row(
                    mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_dob == null ? "Select Date" : DateFormat('yyyy-MM-dd').format(_dob!)),
                      const material.Icon(LucideIcons.calendar, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // City
              const Text('City').h4(),
              const SizedBox(height: 8),
              TextField(
                controller: _cityController,
                 placeholder: const Text("e.g. Dhamtari"),
              ),

              const SizedBox(height: 16),

              // Pincode
              const Text('Pincode').h4(),
              const SizedBox(height: 8),
              TextField(
                controller: _pincodeController,
                keyboardType: material.TextInputType.number,
                maxLength: 6,
                 placeholder: const Text("e.g. 493773"),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: Button.primary(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading 
                    ? const material.SizedBox(width: 16, height: 16, child: material.CircularProgressIndicator(strokeWidth: 2, color: material.Colors.white)) 
                    : const Text("Save & Continue"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
