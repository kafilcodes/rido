import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

class UITheme {
  static shadcn.ThemeData get shadcnLight {
    final base = shadcn.ThemeData(radius: 0.5);
    return base.copyWith(
      colorScheme: () => base.colorScheme.copyWith(
        primary: () => shadcn.Colors.indigo,
      ),
    );
  }

  static shadcn.ThemeData get shadcnDark {
    final base = shadcn.ThemeData.dark(radius: 0.5);
    return base.copyWith(
      colorScheme: () => base.colorScheme.copyWith(
        background: () => const material.Color(0xFF09090B), // Zinc 950
        foreground: () => const material.Color(0xFFFAFAFA), // Zinc 50
        primary: () => shadcn.Colors.indigo,
      ),
    );
  }
  
  // Helper for gradients
  static const material.LinearGradient primaryGradient = material.LinearGradient(
    colors: [material.Color(0xFF6366F1), material.Color(0xFFA855F7)], // Indigo to Purple
    begin: material.Alignment.topLeft,
    end: material.Alignment.bottomRight,
  );
}
