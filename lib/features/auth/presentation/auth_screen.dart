import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:sizer/sizer.dart';
import 'package:lottie/lottie.dart';
import '../data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final Logger _logger = Logger();

  void _verifyPhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final phone = "+91${_phoneController.text.trim()}";

    final authRepo = ref.read(authRepositoryProvider);
    
    await authRepo.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        _logger.i("Auto verification completed");
        await authRepo.signInWithCredential(credential);
        if (mounted) context.go('/home'); // Or check profile
      },
      verificationFailed: (e) {
        _logger.e("Verification Failed: ${e.message}");
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message}")),
        );
      },
      codeSent: (verificationId, resendToken) {
        _logger.i("Code sent to $phone");
        setState(() => _isLoading = false);
        context.push('/otp', extra: {
          'verificationId': verificationId,
          'phone': phone,
        });
      },
      codeAutoRetrievalTimeout: (verificationId) {
         _logger.w("Auto retrieval timeout");
         // Handle timeout if needed
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 5.h),
                Center(
                  child: Lottie.asset(
                    'assets/lottie/auth.json',
                    height: 30.h,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  "Enter your mobile number",
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2.h),
                Text(
                  "We'll send you a verification code.",
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
                SizedBox(height: 4.h),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    prefixText: "+91 ",
                    prefixIcon: Icon(Icons.phone_android, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelText: "Phone Number",
                    counterText: "",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Required";
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                      return "Invalid Number";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 4.h),
                Container(
                  width: double.infinity,
                  height: 6.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)], // Purplish Gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _verifyPhone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _isLoading 
                      ? const SizedBox.shrink()
                      : const Icon(Icons.arrow_forward, color: Colors.white),
                    label: _isLoading 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        ) 
                      : Text("Continue", style: TextStyle(fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
