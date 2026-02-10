import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF17223B); // Brand Navy
  static const Color primaryLight = Color(0xFF2E3B55);
  static const Color accent = Color(0xFFF2A644);  // Matching web gold
  static const Color error = Color(0xFFDE3C4B);   // Brand Red
  static const Color background = Color(0xFFF8F9FB);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGray = Color(0xFF6B7280);
  static const Color info = Color(0xFF1B84FF);
  static const Color success = Color(0xFF03C95A);
  
  static const List<Color> primaryGradient = [
    Color(0xFF17223B),
    Color(0xFF2E3B55),
  ];

  static const List<Color> chartColors = [
    Color(0xFFFFC107), // Yellow/Gold
    Color(0xFF3B7080), // Slate
    Color(0xFFE70D0D), // Red
    Color(0xFFFD3995), // Pink
    Color(0xFF03C95A), // Green
    Color(0xFF1B84FF), // Blue
    Color(0xFFAB47BC), // Purple
    Color(0xFFF26522), // Orange
    Color(0xFF212529), // Dark
  ];
}

class AppStyles {
  static const String fontFamily = 'Source Sans Pro';
  
  static final BoxDecoration modernCardDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static const TextStyle heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    letterSpacing: -0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textGray,
    height: 1.5,
  );
}
