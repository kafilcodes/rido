import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sizer/sizer.dart';

class AccountScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AccountScreen({super.key, this.onBack});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  User? _user;
  Map<String, dynamic>? _userData;

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
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    
    final name = _userData?['name'] as String? ?? _user?.displayName ?? "User Name";
    final phone = _userData?['phone'] as String? ?? _user?.phoneNumber ?? "";
    final photoUrl = _userData?['profile_pic'] as String?;
    final city = _userData?['city'] as String?;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Account"),
        automaticallyImplyLeading: false, 
        leading: widget.onBack != null ? IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: widget.onBack,
        ) : null,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // Profile Header
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: (photoUrl == null || photoUrl.isEmpty) 
                      ? const Icon(Icons.person, size: 35, color: Colors.grey) 
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                      ),
                      if (city != null)
                      Text(
                        city,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                   onPressed: () => context.push('/profile-form'), 
                   icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                )
              ],
            ),
            
            const SizedBox(height: 32),

            // Menu Grid / List
            _buildSectionHeader(context, "Favorites"),
            _buildMenuItem(context, "Saved Places", Icons.place, onTap: () {}),
            _buildMenuItem(context, "Trusted Contacts", Icons.security, onTap: () {}),

            const SizedBox(height: 24),
            _buildSectionHeader(context, "Settings"),
            _buildMenuItem(context, "Notifications", Icons.notifications_none, onTap: () {}),
            _buildMenuItem(context, "Privacy", Icons.lock_outline, onTap: () {}),
            _buildMenuItem(context, "Payments", Icons.payment, onTap: () {}),
            
            const SizedBox(height: 24),
            _buildMenuItem(
              context, 
              "Logout", 
              Icons.logout, 
              onTap: () {
                 FirebaseAuth.instance.signOut();
                 context.go('/auth');
              },
              isDestructive: true,
            ),
            
            const SizedBox(height: 40),
            Text(
              "v1.0.0",
              style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title, 
          style: TextStyle(
            fontSize: 16.sp, 
            fontWeight: FontWeight.bold, 
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87
          )
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, {required VoidCallback onTap, bool isDestructive = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red.withOpacity(0.1) : (isDark ? Colors.black : Colors.white),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon, 
            size: 20, 
            color: isDestructive ? Colors.red : (isDark ? Colors.white : Colors.black)
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : (isDark ? Colors.white : Colors.black),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      ),
    );
  }
}
