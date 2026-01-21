import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';

class RoleSelectionScreen extends material.StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  material.Widget build(material.BuildContext context) {
    return material.Scaffold(
      appBar: material.AppBar(title: const Text("Choose your role")),
      body: material.Center(
        child: material.Row(
          mainAxisAlignment: material.MainAxisAlignment.spaceEvenly,
          children: [
            _buildCard(context, "Rider", LucideIcons.user, "rider"),
            _buildCard(context, "Driver", LucideIcons.car, "driver"),
          ],
        ),
      ),
    );
  }

  material.Widget _buildCard(material.BuildContext context, String title, IconData icon, String role) {
    return material.GestureDetector(
      onTap: () => context.push('/profile-form', extra: role),
      child: SizedBox(
        width: 40.w,
        height: 20.h,
        child: Card( // Shadcn Card
          padding: const material.EdgeInsets.all(16),
          child: material.Column(
            mainAxisAlignment: material.MainAxisAlignment.center,
            children: [
              material.Icon(icon, size: 40.sp),
              SizedBox(height: 1.h),
              Text(title).h3(), 
            ],
          ),
        ),
      ),
    );
  }
}
