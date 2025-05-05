import 'dart:io' show Platform;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/router/app_router.dart';

@RoutePage()
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define specific selected colors for dark mode
    const Color homeSelectedDark = Color(0xFFD8A964);
    const Color calendarSelectedDark = Color(0xFFE0E0E0);
    const Color leaveSelectedDark = Color(0xFF4A7C82);
    const Color settingsSelectedDark = Color(0xFF3A5F84);

    return AutoTabsScaffold(
      routes: const [HomeRoute(), CalendarRoute(), FormRoute(), SettingRoute()],
      backgroundColor: context.colorScheme.surface,
      bottomNavigationBuilder: (_, tabsRouter) {
        return SalomonBottomBar(
          margin: EdgeInsets.symmetric(
            horizontal: context.w(20),
            vertical: context.h(8),
          ),
          // Use theme surface color for background
          backgroundColor: context.colorScheme.surface.withValues(
            alpha: context.isDarkMode ? 0.95 : 0.9,
          ),
          itemPadding: EdgeInsets.symmetric(
            horizontal: context.w(16),
            vertical: context.h(12),
          ),
          currentIndex: tabsRouter.activeIndex,
          onTap: tabsRouter.setActiveIndex,
          // Use theme onSurface color for unselected items
          unselectedItemColor: context.colorScheme.onSurface.withValues(
            alpha: 0.6,
          ),
          items: [
            /// Home
            SalomonBottomBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              title: Padding(
                padding: EdgeInsets.only(
                  bottom: context.h(Platform.isAndroid ? 2 : 0),
                ),
                child: const Text("首頁"),
              ),
              selectedColor:
                  context.isDarkMode
                      ? homeSelectedDark
                      : context.colorScheme.primary,
            ),

            /// Calendar
            SalomonBottomBarItem(
              icon: const Icon(Icons.calendar_today_outlined),
              activeIcon: const Icon(Icons.calendar_today),
              title: Padding(
                padding: EdgeInsets.only(
                  bottom: context.h(Platform.isAndroid ? 2 : 0),
                ),
                child: const Text("日曆"),
              ),
              selectedColor:
                  context.isDarkMode
                      ? calendarSelectedDark
                      : context.colorScheme.secondary,
            ),

            /// Forms (Previously Leave)
            SalomonBottomBarItem(
              icon: const Icon(Icons.description_outlined),
              activeIcon: const Icon(Icons.description),
              title: Padding(
                padding: EdgeInsets.only(
                  bottom: context.h(Platform.isAndroid ? 2 : 0),
                ),
                child: const Text("表單"),
              ),
              selectedColor:
                  context.isDarkMode
                      ? leaveSelectedDark
                      : context.colorScheme.tertiary,
            ),

            /// Settings
            SalomonBottomBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              title: Padding(
                padding: EdgeInsets.only(
                  bottom: context.h(Platform.isAndroid ? 2 : 0),
                ),
                child: const Text("設定"),
              ),
              selectedColor:
                  context.isDarkMode
                      ? settingsSelectedDark
                      : context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ],
        );
      },
    );
  }
}
