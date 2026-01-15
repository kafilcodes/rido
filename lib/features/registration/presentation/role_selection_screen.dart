import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose your role")),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCard(context, "Rider", Icons.person, "rider"),
            _buildCard(context, "Driver", Icons.drive_eta, "driver"),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, String role) {
    return InkWell(
      onTap: () => context.push('/profile-form', extra: role),
      child: Card(
        child: Container(
          width: 40.w,
          height: 20.h,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40.sp),
              SizedBox(height: 1.h),
              Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
