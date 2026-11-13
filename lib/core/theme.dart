import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Spendly design tokens shared by user, admin and super-admin experiences.
class AppColors {
  static const primary = Color(0xFF6366F1);
  static const secondary = Color(0xFF8B5CF6);
  static const accent = Color(0xFFEC4899);
  static const ink = Color(0xFF11164A);
  static const slate = Color(0xFF66708F);
  static const surface = Color(0xFFF6F7FF);
  static const border = Color(0xFFE5E8F5);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);
  static const white = Color(0xFFFFFFFF);
  static const heroGradient = LinearGradient(
    colors: [Color(0xFF3769F8), primary, secondary],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary, secondary: AppColors.secondary,
      surface: Colors.white, error: AppColors.danger,
      onPrimary: Colors.white, onSurface: AppColors.ink,
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: AppColors.ink, displayColor: AppColors.ink,
      ),
      primaryTextTheme: GoogleFonts.poppinsTextTheme(base.primaryTextTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface, foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent, elevation: 0, centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        hintStyle: const TextStyle(color: AppColors.slate),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.7)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.danger)),
      ),
      cardTheme: CardThemeData(color: Colors.white, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: AppColors.border))),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        elevation: 0, minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
      )),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      )),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.primary)),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        shape: CircleBorder(), elevation: 3,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: .13),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.slate,
        )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => GoogleFonts.poppins(
          fontSize: 11, fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.slate,
        )),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white, selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.slate, showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed, elevation: 8,
      ),
      tabBarTheme: const TabBarThemeData(labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.slate, indicatorColor: AppColors.primary,
        dividerColor: Colors.transparent),
      chipTheme: ChipThemeData(backgroundColor: Colors.white,
        selectedColor: AppColors.primary.withValues(alpha: .12),
        side: const BorderSide(color: AppColors.border), shape: shape),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      snackBarTheme: SnackBarThemeData(backgroundColor: AppColors.ink,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white),
        behavior: SnackBarBehavior.floating, shape: shape),
      dialogTheme: DialogThemeData(backgroundColor: Colors.white, shape: shape),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    );
  }
}
