import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sizer/sizer.dart';
import 'package:logger/logger.dart';
import '../data/auth_repository.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phone;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phone,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController _pinController = TextEditingController();
  final Logger _logger = Logger();
  bool _isLoading = false;
  int _secondsRemaining = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _secondsRemaining = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  bool _isVerified = false;
  bool _hasError = false;

  void _verifyOtp([String? pin]) async {
    final smsCode = pin ?? _pinController.text;
    if (smsCode.length != 6) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final credential = PhoneAuthProvider.credential(
      verificationId: widget.verificationId,
      smsCode: smsCode,
    );

    final authRepo = ref.read(authRepositoryProvider);

    try {
      final userCred = await authRepo.signInWithCredential(credential);
      setState(() {
        _isLoading = false;
        _isVerified = true;
      });
      // Delay to show the checkmark
      await Future.delayed(const Duration(milliseconds: 800));
      _checkUserAndRedirect(userCred.user);
    } catch (e) {
      _logger.e("OTP Error: $e");
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Verification Failed: $e")));
      }
    }
  }

  void _checkUserAndRedirect(User? user) async {
    if (user == null) return;
    
    // Check Firestore
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    
    if (mounted) {
      if (doc.exists) {
        context.go('/home');
      } else {
        context.go('/role-selection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... defaultPinTheme definition omitted as it is unused or can be defined inline ...

    return Scaffold(
      appBar: AppBar(title: const Text("Verify Phone")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.message, size: 16.sp, color: Colors.grey),
                const SizedBox(width: 8),
                Text("Code sent to ${widget.phone}"),
              ],
            ),
            const SizedBox(height: 32),
            Pinput(
              controller: _pinController,
              pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
              showCursor: true,
              onCompleted: (pin) => _verifyOtp(pin),
              length: 6,
              defaultPinTheme: PinTheme(
                width: 56, 
                height: 56, 
                textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black), 
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200], 
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _hasError ? Colors.red : Theme.of(context).dividerColor), 
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 56, 
                height: 56, 
                 textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black), 
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200], 
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).primaryColor, width: 2), 
                ),
              ),
            ),
             const SizedBox(height: 32),
             Container(
                width: double.infinity,
                height: 6.h,
                decoration: BoxDecoration(
                  gradient: _isVerified 
                      ? const LinearGradient(colors: [Colors.green, Colors.lightGreen])
                      : const LinearGradient(
                          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: (_isLoading || _isVerified) ? null : () => _verifyOtp(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : _isVerified
                          ? const Icon(Icons.check, color: Colors.white, size: 30)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.white),
                                const SizedBox(width: 8),
                                Text("Verify", style: TextStyle(fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                ),
             ),
             const SizedBox(height: 16),
             if (_secondsRemaining > 0)
                TextButton.icon(
                  onPressed: null, 
                  icon: const Icon(Icons.timer_outlined, size: 16),
                  label: Text("Resend in $_secondsRemaining s"),
                )
             else
                TextButton.icon(
                  onPressed: () {
                    // Implement resend logic (call verifyPhoneNumber again)
                    startTimer();
                  }, 
                  icon: const Icon(Icons.refresh),
                  label: const Text("Resend OTP"),
                )
          ],
        ),
      ),
    );
  }
}
