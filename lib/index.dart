import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:joker_state/joker_state.dart';

import 'core/theme/app_theme.dart';
import 'data/models/auth_session.dart';
import 'presentation/screens/login_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeJoker = Circus.spotlight<AppThemeMode>(tag: 'themeMode');

    return JokerPortal<AuthSession>(
      joker: Circus.summon<AuthSession>(
        const AuthSession(),
        tag: 'auth',
        keepAlive: true,
      ),
      // Wrap with JokerStage to listen for theme changes
      child: JokerStage<AppThemeMode>(
        // Pass the Joker<AppThemeMode> instance itself
        joker: themeJoker,
        builder: (context, currentThemeMode) {
          return MaterialApp(
            title: 'Auto NUEIP',
            theme: AppTheme.lightTheme, // Light theme data
            darkTheme: AppTheme.darkTheme, // Dark theme data
            themeMode: _getThemeMode(
              currentThemeMode,
            ), // Set mode from Joker state
            home: const KeyboardVisibilityProvider(child: LoginScreen()),
            debugShowCheckedModeBanner: false, // Optional: remove debug banner
          );
        },
      ),
    );
  }

  // Helper to map AppThemeMode to ThemeMode
  ThemeMode _getThemeMode(AppThemeMode appThemeMode) {
    switch (appThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
      // ignore: unreachable_switch_default
      default:
        return ThemeMode.system;
    }
  }
}
