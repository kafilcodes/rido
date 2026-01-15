import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sizer/sizer.dart';

class FindingDriverScreen extends StatelessWidget {
  const FindingDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
       decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset('assets/lottie/ride.json', height: 15.h), // Reusing existing lottie
          SizedBox(height: 2.h),
          Text("Connecting to nearby drivers...", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 1.h),
          LinearProgressIndicator(backgroundColor: Colors.grey[200], color: Colors.black),
          SizedBox(height: 4.h),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel Request"),
          )
        ],
      ),
    );
  }
}
