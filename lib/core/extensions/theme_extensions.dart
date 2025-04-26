import 'package:flutter/material.dart';

/// Extension on [BuildContext] to provide quick access to theme properties.
extension ThemeContextExtension on BuildContext {
  /// Returns the current [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// Returns the current [ColorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Returns the current [TextTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Returns `true` if the current theme brightness is [Brightness.dark].
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
