import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:rido/core/theme/ui_theme.dart';

class HomeSearchCard extends StatelessWidget {
  final VoidCallback onTap;
  final String greeting;

  const HomeSearchCard({
    super.key,
    required this.onTap,
    required this.greeting,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return material.Positioned(
      bottom: 20.h, // Positioned above the bottom area
      left: 5.w,
      right: 5.w,
      child: material.Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.background.withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(color: material.Colors.black12, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: Text(greeting).small().medium().foreground(),
          ),

          // Search Bar Trigger
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.border, width: 1),
                boxShadow: const [
                  BoxShadow(color: material.Colors.black12, blurRadius: 20, offset: Offset(0, 8))
                ],
              ),
              child: Row(
                children: [
                  // Icon with accent gradient
                  ShaderMask(
                    shaderCallback: (bounds) => UITheme.primaryGradient.createShader(bounds),
                    child: const Icon(LucideIcons.search, size: 24, color: material.Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Text("Where to?").h4().foreground(),
                  const Spacer(),
                  // removed "Now" indicator as requested
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
