import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:joker_state/joker_state.dart';

import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/notification.dart';
import '../presenters/setting_presenter.dart';

@RoutePage()
class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AutoRouter();
  }
}

@RoutePage()
class SettingMainScreen extends StatelessWidget {
  const SettingMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final presenter = Circus.find<SettingPresenter>();
    final themeJoker = Circus.find<Joker<AppThemeMode>>('themeMode');

    return Scaffold(
      appBar: AppBar(title: const Text('設定'), centerTitle: true, elevation: 1),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: context.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Gap(context.h(16)),
            // Profile Section
            _buildProfileSection(context, presenter)
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.2, end: 0, duration: 400.ms),

            Gap(context.h(24)),

            // Account Settings
            _buildSettingsSection(context, '帳號設定', [
                  _buildSettingTile(
                    context,
                    title: '編輯帳號資訊',
                    icon: Icons.person_outline,
                    onTap: () {
                      // Navigate to account editing screen
                      context.pushRoute(const ProfileEditingRoute()).then((_) {
                        presenter.getUserInfo();
                      });
                    },
                  ),
                  _buildSettingTile(
                    context,
                    title: '清除帳號資料',
                    icon: Icons.delete_outline,
                    onTap: () {
                      _showClearDataDialog(context, presenter);
                    },
                    isDestructive: true,
                  ),
                ])
                .animate()
                .fadeIn(duration: 700.ms)
                .slideY(begin: 0.2, end: 0, duration: 500.ms),

            Gap(context.h(16)),

            // App Settings
            _buildSettingsSection(context, 'APP 設定', [
                  // Dark mode switch
                  _buildSwitchTile(
                    context,
                    title: '深色模式',
                    icon: Icons.dark_mode_outlined,
                    value: themeJoker.state == AppThemeMode.dark,
                    onChanged: (value) {
                      // Update setting state
                      presenter.toggleDarkMode(value);
                      // Update theme mode
                      themeJoker.trick(
                        value ? AppThemeMode.dark : AppThemeMode.light,
                      );
                    },
                  ),

                  // Notification switch
                  presenter.perform(
                    builder: (context, state) {
                      return _buildSwitchTile(
                        context,
                        title: '開啟通知',
                        icon: Icons.notifications_outlined,
                        value: state.notificationsEnabled,
                        onChanged: (value) async {
                          if (value) {
                            // Try to request notification permissions
                            await _requestNotificationPermissions(
                              context,
                              presenter,
                            );
                          } else {
                            // Directly disable notifications
                            presenter.toggleNotifications(false);
                          }
                        },
                      );
                    },
                  ),
                ])
                .animate()
                .fadeIn(duration: 800.ms)
                .slideY(begin: 0.2, end: 0, duration: 600.ms),

            Gap(context.h(16)),

            // About Section
            _buildSettingsSection(context, '關於', [
                  _buildSettingTile(
                    context,
                    title: '開發者資訊',
                    icon: Icons.info_outline,
                    onTap: () {
                      context.pushRoute(const DeveloperInfoRoute());
                    },
                  ),
                  _buildSettingTile(
                    context,
                    title: '版本',
                    icon: Icons.android_outlined,
                    subtitle: 'v1.1.2',
                    onTap: null,
                  ),
                ])
                .animate()
                .fadeIn(duration: 900.ms)
                .slideY(begin: 0.2, end: 0, duration: 700.ms),

            Gap(context.h(40)),
          ],
        ),
      ),
    );
  }
}

