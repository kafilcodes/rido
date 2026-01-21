import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:sizer/sizer.dart';
import 'package:lottie/lottie.dart';
import 'package:rido/core/theme/ui_theme.dart';
import '../data/auth_repository.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final material.GlobalKey<material.FormState> _formKey = material.GlobalKey<material.FormState>();
  bool _isLoading = false;
  bool _isValidPhone = false;
  final Logger _logger = Logger();

  bool _isFakePhoneNumber(String phone) {
    if (phone.length != 10) return false; // Should verify length first

    // 1. Check for all same digits (0000000000, 1111111111, etc.)
    if (RegExp(r'^(\d)\1+$').hasMatch(phone)) return true;

    // 2. Check for sequential patterns
    const sequences = ['0123456789', '1234567890', '9876543210', '0987654321'];
    if (sequences.contains(phone)) return true;

    // 3. Check for repeating blocks (e.g., 1212121212, 1231231231)
    // Simple heuristic: if the first 5 digits repeated equals the string
    if (phone.substring(0, 5) * 2 == phone) return true;
    // If first 2 digits repeated 5 times
    if (phone.substring(0, 2) * 5 == phone) return true;

    return false;
  }

  void _onPhoneChanged(String value) {
    // Basic format check + Fake check
    if (value.length == 10 && RegExp(r'^[0-9]{10}$').hasMatch(value)) {
       if (_isFakePhoneNumber(value)) {
         setState(() => _isValidPhone = false);
       } else {
         setState(() => _isValidPhone = true);
       }
    } else {
       if (_isValidPhone) setState(() => _isValidPhone = false);
    }
  }

  void _verifyPhone() async {
    final phoneText = _phoneController.text.trim();
    
    // Comprehensive Validation
    if (phoneText.isEmpty || phoneText.length != 10 || _isFakePhoneNumber(phoneText)) {
      String message = 'Please enter a valid 10-digit phone number';
      if (_isFakePhoneNumber(phoneText)) {
        message = 'Please enter a valid, real phone number';
      }

      showToast(
         context: context,
         builder: (context, overlay) => SurfaceCard(
          child: Basic(
            title: const Text('Invalid Number'),
            subtitle: Text(message),
          ),
        ),
        location: ToastLocation.bottomRight,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.verifyPhoneNumber(
        phoneNumber: '+91$phoneText', 
        verificationCompleted: (credential) async {
          await authRepo.signInWithCredential(credential);
          if (mounted) context.go('/home'); 
        },
        verificationFailed: (e) {
             if (mounted) {
               setState(() => _isLoading = false);
               showToast(
                context: context,
                builder: (context, overlay) => SurfaceCard(
                  child: Basic(
                    title: const Text('Verification Failed'),
                    subtitle: Text(e.message ?? 'Unknown error occurred'),
                  ),
                ),
                location: ToastLocation.bottomRight,
              );
            }
        },
        codeSent: (verificationId, [resendToken]) {
           if (mounted) {
              setState(() => _isLoading = false);
              context.push(
                '/otp', 
                extra: {
                  'verificationId': verificationId,
                  'phone': '+91$phoneText',
                }
              );
           }
        },
        codeAutoRetrievalTimeout: (verificationId) {
           if (mounted) {
             setState(() => _isLoading = false);
           }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showToast(
          context: context,
          builder: (context, overlay) => SurfaceCard(
            child: Basic(
              title: const Text('Error'),
              subtitle: Text(e.toString()),
            ),
          ),
          location: ToastLocation.bottomRight,
        );
      }
    }
  }

  @override
  material.Widget build(material.BuildContext context) {
    return material.Scaffold(
      body: material.Center(
        child: material.SingleChildScrollView(
          padding: const material.EdgeInsets.all(24.0),
          child: material.Column(
            mainAxisAlignment: material.MainAxisAlignment.center,
            crossAxisAlignment: material.CrossAxisAlignment.stretch,
            children: [
              material.Center(
                child: Lottie.asset(
                  'assets/lottie/auth.json',
                  height: 30.h,
                  fit: material.BoxFit.contain,
                ),
              ),
              const material.SizedBox(height: 32),
              
              Text(
                "Enter your mobile number",
                style: material.Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: material.FontWeight.bold,
                ),
                textAlign: material.TextAlign.center,
              ),
              const material.SizedBox(height: 8),
              const Text("We will send you a confirmation code").muted().center(),
              const material.SizedBox(height: 32),
              
              // Phone Field with Flag
              material.TextField(
                controller: _phoneController,
                onChanged: _onPhoneChanged,
                keyboardType: material.TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                   FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: material.InputDecoration(
                  hintText: "Enter mobile number",
                  counterText: "",
                  filled: true,
                  fillColor: material.Theme.of(context).inputDecorationTheme.fillColor,
                  border: material.OutlineInputBorder(
                    borderRadius: material.BorderRadius.circular(8),
                    borderSide: material.BorderSide.none,
                  ),
                  prefixIcon: material.Container(
                     padding: const material.EdgeInsets.symmetric(horizontal: 12),
                     child: material.Row(
                       mainAxisSize: material.MainAxisSize.min,
                       children: [
                         const Text("🇮🇳", style: material.TextStyle(fontSize: 24)),
                         const material.SizedBox(width: 8),
                         Text("+91", style: material.TextStyle(fontWeight: material.FontWeight.bold, color: material.Theme.of(context).colorScheme.onSurface)),
                         const material.SizedBox(width: 8),
                         material.Container(height: 24, width: 1, color: material.Colors.grey.withOpacity(0.3)),
                       ],
                     ),
                  ),
                ),
              ),
              const material.SizedBox(height: 24),
              
              // Continue Button
              material.GestureDetector(
                onTap: (_isValidPhone && !_isLoading) ? _verifyPhone : null,
                child: material.Container(
                   width: double.infinity,
                   padding: const material.EdgeInsets.symmetric(vertical: 16),
                   alignment: material.Alignment.center,
                   decoration: material.BoxDecoration(
                     borderRadius: material.BorderRadius.circular(8),
                     color: (_isValidPhone || _isLoading) 
                        ? material.Theme.of(context).colorScheme.primary 
                        : material.Colors.grey[800], // Disabled color (Dark mode appropriate)
                   ),
                   child: _isLoading 
                     ? const material.SizedBox(width: 24, height: 24, child: material.CircularProgressIndicator(strokeWidth: 2, color: material.Colors.white))
                     : material.Row(
                         mainAxisAlignment: material.MainAxisAlignment.center,
                         children: [
                           Text(
                             "Continue", 
                             style: material.TextStyle(
                               fontWeight: material.FontWeight.bold, 
                               fontSize: 16,
                               color: (_isValidPhone || _isLoading) 
                                  ? material.Theme.of(context).colorScheme.onPrimary 
                                  : material.Colors.white54, // Disabled text color
                             )
                           ),
                           const material.SizedBox(width: 8),
                           Icon(
                             LucideIcons.arrowRight, 
                             size: 18, 
                             color: (_isValidPhone || _isLoading) 
                                ? material.Theme.of(context).colorScheme.onPrimary 
                                : material.Colors.white54
                           ),
                         ],
                       ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
