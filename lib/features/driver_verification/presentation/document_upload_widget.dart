import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:sizer/sizer.dart';
import 'package:logger/logger.dart';

class DocumentUploadWidget extends StatefulWidget {
  final String label;
  final Function(File?) onImageSelected;
  final IconData icon;

  const DocumentUploadWidget({
    super.key,
    required this.label,
    required this.onImageSelected,
    this.icon = Icons.file_upload,
  });

  @override
  State<DocumentUploadWidget> createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  File? _file;
  final Logger _logger = Logger();

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        setState(() => _file = File(picked.path));
        widget.onImageSelected(_file);
      }
    } catch (e) {
      _logger.e("Image Pick Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 18.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey, style: BorderStyle.solid), // Fallback to solid
        ),
        child: _file == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 30.sp, color: Colors.grey),
                  SizedBox(height: 1.h),
                  Text(widget.label, style: TextStyle(color: Colors.grey[600], fontSize: 12.sp)),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_file!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              ),
      ),
    );
  }
}
