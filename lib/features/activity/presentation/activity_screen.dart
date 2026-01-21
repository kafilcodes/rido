import 'package:flutter/material.dart' as material;
import 'package:lottie/lottie.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ActivityScreen extends material.StatelessWidget {
  const ActivityScreen({super.key});

  @override
  @override
  material.Widget build(material.BuildContext context) {
    // Resolve Theme conflict - Use Shadcn Theme
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Resolve Colors conflict
    final textColor = theme.colorScheme.foreground;
    final subtitleColor = theme.colorScheme.mutedForeground;

    return material.Container(
      color: theme.colorScheme.background,
      child: material.SafeArea(
        child: material.Column(
          children: [
             material.Padding(
              padding: const material.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: material.Row(
                children: [
                  material.IconButton(
                    icon: material.Icon(LucideIcons.menu, color: theme.colorScheme.foreground),
                    onPressed: () => material.Scaffold.of(context).openDrawer(),
                  ),
                  const material.SizedBox(width: 8),
                  material.Text("Recent Activity", style: theme.typography.h4.copyWith(color: theme.colorScheme.foreground)),
                ],
              ),
            ),
            material.Expanded(
              child: material.Center(
                child: material.Column(
                  mainAxisAlignment: material.MainAxisAlignment.center,
                  children: [
                    // Lottie with Icon fallback
                    Lottie.asset(
                       'assets/lottie/empty_activity.json',
                       width: 200,
                       height: 200,
                       errorBuilder: (c, e, s) => const material.Icon(LucideIcons.history, size: 64, color: material.Colors.grey),
                    ),
                    const material.SizedBox(height: 16),
                    material.Text("No recent rides", style: material.TextStyle(fontSize: 18, fontWeight: material.FontWeight.bold, color: textColor)),
                    const material.SizedBox(height: 8),
                    material.Text("Your completed trips will appear here.", style: material.TextStyle(color: subtitleColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