Widget _buildProfileSection(BuildContext context, SettingPresenter presenter) {
  return presenter.perform(
    builder: (context, state) {
      final userInfo = state.userInfo; // Access the UserInfo object

      // Fallback values for display
      final String displayName = userInfo.userName ?? '使用者名稱';
      final String displayDept = userInfo.deptName ?? '部門資訊';
      final String displayCompany = userInfo.companyName ?? '公司資訊';

      return Center(
        child: SizedBox(
          width: double.infinity,
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.r(16)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: context.h(20),
                horizontal: context.w(16),
              ),
              child: Row(
                children: [
                  // Profile Image (using asset based on theme)
                  Circus.find<Joker<AppThemeMode>>('themeMode').perform(
                    builder: (context, themeMode) {
                      final isDarkMode = themeMode == AppThemeMode.dark;
                      return CircleAvatar(
                        radius: context.r(45),
                        backgroundColor:
                            context.colorScheme.surfaceContainerHighest,
                        backgroundImage: AssetImage(
                          isDarkMode
                              ? 'assets/images/logo_dark.png'
                              : 'assets/images/logo.png',
                        ),
                      );
                    },
                  ),
                  Gap(context.w(16)),
                  // User Info Text Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: context.sp(22),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Gap(context.h(4)),
                        Text(
                          displayDept,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                            fontSize: context.sp(14),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Gap(context.h(2)),
                        Text(
                          displayCompany,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.outline,
                            fontSize: context.sp(12),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

// Request notification permissions and update notification status
Future<void> _requestNotificationPermissions(
  BuildContext context,
  SettingPresenter presenter,
) async {
  // Initialize notification system and request permissions
  await NotificationUtils.init();

  // Try to send a test notification to check if permissions have been granted
  try {
    await NotificationUtils.showSimpleNotification(1000, '測試通知', '您已成功啟用通知功能！');
    // If successful, update setting state
    presenter.toggleNotifications(true);

    // Show success message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('通知功能已啟用', style: TextStyle(fontSize: context.sp(14))),
        ),
      );
    }
  } catch (e) {
    // If unable to send notification, permission denied
    debugPrint('Notification permission request failed: $e');
    presenter.toggleNotifications(false);

    // Show error message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '無法啟用通知功能，請在設定中允許通知權限',
            style: TextStyle(fontSize: context.sp(14)),
          ),
        ),
      );
    }
  }
}

Widget _buildSettingsSection(
  BuildContext context,
  String title,
  List<Widget> children,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.only(left: context.w(8), bottom: context.h(8)),
        child: Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colorScheme.primary,
            fontSize: context.sp(16),
          ),
        ),
      ),
      Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(16)),
        ),
        child: Column(children: children),
      ),
    ],
  );
}

Widget _buildSettingTile(
  BuildContext context, {
  required String title,
  required IconData icon,
  String? subtitle,
  required Function()? onTap,
  bool isDestructive = false,
}) {
  final color = isDestructive ? Colors.red : context.colorScheme.onSurface;

  return ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(color: color, fontSize: context.sp(16)),
        ),
        subtitle:
            subtitle != null
                ? Text(subtitle, style: TextStyle(fontSize: context.sp(14)))
                : null,
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(12)),
        ),
      )
      .animate()
      .fadeIn(duration: 300.ms)
      .then()
      .shimmer(delay: 200.ms, duration: 600.ms);
}

Widget _buildSwitchTile(
  BuildContext context, {
  required String title,
  required IconData icon,
  required bool value,
  required Function(bool) onChanged,
}) {
  return ListTile(
        leading: Icon(icon),
        title: Text(title, style: TextStyle(fontSize: context.sp(16))),
        trailing: Switch(value: value, onChanged: onChanged),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(12)),
        ),
      )
      .animate()
      .fadeIn(duration: 300.ms)
      .then()
      .shimmer(delay: 200.ms, duration: 600.ms);
}

void _showClearDataDialog(BuildContext context, SettingPresenter presenter) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('清除帳號資料', style: TextStyle(fontSize: context.sp(20))),
        content: Text(
          '您確定要清除帳號資料嗎？此操作無法復原。',
          style: TextStyle(fontSize: context.sp(16)),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('取消', style: TextStyle(fontSize: context.sp(14))),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await presenter.clearProflie();

              if (context.mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '帳號資料已清除',
                      style: TextStyle(fontSize: context.sp(14)),
                    ),
                  ),
                );
                context.router.replace(const LoginRoute());
              }
            },
            child: Text('清除', style: TextStyle(fontSize: context.sp(14))),
          ),
        ],
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
    },
  );
}
