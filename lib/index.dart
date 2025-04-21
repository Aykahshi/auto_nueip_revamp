import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:joker_state/joker_state.dart';

import 'core/theme/app_theme.dart';
import 'data/models/auth_session.dart';
import 'presentation/screens/login_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return JokerPortal<AuthSession>(
      joker: Circus.summon<AuthSession>(
        const AuthSession(),
        tag: 'auth',
        keepAlive: true,
      ),
      child: MaterialApp(
        title: 'Auto NUEIP',
        theme: AppTheme.lightTheme,
        home: const KeyboardVisibilityProvider(child: LoginScreen()),
      ),
    );
  }
}
