import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../../core/router/app_router.dart';

@RoutePage()
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    // Define specific selected colors for dark mode
    const Color homeSelectedDark = Color(
      0xFFD8A964,
    ); // Muted Orange (_secondaryDark)
    const Color calendarSelectedDark = Color(
      0xFFE0E0E0,
    ); // Light Grey (_textOnDark)
    const Color leaveSelectedDark = Color(
      0xFF4A7C82,
    ); // Dark Teal (_tertiaryDark)
    const Color settingsSelectedDark = Color(
      0xFF3A5F84,
    ); // Muted Blue (_primaryDark)

    return AutoTabsScaffold(
      routes: const [
        HomeRoute(),
        CalendarRoute(),
        LeaveRoute(),
        SettingRoute(),
      ],
      backgroundColor: colorScheme.surface,
      bottomNavigationBuilder: (_, tabsRouter) {
        return SalomonBottomBar(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          // Use theme surface color for background
          backgroundColor: colorScheme.surface.withValues(
            alpha: isDarkMode ? 0.95 : 0.9,
          ),
          currentIndex: tabsRouter.activeIndex,
          onTap: tabsRouter.setActiveIndex,
          // Use theme onSurface color for unselected items
          unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
          items: [
            /// Home
            SalomonBottomBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              title: const Text("首頁"),
              selectedColor:
                  isDarkMode
                      ? homeSelectedDark // Specific dark color
                      : colorScheme.primary, // Light theme primary
            ),

            /// Calendar
            SalomonBottomBarItem(
              icon: const Icon(Icons.calendar_today_outlined),
              activeIcon: const Icon(Icons.calendar_today),
              title: const Text("日曆"),
              selectedColor:
                  isDarkMode
                      ? calendarSelectedDark // Specific dark color
                      : colorScheme.secondary, // Light theme secondary
            ),

            /// Leave
            SalomonBottomBarItem(
              icon: const Icon(Icons.logout_outlined),
              activeIcon: const Icon(Icons.logout),
              title: const Text("請假"),
              selectedColor:
                  isDarkMode
                      ? leaveSelectedDark // Specific dark color
                      : colorScheme.tertiary, // Light theme tertiary
            ),

            /// Settings
            SalomonBottomBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              title: const Text("設定"),
              selectedColor:
                  isDarkMode
                      ? settingsSelectedDark // Specific dark color
                      : colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ), // Light theme primary
            ),
          ],
        );
      },
    );
  }
}
