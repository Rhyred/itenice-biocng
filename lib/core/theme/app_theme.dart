import 'package:flutter/material.dart';

/// Design tokens terpusat sesuai PRD §2 — NiceGas BioCNG
class AppTheme {
  AppTheme._();

  // ── Color tokens ──────────────────────────────────────────────
  /// Warna utama: Orange energetik
  static const Color primary = Color(0xFFE8650A);
  static const Color primaryLight = Color(0xFFFFF3EB);
  static const Color primaryDark = Color(0xFFBF4F04);

  static const Color background = Color(0xFFF7F4F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFEDE8E3);

  static const Color statusOptimal = Color(0xFF22C55E);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusCritical = Color(0xFFEF4444);

  static const Color textPrimary = Color(0xFF1C1A18);
  static const Color textSecondary = Color(0xFF8A8078);

  // ── Shape ─────────────────────────────────────────────────────
  static const double cardRadius = 16.0;

  // ── ThemeData ─────────────────────────────────────────────────
  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: surface,
      onSurface: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',

      // AppBar: flat, background sama dengan scaffold
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: textPrimary),
        actionsIconTheme: IconThemeData(color: textPrimary),
      ),

      // Card: flat, border tipis, radius 16
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: borderColor),
        ),
        margin: EdgeInsets.zero,
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0EDE8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: background,
        selectedColor: primary.withValues(alpha: 0.15),
        labelStyle: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
        side: const BorderSide(color: borderColor),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
