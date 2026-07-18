import 'package:flutter/material.dart';

class AppColors {
  // Deep Space Purple Slate scheme
  static const Color slate50 = Color(0xFFF8F7FF);
  static const Color slate100 = Color(0xFFF1EEFD);
  static const Color slate200 = Color(0xFFE2DCF8);
  static const Color slate300 = Color(0xFFC5BBF0);
  static const Color slate400 = Color(0xFF9E8EE4);
  static const Color slate500 = Color(0xFF705EC5);
  static const Color slate600 = Color(0xFF4A3A9D);
  static const Color slate700 = Color(0xFF2E2270);
  static const Color slate800 = Color(0xFF17113C);
  static const Color slate850 = Color(0xFF110C2B);
  static const Color slate900 = Color(0xFF0B071E);
  
  // Glowing Neon Purple/Violet scheme
  static const Color indigoAccent = Color(0xFFC084FC); // Neon Purple
  static const Color indigoDefault = Color(0xFF8B5CF6); // Vibrant Purple
  static const Color indigoNeon = Color(0xFFA855F7); // Glowing Purple
  
  // Emerald scheme (success/resolved)
  static const Color emeraldDefault = Color(0xFF10B981);
  static const Color emeraldAccent = Color(0xFF34D399);

  // Purple accents (substituted for green highlights)
  static const Color green50 = Color(0xFFF5F3FF);
  static const Color green100 = Color(0xFFEDE9FE);
  static const Color green200 = Color(0xFFDDD6FE);
  static const Color green300 = Color(0xFFC7D2FE);
  static const Color green500 = Color(0xFF8B5CF6);
  static const Color green600 = Color(0xFF7C3AED);
  static const Color green700 = Color(0xFF6D28D9);

  // Semantic
  static const Color success = emeraldDefault;
  static const Color pending = Color(0xFFD946EF); // Neon Magenta
  static const Color inProgress = Color(0xFFF59E0B); // Amber
  static const Color open = Color(0xFF3B82F6); // Neon Blue
  static const Color critical = Color(0xFFEF4444); // Pulse Red
}
