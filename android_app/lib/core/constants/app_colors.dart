import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryLight = Color(0xFF5B9BF8);
  static const Color primaryDark = Color(0xFF0D47A1);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF34A853);
  static const Color secondaryLight = Color(0xFF81C995);
  static const Color secondaryDark = Color(0xFF1B8E4E);
  
  // Accent Colors
  static const Color accent = Color(0xFFEA4335);
  static const Color accentLight = Color(0xFFF28482);
  static const Color warning = Color(0xFFFBBC04);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey100 = Color(0xFFF7F7F7);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey900 = Color(0xFF212121);
  
  // Status Colors
  static const Color success = Color(0xFF34A853);
  static const Color error = Color(0xFFEA4335);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warning2 = Color(0xFFFBBC04);
  static const Color info = Color(0xFF1A73E8);
  
  // Transparent
  static const Color transparent = Color(0x00000000);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );
}
