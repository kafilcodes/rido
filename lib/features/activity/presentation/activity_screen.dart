import 'package:flutter/material.dart';

class ActivityScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const ActivityScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey[600];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Recent Activity"),
        automaticallyImplyLeading: false,
        leading: onBack != null ? IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: onBack,
        ) : null,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text("No recent rides", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Text("Your completed trips will appear here.", style: TextStyle(color: subtitleColor)),
          ],
        ),
      ),
    );
  }
}
