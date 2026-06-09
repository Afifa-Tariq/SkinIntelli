import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color backgroundColor = Color(0xFFF3F7F1);
  static const Color sidebarColor = Color(0xFF2C4131);
  static const Color selectedMenuItemColor = Color(0xFF4B7D3F);
  static const Color primary = Color(0xFF4F6D44);
  static const Color accent = Color(0xFF32CD32);
  static const Color card = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF1F2A1F);
  static const Color mutedForeground = Color(0xFF6B7A6A);
  static const Color border = Color(0xFFE6EAE4);
  static const Color error = Color(0xFFD4183D);
}

class AppTheme {
  static const Color primary = AppColors.primary;
  static const Color accent = AppColors.accent;
  static const Color background = AppColors.backgroundColor;
  static const Color card = AppColors.card;

  // Update this value to your development machine's LAN IP when testing
  // on a physical device, e.g. '192.168.1.42'.
  static const String devMachineIp = '192.168.1.42';

  static String get backendBaseUrl {
    if (kIsWeb) return 'http://localhost:5000';

    if (kDebugMode) {
      if (devMachineIp != '192.168.1.x') {
        return 'http://$devMachineIp:5000';
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:5000';
      }
      debugPrint(
        'WARNING: AppTheme.devMachineIp is still set to the placeholder "192.168.1.x". '
        'On a physical device, 127.0.0.1 refers to the device itself, not your PC. '
        'Set devMachineIp to your PC LAN IP to connect to the backend.',
      );
    }
    return 'http://127.0.0.1:5000';
  }

  static const Color foreground = AppColors.foreground;
  static const Color mutedForeground = AppColors.mutedForeground;
  static const Color border = AppColors.border;
  static const Color error = AppColors.error;

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: accent,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
    fontFamily: GoogleFonts.poppins().fontFamily,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      floatingLabelStyle: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: AppColors.mutedForeground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: TextStyle(color: foreground, fontWeight: FontWeight.w500),
      hintStyle: TextStyle(color: mutedForeground),
    ),
  );
}
