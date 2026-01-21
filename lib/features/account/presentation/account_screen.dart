import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:rido/core/theme/ui_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sizer/sizer.dart';

class AccountScreen extends material.StatefulWidget {
  const AccountScreen({super.key});

  @override
  material.State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends material.State<AccountScreen> {
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userData = doc.data();
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      material.debugPrint("Error fetching profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // USE SHADCN THEME
    final theme = Theme.of(context);
    
    final name = _userData?['name'] as String? ?? _user?.displayName ?? "User";
    final phone = _userData?['phone'] as String? ?? _user?.phoneNumber ?? "";
    final photoUrl = _userData?['profile_pic'] as String?;
    
    // Initials logic
    String initials = name.isNotEmpty ? name[0].toUpperCase() : "U";
    if (name.contains(" ")) {
       final parts = name.split(" ");
       if (parts.length > 1 && parts[1].isNotEmpty) initials = "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }

    return material.Container(
      color: theme.colorScheme.background,
      child: material.SafeArea(
        child: Column(
          children: [
            // Custom Header with Menu Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  material.IconButton(
                    icon: Icon(LucideIcons.menu, color: theme.colorScheme.foreground),
                    onPressed: () => material.Scaffold.of(context).openDrawer(),
                  ),
                  const SizedBox(width: 8),
                  Text("Account", style: theme.typography.h4.copyWith(color: theme.colorScheme.foreground)),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     // Profile Card
                     Card(
                       child: Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: Row(
                          children: [
                            material.CircleAvatar(
                              radius: 32,
                              backgroundColor: material.Colors.transparent,
                              child: Container(
                                 width: 64,
                                 height: 64,
                                 decoration: material.BoxDecoration(
                                   shape: material.BoxShape.circle,
                                   color: photoUrl == null ? theme.colorScheme.muted : null,
                                   image: photoUrl != null ? material.DecorationImage(image: material.NetworkImage(photoUrl), fit: material.BoxFit.cover) : null,
                                   gradient: photoUrl == null ? UITheme.primaryGradient : null,
                                 ),
                                 alignment: material.Alignment.center,
                                 child: photoUrl == null 
                                   ? Text(initials, style: const material.TextStyle(color: material.Colors.white, fontSize: 20, fontWeight: material.FontWeight.bold))
                                   : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name).h4().foreground(), 
                                  const SizedBox(height: 2),
                                  Text(phone).muted().small(),
                                ],
                              ),
                            ),
                            material.IconButton(
                              onPressed: () {}, // Edit Profile
                              icon: Icon(LucideIcons.pencil, size: 16, color: theme.colorScheme.primary),
                            )
                          ],
                         ),
                       ),
                     ),
                     
                     const SizedBox(height: 16),
                     
                     // Favorites Section
                     Text("Favorites").small().muted(),
                     const SizedBox(height: 8),
                     Card(
                       padding: EdgeInsets.zero,
                       child: Column(
                         children: [
                           _buildListItem(context, icon: LucideIcons.mapPin, title: "Saved Places", onTap: () {}),
                           const Divider(),
                           _buildListItem(context, icon: LucideIcons.shieldCheck, title: "Trusted Contacts", onTap: () {}),
                         ],
                       ),
                     ),
                     
                     const SizedBox(height: 16),
                     
                     // Settings Section
                     Text("Settings").small().muted(),
                     const SizedBox(height: 8),
                     Card(
                       padding: EdgeInsets.zero,
                       child: Column(
                         children: [
                           _buildListItem(context, icon: LucideIcons.creditCard, title: "Payment Methods", onTap: () {}, enabled: false),
                           const Divider(),
                           _buildListItem(context, icon: LucideIcons.languages, title: "Language", trailing: "English", onTap: () {}, enabled: false),
                           const Divider(),
                           _buildListItem(context, icon: LucideIcons.lock, title: "Privacy", onTap: () {}, enabled: false),
                         ],
                       ),
                     ),

                     const SizedBox(height: 24),
                     
                     SizedBox(
                       width: double.infinity,
                       child: Button.ghost(
                          onPressed: () {
                             FirebaseAuth.instance.signOut();
                             context.go('/auth');
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                               Icon(LucideIcons.logOut, color: theme.colorScheme.destructive, size: 18),
                               const SizedBox(width: 8),
                               Text("Sign out", style: material.TextStyle(color: theme.colorScheme.destructive)),
                            ],
                          ),
                       ),
                     ),
                     
                     const SizedBox(height: 24),
                     Center(child: Text("Version 1.0.0").muted().small()),
                   ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, {
    required IconData icon, 
    required String title, 
    String? trailing, 
    required VoidCallback onTap,
    bool enabled = true
  }) {
     final theme = Theme.of(context);
     final opacity = enabled ? 1.0 : 0.5;
     
     return GestureDetector(
       onTap: enabled ? onTap : null,
       behavior: HitTestBehavior.opaque,
       child: Padding(
         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
         child: Opacity(
           opacity: opacity,
           child: Row(
             children: [
               Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: theme.colorScheme.primary.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Icon(icon, size: 18, color: theme.colorScheme.primary),
               ),
               const SizedBox(width: 12),
               Expanded(child: Text(title).medium().foreground()),
               if (trailing != null) ...[
                  Text(trailing).muted().small(),
                  const SizedBox(width: 8),
               ],
               if (enabled)
                Icon(LucideIcons.chevronRight, size: 16, color: theme.colorScheme.mutedForeground)
               else 
                const SizedBox(width: 16) // Placeholder for alignment or just empty
             ],
           ),
         ),
       ),
     );
  }
}
