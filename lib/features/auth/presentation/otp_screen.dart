import 'dart:async';
import 'package:flutter/material.dart' as material;
import 'package:rido/core/theme/ui_theme.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
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
  final material.TextEditingController _pinController = material.TextEditingController();
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
         material.ScaffoldMessenger.of(context).showSnackBar(material.SnackBar(content: material.Text("Verification Failed: $e")));
      }
    }
  }

  void _checkUserAndRedirect(User? user) async {
    if (user == null) return;
    
    // Check Firestore
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    
    if (mounted) {
      // Check if document exists AND has valid data (e.g. name is not empty)
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('name') && (data['name'] as String).isNotEmpty) {
           context.go('/home');
        } else {
           // Document exists but profile incomplete? Go to role/profile
           context.go('/role-selection');
        }
      } else {
        context.go('/role-selection');
      }
    }
  }

  @override
  material.Widget build(material.BuildContext context) {
    // Theme-aware Pinput colors
    final theme = material.Theme.of(context);
    final borderColor = theme.colorScheme.outline;
    final focusedColor = theme.colorScheme.primary;
    final fillColor = theme.colorScheme.surface;
    
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: material.TextStyle(fontSize: 20, color: theme.colorScheme.onSurface, fontWeight: material.FontWeight.w600),
      decoration: material.BoxDecoration(
        color: fillColor,
        borderRadius: material.BorderRadius.circular(8),
        border: material.Border.all(color: _hasError ? theme.colorScheme.error : borderColor),
      ),
    );

    return material.Scaffold(
      appBar: material.AppBar(title: const Text("Verify Phone")),
      body: material.SingleChildScrollView(
        padding: const material.EdgeInsets.all(24.0),
        child: material.Column(
          children: [
            material.Row(
              mainAxisAlignment: material.MainAxisAlignment.center,
              children: [
                material.Icon(LucideIcons.messageSquare, size: 16.sp, color: theme.colorScheme.onSurface),
                const SizedBox(width: 8),
                Text("Code sent to ${widget.phone}").muted(),
              ],
            ),
            const SizedBox(height: 32),
            Pinput(
              controller: _pinController,
              pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
              showCursor: true,
              onCompleted: (pin) => _verifyOtp(pin),
              length: 6,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: material.Border.all(color: focusedColor, width: 2),
                ),
              ),
            ),
             const SizedBox(height: 32),
             
             SizedBox(
               width: double.infinity,
               height: 6.h,
               child: _isVerified 
               ? Button.secondary(
                  onPressed: null,
                  child: const material.Icon(LucideIcons.check, size: 24),
                 )
               : material.GestureDetector(
                  onTap: (!_isLoading) ? () => _verifyOtp() : null,
                  child: material.Container(
                    width: double.infinity,
                    padding: const material.EdgeInsets.symmetric(vertical: 16),
                    alignment: material.Alignment.center,
                    decoration: material.BoxDecoration(
                      borderRadius: material.BorderRadius.circular(8),
                      color: material.Theme.of(context).colorScheme.primary,
                    ),
                    child: _isLoading
                        ? const material.SizedBox(width: 24, height: 24, child: material.CircularProgressIndicator(strokeWidth: 2, color: material.Colors.white))
                        : const material.Row(
                            mainAxisAlignment: material.MainAxisAlignment.center,
                            children: [
                               Text("Verify & Continue", style: material.TextStyle(fontWeight: material.FontWeight.bold, fontSize: 16, color: material.Colors.white)),
                               material.SizedBox(width: 8),
                               Icon(LucideIcons.arrowRight, size: 18, color: material.Colors.white),
                            ],
                          ),
                  ),
                ),
             ),

             const SizedBox(height: 16),
             if (_secondsRemaining > 0)
                Button.ghost(
                  onPressed: null, 
                  child: material.Row(
                    mainAxisSize: material.MainAxisSize.min,
                    children: [
                      const material.Icon(LucideIcons.timer, size: 16),
                      const SizedBox(width: 8),
                      Text("Resend in $_secondsRemaining s"),
                    ],
                  ),
                )
             else
                Button.ghost(
                  onPressed: () {
                    startTimer();
                  }, 
                  child: const Text("Resend OTP"),
                )
          ],
        ),
      ),
    );
  }
}
