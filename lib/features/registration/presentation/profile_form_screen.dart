import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

class ProfileFormScreen extends ConsumerStatefulWidget {
  final String role; // 'rider' or 'driver'

  const ProfileFormScreen({super.key, required this.role});

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  // ... other controllers
  
  File? _imageFile;
  DateTime? _dob;
  bool _isLoading = false;
  final Logger _logger = Logger();

  static const allowedPincodes = ['493773', '493776', '493663', '493662', '493778'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      if (await pickedFile.length() > 3000000) { // 3MB
         // Show error
         return;
      }
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture required")));
       return;
    }
    if (_dob == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Date of Birth required")));
       return;
    }
    
    // Age check
    final age = DateTime.now().year - _dob!.year;
    if (widget.role == 'driver' && age < 18) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Drivers must be 18+")));
       return;
    }
    if (widget.role == 'rider' && age < 16) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Riders must be 16+")));
       return;
    }

    // Pincode Check
    if (!allowedPincodes.contains(_pincodeController.text)) {
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'Service Unavailable',
          message: 'Service unavailable in this area.',
          contentType: ContentType.failure,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
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
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Complete Profile (${widget.role.toUpperCase()})")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                  child: _imageFile == null ? const Icon(Icons.camera_alt, size: 40) : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              // DOB Picker
              ListTile(
                title: Text(_dob == null ? "Select Date of Birth" : "DOB: ${DateFormat('yyyy-MM-dd').format(_dob!)}"),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.grey)),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _dob = d);
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: "City", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: "Pincode", border: OutlineInputBorder(), counterText: ""),
                validator: (v) => v!.length != 6 ? "Invalid Pincode" : null,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading ? const CircularProgressIndicator() : const Text("Save & Continue"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
