import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'document_upload_widget.dart';

class VerifiedDocsScreen extends StatefulWidget {
  const VerifiedDocsScreen({super.key});

  @override
  State<VerifiedDocsScreen> createState() => _VerifiedDocsScreenState();
}

class _VerifiedDocsScreenState extends State<VerifiedDocsScreen> {
  final _aadharController = TextEditingController();
  File? _aadharFront;
  File? _aadharBack;
  File? _licenseFront;
  bool _isLoading = false;
  final Logger _logger = Logger();

  Future<void> _uploadDocs() async {
    if (_aadharController.text.replaceAll(' ', '').length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Aadhar Number")));
      return;
    }
    if (_aadharFront == null || _aadharBack == null || _licenseFront == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload all documents")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final storage = FirebaseStorage.instance;
      
      // Upload
      final aadharFrontUrl = await _uploadFile(_aadharFront!, 'drivers/$uid/aadhar_front.jpg');
      final aadharBackUrl = await _uploadFile(_aadharBack!, 'drivers/$uid/aadhar_back.jpg');
      final licenseUrl = await _uploadFile(_licenseFront!, 'drivers/$uid/license_front.jpg');

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'aadhar_number': _aadharController.text,
        'aadhar_front': aadharFrontUrl,
        'aadhar_back': aadharBackUrl,
        'license_front': licenseUrl,
        'step': 1, // 1 = Docs Done
      });
      
      if (mounted) context.push('/vehicle-details');

    } catch (e) {
      _logger.e(e);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _uploadFile(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Document Verification")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Aadhar Card Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _aadharController,
              keyboardType: TextInputType.number,
              maxLength: 14, // 12 + 2 spaces
              inputFormatters: [
                 FilteringTextInputFormatter.digitsOnly,
                 _AadharFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: "Aadhar Number",
                hintText: "XXXX XXXX XXXX",
                border: OutlineInputBorder(),
                counterText: "",
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: DocumentUploadWidget(label: "Front Side", onImageSelected: (f) => setState(() => _aadharFront = f))),
                const SizedBox(width: 10),
                Expanded(child: DocumentUploadWidget(label: "Back Side", onImageSelected: (f) => setState(() => _aadharBack = f))),
              ],
            ),
            const SizedBox(height: 30),
            const Text("Driving License", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
             DocumentUploadWidget(label: "License Front", onImageSelected: (f) => setState(() => _licenseFront = f), icon: Icons.badge),
             const SizedBox(height: 40),
             SizedBox(
               width: double.infinity,
               height: 50,
               child: ElevatedButton(
                 onPressed: _isLoading ? null : _uploadDocs,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.black,
                   foregroundColor: Colors.white,
                 ),
                 child: _isLoading ? const CircularProgressIndicator() : const Text("Next Step"),
               ),
             )
          ],
        ),
      ),
    );
  }
}

class _AadharFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');
    // Logic to add space every 4 chars...
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(text: string, selection: TextSelection.collapsed(offset: string.length));
  }
}
