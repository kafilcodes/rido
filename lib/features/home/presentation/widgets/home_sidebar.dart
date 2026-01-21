import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rido/core/theme/ui_theme.dart';
import 'package:shimmer/shimmer.dart'; // Add Shimmer Import
import 'package:rido/core/theme/theme_provider.dart';

class HomeSidebar extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final Function(int) onIndexChanged;
  final int currentIndex;
  final Map<String, dynamic>? userData; // If null, assume loading
  final User? currentUser;

  const HomeSidebar({
    super.key,
    required this.onClose,
    required this.onIndexChanged,
    this.currentIndex = 0,
    required this.userData,
    required this.currentUser,
  });

  @override
  ConsumerState<HomeSidebar> createState() => _HomeSidebarState();
}

class _HomeSidebarState extends ConsumerState<HomeSidebar> {

  void _toggleTheme() {
    ref.read(themeProvider.notifier).toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    // Shimmer Loading State
    final isLoading = widget.userData == null && widget.currentUser != null; // Simple heuristic

    final name = widget.userData?['name'] as String? ?? widget.currentUser?.displayName ?? "User";
    final phone = widget.userData?['phone'] as String? ?? widget.currentUser?.phoneNumber ?? "";
    final photoUrl = widget.userData?['profile_pic'] as String?;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Define shimmer colors
    final baseColor = isDark ? const material.Color(0xFF27272a) : material.Colors.grey[300]!;
    final highlightColor = isDark ? const material.Color(0xFF3f3f46) : material.Colors.grey[100]!;

    // Fallback Initials
    String initials = "U";
    if (name.isNotEmpty) {
      initials = name[0].toUpperCase();
      if (name.contains(" ")) {
        final parts = name.split(" ");
        if (parts.length > 1 && parts[1].isNotEmpty) {
          initials = "${parts[0][0]}${parts[1][0]}".toUpperCase();
        }
      }
    }

    return Container(
      width: 75.w,
      height: 100.h,
      color: theme.colorScheme.background,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              children: [
                if (isLoading)
                   Shimmer.fromColors(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      child: const material.CircleAvatar(radius: 24, backgroundColor: material.Colors.white),
                   )
                else
                  material.CircleAvatar(
                    radius: 24,
                    backgroundImage: (photoUrl != null) ? NetworkImage(photoUrl) : null,
                    backgroundColor: (photoUrl == null) ? UITheme.primaryGradient.colors.first : null,
                    child: (photoUrl == null)
                        ? Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, color: material.Colors.white))
                        : null,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading) ...[
                         Shimmer.fromColors(
                            baseColor: baseColor,
                            highlightColor: highlightColor,
                            child: Container(width: 100, height: 16, decoration: BoxDecoration(color: material.Colors.white, borderRadius: BorderRadius.circular(4))),
                         ),
                         const SizedBox(height: 4),
                         Shimmer.fromColors(
                            baseColor: baseColor,
                            highlightColor: highlightColor,
                            child: Container(width: 80, height: 12, decoration: BoxDecoration(color: material.Colors.white, borderRadius: BorderRadius.circular(4))),
                         ),
                      ] else ...[
                         Text(name).h4().ellipsis().foreground(),
                         Text(phone).muted().small(),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                _buildNavItem("Home", LucideIcons.house, 0),
                _buildNavItem("Activity", LucideIcons.history, 1),
                _buildNavItem("Account", LucideIcons.user, 2),
                _buildNavItem("Notifications", LucideIcons.bell, 3), // New Item
                
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8),
                  child: const Text("Preferences").muted().small(),
                ),
                
                // Theme Switcher : Corrected to ensure it works
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    // color: theme.colorScheme.secondary.withOpacity(0.5), // Optional: Remove bg for cleaner look? Keeping as is for grouping
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(isDark ? LucideIcons.moon : LucideIcons.sun, size: 20, color: theme.colorScheme.foreground),
                          const SizedBox(width: 12),
                          Text("Dark Mode", style: TextStyle(color: theme.colorScheme.foreground)),
                        ],
                      ),
                      Switch(
                        value: isDark,
                        onChanged: (v) => _toggleTheme(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Button.ghost(
              onPressed: () {
                widget.onClose();
                FirebaseAuth.instance.signOut();
                context.go('/auth');
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(LucideIcons.logOut, color: theme.colorScheme.destructive, size: 20),
                  const SizedBox(width: 12),
                  Text("Sign Out", style: TextStyle(color: theme.colorScheme.destructive)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, IconData icon, int index) {
    final isSelected = widget.currentIndex == index;
    final theme = Theme.of(context);
    
    // Active: Gradient Icon & Text, Transparent BG (Clean look)
    // Inactive: Foreground color
    
    final content = Row(
      children: [
        Icon(
          icon, 
          size: 20, 
          color: isSelected ? material.Colors.white : theme.colorScheme.foreground // White if gradient mask applied? No, mask needs white to apply colors.
        ),
        const SizedBox(width: 12),
        Text(
          title, 
          style: TextStyle(
            color: isSelected ? material.Colors.white : theme.colorScheme.foreground,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          )
        ),
        if (isSelected) ...[
           const Spacer(),
           // Dot indicator instead of chevron for "Clean" look? Or Gradient Chevron?
           // Using Gradient Chevron
           const Icon(LucideIcons.chevronRight, size: 16, color: material.Colors.white),
        ]
      ],
    );

    return GestureDetector(
      onTap: () {
        widget.onIndexChanged(index);
        widget.onClose();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
           // Removing vibrant background as requested
           color: material.Colors.transparent, 
           borderRadius: BorderRadius.circular(8),
        ),
        child: isSelected 
          ? ShaderMask(
              shaderCallback: (bounds) => UITheme.primaryGradient.createShader(bounds),
              child: content,
            )
          : content,
      ),
    );
  }
}
