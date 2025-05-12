import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:joker_state/joker_state.dart';

import 'core/config/storage_keys.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/local_storage.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeJoker = Circus.spotlight<AppThemeMode>(tag: 'themeMode');

    final isDarkMode = LocalStorage.get<bool>(
      StorageKeys.darkModeEnabled,
      defaultValue: false,
    );

    if (isDarkMode) {
      themeJoker.trick(AppThemeMode.dark);
    }

    final router = Circus.find<AppRouter>();

    return ScreenUtil(
      options: const ScreenUtilOptions(
        designSize: Size(393, 852),
        paddingScaleStrategy: ScreenUtilScaleStrategy.both,
      ),
      child: JokerPortal<AppThemeMode>(
        joker: themeJoker,
        child: JokerCast<AppThemeMode>(
          builder: (context, currentThemeMode) {
            return _AnimatedThemeApp(
              themeMode: _getThemeMode(currentThemeMode),
              router: router,
            );
          },
        ),
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

class _AnimatedThemeApp extends StatefulWidget {
  final ThemeMode themeMode;
  final AppRouter router;

  const _AnimatedThemeApp({required this.themeMode, required this.router});

  @override
  State<_AnimatedThemeApp> createState() => _AnimatedThemeAppState();
}

class _AnimatedThemeAppState extends State<_AnimatedThemeApp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(_AnimatedThemeApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.themeMode != oldWidget.themeMode) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: ColorTween(
        begin:
            widget.themeMode == ThemeMode.dark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.2),
        end:
            widget.themeMode == ThemeMode.dark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.2),
      ),
      duration: const Duration(milliseconds: 600),
      builder: (context, color, child) {
        return AnimatedTheme(
          data:
              widget.themeMode == ThemeMode.dark
                  ? AppTheme.darkTheme
                  : AppTheme.lightTheme,
          duration: const Duration(milliseconds: 600),
          child: MediaQuery.withNoTextScaling(
            child: MaterialApp.router(
              title: 'Auto NUEIP',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: widget.themeMode,
              locale: const Locale('zh', 'TW'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('zh', 'TW')],
              debugShowCheckedModeBanner: false,
              routerConfig: widget.router.config(),
            ),
          ),
        );
      },
    );
  }
}
