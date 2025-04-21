import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Enum representing the available theme modes.
enum AppThemeMode { light, dark, system }

// --- Light Theme Color Palette ---
const Color _primaryLight = Color(0xFF26A69A); // Teal
const Color _secondaryLight = Color(0xFF2196F3); // Blue
const Color _accentLight = Color(0xFFFFCA28); // Yellow
const Color _backgroundLight = Color(0xFFE0F7FA); // Light Cyan
const Color _surfaceLight = Colors.white;
const Color _textOnLight = Color(0xFF212121); // Dark Grey
const Color _textOnPrimaryLight = Colors.white;

// --- Dark Theme Color Palette ---
const Color _primaryDark = Color(0xFF4DB6AC); // Lighter Teal for Dark
const Color _secondaryDark = Color(0xFF64B5F6); // Lighter Blue for Dark
const Color _accentDark = Color(0xFFFFD54F); // Slightly Lighter Yellow
const Color _backgroundDark = Color(0xFF121212); // Very Dark Grey
const Color _surfaceDark = Color(0xFF1E1E1E); // Slightly lighter dark grey
const Color _textOnDark = Color(0xFFE0E0E0); // Light Grey
const Color _textOnPrimaryDark = Color(
  0xFF000000,
); // Black text on Lighter Teal
const Color _errorDark = Color(0xFFCF6679); // Material Dark Error
const Color _errorLight = Colors.redAccent;

// --- App Theme Definition ---

class AppTheme {
  // --- Light Theme ---
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _primaryLight,
    colorScheme: const ColorScheme.light(
      primary: _primaryLight,
      onPrimary: _textOnPrimaryLight,
      secondary: _secondaryLight,
      onSecondary: _textOnPrimaryLight,
      tertiary: _accentLight,
      onTertiary: _textOnLight, // Dark text on Yellow
      error: _errorLight,
      onError: _textOnPrimaryLight,
      surface: _surfaceLight,
      onSurface: _textOnLight,
      outline: _primaryLight,
    ),
    scaffoldBackgroundColor: _backgroundLight,
    appBarTheme: const AppBarTheme(
      color: _primaryLight,
      foregroundColor: _textOnPrimaryLight,
      elevation: 1.0,
      titleTextStyle: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w500,
        color: _textOnPrimaryLight, // Explicitly set color
      ),
      iconTheme: IconThemeData(color: _textOnPrimaryLight),
    ),
    textTheme: _buildTextTheme(GoogleFonts.notoSansTcTextTheme(), _textOnLight),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryLight,
        foregroundColor: _textOnPrimaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceLight.withAlpha(204),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _primaryLight, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: _primaryLight.withAlpha(153), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _secondaryLight, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _errorLight, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _errorLight, width: 2.0),
      ),
      labelStyle: TextStyle(color: _textOnLight.withAlpha(77)),
      floatingLabelStyle: const TextStyle(color: _secondaryLight),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: _secondaryLight,
      selectionColor: _secondaryLight.withAlpha(77),
      selectionHandleColor: _secondaryLight,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: true,
  );

  // --- Dark Theme ---
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _primaryDark,
    colorScheme: const ColorScheme.dark(
      primary: _primaryDark,
      onPrimary: _textOnPrimaryDark, // Black text on Lighter Teal
      secondary: _secondaryDark,
      onSecondary: _textOnPrimaryDark, // Black text on Lighter Blue
      tertiary: _accentDark,
      onTertiary: _textOnLight, // Dark Grey text on Lighter Yellow
      error: _errorDark,
      onError: _textOnPrimaryDark, // Black text on Dark Error Red
      surface: _surfaceDark,
      onSurface: _textOnDark,
      outline: _primaryDark,
    ),
    scaffoldBackgroundColor: _backgroundDark,
    appBarTheme: const AppBarTheme(
      color: _surfaceDark, // Use surface color for dark AppBar
      foregroundColor: _textOnDark,
      elevation: 1.0,
      titleTextStyle: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w500,
        color: _textOnDark, // Explicitly set color
      ),
      iconTheme: IconThemeData(color: _textOnDark),
    ),
    textTheme: _buildTextTheme(GoogleFonts.notoSansTcTextTheme(), _textOnDark),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryDark,
        foregroundColor: _textOnPrimaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceDark.withAlpha(150), // Darker fill
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _primaryDark, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: _primaryDark.withAlpha(153), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _secondaryDark, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _errorDark, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _errorDark, width: 2.0),
      ),
      labelStyle: TextStyle(color: _textOnDark.withAlpha(77)),
      floatingLabelStyle: const TextStyle(color: _secondaryDark),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: _secondaryDark,
      selectionColor: _secondaryDark.withAlpha(77),
      selectionHandleColor: _secondaryDark,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: true,
  );

  // Helper to apply default text color to the base theme
  static TextTheme _buildTextTheme(TextTheme base, Color defaultTextColor) {
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(color: defaultTextColor),
          displayMedium: base.displayMedium?.copyWith(color: defaultTextColor),
          displaySmall: base.displaySmall?.copyWith(color: defaultTextColor),
          headlineLarge: base.headlineLarge?.copyWith(color: defaultTextColor),
          headlineMedium: base.headlineMedium?.copyWith(
            color: defaultTextColor,
          ),
          headlineSmall: base.headlineSmall?.copyWith(color: defaultTextColor),
          titleLarge: base.titleLarge?.copyWith(color: defaultTextColor),
          titleMedium: base.titleMedium?.copyWith(color: defaultTextColor),
          titleSmall: base.titleSmall?.copyWith(color: defaultTextColor),
          bodyLarge: base.bodyLarge?.copyWith(color: defaultTextColor),
          bodyMedium: base.bodyMedium?.copyWith(color: defaultTextColor),
          bodySmall: base.bodySmall?.copyWith(color: defaultTextColor),
          labelLarge: base.labelLarge?.copyWith(
            color: defaultTextColor,
          ), // Buttons etc.
          labelMedium: base.labelMedium?.copyWith(color: defaultTextColor),
          labelSmall: base.labelSmall?.copyWith(color: defaultTextColor),
        )
        .apply(); // apply() is often redundant if using copyWith for color
  }
}
