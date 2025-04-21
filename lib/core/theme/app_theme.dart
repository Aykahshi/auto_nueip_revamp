import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Color Palette (Inspired by icon_android.png) ---

const Color _primaryColor = Color(0xFF26A69A); // Teal from inner circle/shadow
const Color _secondaryColor = Color(0xFF2196F3); // Blue from cloud
const Color _accentColor = Color(0xFFFFCA28); // Yellow from cloud
const Color _lightBackgroundColor = Color(
  0xFFE0F7FA,
); // Light cyan from highlights
const Color _darkSurfaceColor = Color(
  0xFF37474F,
); // Dark blue-grey from screen frame
const Color _lightTextColor = Color(0xFFFAFAFA); // Almost white
const Color _darkTextColor = Color(0xFF212121); // Very dark grey (almost black)

// --- App Theme Definition ---

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _primaryColor,
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      onPrimary: _lightTextColor, // Text on primary color
      secondary: _secondaryColor,
      onSecondary: _lightTextColor, // Text on secondary color
      tertiary: _accentColor,
      onTertiary: _darkTextColor, // Text on accent color
      error: Colors.redAccent,
      onError: _lightTextColor,
      surface: _lightBackgroundColor, // Card, Dialog backgrounds
      onSurface: _darkTextColor, // Text on surface
      outline: _primaryColor, // Input field borders etc.
    ),
    scaffoldBackgroundColor: _lightBackgroundColor,
    appBarTheme: const AppBarTheme(
      color: _primaryColor,
      foregroundColor: _lightTextColor, // Title and icon color
      elevation: 1.0,
      titleTextStyle: TextStyle(
        // Ensure font family is applied if default textTheme doesn't cover it
        // fontFamily: GoogleFonts.notoSansTc().fontFamily, // Uncomment if needed
        fontSize: 20.0,
        fontWeight: FontWeight.w500,
      ),
      iconTheme: IconThemeData(color: _lightTextColor),
    ),
    textTheme: _buildTextTheme(
      GoogleFonts.notoSansTcTextTheme(),
    ), // Base TextTheme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor, // Button background
        foregroundColor: _lightTextColor, // Button text/icon color
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withAlpha(204),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _primaryColor, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: _primaryColor.withAlpha(153), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _secondaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
      ),
      labelStyle: const TextStyle(color: _darkSurfaceColor),
      floatingLabelStyle: const TextStyle(color: _secondaryColor),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: _secondaryColor,
      selectionColor: _secondaryColor.withAlpha(77),
      selectionHandleColor: _secondaryColor,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: true,
  );

  // Helper to apply dark text color to the base theme
  static TextTheme _buildTextTheme(TextTheme base) {
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(color: _darkTextColor),
          displayMedium: base.displayMedium?.copyWith(color: _darkTextColor),
          displaySmall: base.displaySmall?.copyWith(color: _darkTextColor),
          headlineLarge: base.headlineLarge?.copyWith(color: _darkTextColor),
          headlineMedium: base.headlineMedium?.copyWith(color: _darkTextColor),
          headlineSmall: base.headlineSmall?.copyWith(color: _darkTextColor),
          titleLarge: base.titleLarge?.copyWith(color: _darkTextColor),
          titleMedium: base.titleMedium?.copyWith(color: _darkTextColor),
          titleSmall: base.titleSmall?.copyWith(color: _darkTextColor),
          bodyLarge: base.bodyLarge?.copyWith(color: _darkTextColor),
          bodyMedium: base.bodyMedium?.copyWith(color: _darkTextColor),
          bodySmall: base.bodySmall?.copyWith(color: _darkTextColor),
          labelLarge: base.labelLarge?.copyWith(
            color: _darkTextColor,
          ), // Used for buttons
          labelMedium: base.labelMedium?.copyWith(color: _darkTextColor),
          labelSmall: base.labelSmall?.copyWith(color: _darkTextColor),
        )
        .apply();
  }
}
