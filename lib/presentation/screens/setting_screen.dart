import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:joker_state/joker_state.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/local_storage.dart';
import '../../core/utils/notification.dart';
import '../presenters/setting_presenter.dart';

@RoutePage()
class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late SettingPresenter _presenter;

  @override
  void initState() {
    super.initState();
    _presenter = Circus.hire<SettingPresenter>(SettingPresenter());
  }

  @override
  Widget build(BuildContext context) {
    final themeJoker = context.joker<AppThemeMode>();

    return Scaffold(
      appBar: AppBar(title: const Text('設定'), centerTitle: true, elevation: 1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(16),
            // Profile Section
            _buildProfileSection(context, _presenter)
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.2, end: 0, duration: 400.ms),

            const Gap(24),

            // Account Settings
            _buildSettingsSection(context, '帳號設定', [
                  _buildSettingTile(
                    context,
                    title: '編輯帳號資訊',
                    icon: Icons.person_outline,
                    onTap: () {
                      // Navigate to account editing screen
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('編輯帳號資訊 ')));
                    },
                  ),
                  _buildSettingTile(
                    context,
                    title: '清除帳號資料',
                    icon: Icons.delete_outline,
                    onTap: () {
                      _showClearDataDialog(context);
                    },
                    isDestructive: true,
                  ),
                ])
                .animate()
                .fadeIn(duration: 700.ms)
                .slideY(begin: 0.2, end: 0, duration: 500.ms),

            const Gap(16),

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
                      _presenter.toggleDarkMode(value);
                      // Update theme mode
                      themeJoker.trick(
                        value ? AppThemeMode.dark : AppThemeMode.light,
                      );
                    },
                  ),

                  // Notification switch
                  _presenter.perform(
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
                              _presenter,
                            );
                          } else {
                            // Directly disable notifications
                            _presenter.toggleNotifications(false);
                          }
                        },
                      );
                    },
                  ),
                ])
                .animate()
                .fadeIn(duration: 800.ms)
                .slideY(begin: 0.2, end: 0, duration: 600.ms),

            const Gap(16),

            // About Section
            _buildSettingsSection(context, '關於', [
                  _buildSettingTile(
                    context,
                    title: '開發者資訊',
                    icon: Icons.info_outline,
                    onTap: () {
                      _showDeveloperInfo(context);
                    },
                  ),
                  _buildSettingTile(
                    context,
                    title: '版本',
                    icon: Icons.android_outlined,
                    subtitle: 'v1.0.0',
                    onTap: null,
                  ),
                ])
                .animate()
                .fadeIn(duration: 900.ms)
                .slideY(begin: 0.2, end: 0, duration: 700.ms),

            const Gap(40),
          ],
        ),
      ),
    );
  }
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('通知功能已啟用')));
    }
  } catch (e) {
    // If unable to send notification, permission denied
    debugPrint('Notification permission request failed: $e');
    presenter.toggleNotifications(false);

    // Show error message
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('無法啟用通知功能，請在設定中允許通知權限')));
    }
  }
}

Widget _buildProfileSection(BuildContext context, SettingPresenter presenter) {
  return presenter.perform(
    builder: (context, state) {
      // Create a joker for editing state
      final editingJoker = Joker<bool>(false);

      // Create a text controller that updates when username changes
      final TextEditingController usernameController = TextEditingController(
        text: state.username,
      );

      // Function to handle save action
      void saveUsername() {
        if (usernameController.text.isNotEmpty) {
          presenter.updateUsername(usernameController.text);
          editingJoker.trick(false);
        }
      }

      return usernameController.trapeze(
        Center(
          child: SizedBox(
            width: double.infinity,
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Profile Image
                    JokerCast<AppThemeMode>(
                      builder: (context, themeMode) {
                        final isDarkMode = themeMode == AppThemeMode.dark;

                        return CircleAvatar(
                              radius: 50,
                              backgroundImage: AssetImage(
                                isDarkMode
                                    ? 'assets/images/logo_dark.png'
                                    : 'assets/images/logo.png',
                              ),
                            )
                            .animate()
                            .scale(duration: 300.ms, curve: Curves.easeOut)
                            .then()
                            .shimmer(duration: 1200.ms);
                      },
                    ),
                    const Gap(16),

                    // Username section with editable text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Editable Username
                          editingJoker.perform(
                            builder: (context, isEditing) {
                              return Row(
                                children: [
                                  Expanded(
                                    child:
                                        isEditing
                                            ? TextField(
                                              controller: usernameController,
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.titleLarge,
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                              ),
                                              autofocus: true,
                                            )
                                            : Text(
                                              state.username,
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.titleLarge,
                                            ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    iconSize: 20,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      isEditing ? Icons.save : Icons.edit,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                    ),
                                    onPressed: () {
                                      if (isEditing) {
                                        saveUsername();
                                      } else {
                                        editingJoker.trick(true);
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
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
        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
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
  final colorScheme = Theme.of(context).colorScheme;
  final color = isDestructive ? Colors.red : colorScheme.onSurface;

  return ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        title: Text(title),
        trailing: Switch(value: value, onChanged: onChanged),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )
      .animate()
      .fadeIn(duration: 300.ms)
      .then()
      .shimmer(delay: 200.ms, duration: 600.ms);
}

void _showClearDataDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('清除帳號資料'),
        content: const Text('您確定要清除帳號資料嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              // Implement clear data logic
              await LocalStorage.clear();
              if (context.mounted) {
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('帳號資料已清除')));
                }
              }
            },
            child: const Text('清除'),
          ),
        ],
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
    },
  );
}

void _showDeveloperInfo(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('開發者資訊'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('開發者: Auto NuEIP 團隊'),
            SizedBox(height: 8),
            Text('電子郵件: support@example.com'),
            SizedBox(height: 8),
            Text('網站: https://example.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
    },
  );
}
