import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:joker_state/joker_state.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/config/storage_keys.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/utils/auth_utils.dart';
import '../../../../core/utils/local_storage.dart';
import '../../../nueip/domain/repositories/nueip_repository.dart';
import '../../data/models/user_info.dart';
import '../../domain/entities/setting_state.dart';

final class SettingPresenter extends Presenter<SettingState> {
  final NueipRepository _repository;

  SettingPresenter({super.keepAlive = true})
    : _repository = Circus.find<NueipRepository>(),
      super(SettingState.initial());

  @override
  void onReady() async {
    super.onReady();
    await _setDefaultToggle();
    await getUserInfo();
    await getAppVersion();
  }

  Future<void> _setDefaultToggle() async {
    final storedNotificationState = LocalStorage.get<bool>(
      StorageKeys.notificationsEnabled,
      defaultValue: false,
    );

    final actualNotificationState = await checkNotificationPermission();

    final notificationEnabled =
        storedNotificationState && actualNotificationState;

    if (storedNotificationState != notificationEnabled) {
      LocalStorage.set(StorageKeys.notificationsEnabled, notificationEnabled);
    }

    // Load clock reminder settings
    final clockReminderEnabled = LocalStorage.get<bool>(
      StorageKeys.clockReminderEnabled,
      defaultValue: false,
    );

    final morningHour = LocalStorage.get<int>(
      StorageKeys.morningReminderHour,
      defaultValue: 9,
    );

    final morningMinute = LocalStorage.get<int>(
      StorageKeys.morningReminderMinute,
      defaultValue: 0,
    );

    final eveningHour = LocalStorage.get<int>(
      StorageKeys.eveningReminderHour,
      defaultValue: 18,
    );

    final eveningMinute = LocalStorage.get<int>(
      StorageKeys.eveningReminderMinute,
      defaultValue: 0,
    );

    trickWith(
      (state) => state.copyWith(
        notificationsEnabled: notificationEnabled,
        darkModeEnabled: LocalStorage.get<bool>(
          StorageKeys.darkModeEnabled,
          defaultValue: false,
        ),
        clockReminderEnabled: clockReminderEnabled,
        morningReminderTime: TimeOfDay(hour: morningHour, minute: morningMinute),
        eveningReminderTime: TimeOfDay(hour: eveningHour, minute: eveningMinute),
      ),
    );

    // Schedule reminders if enabled
    if (clockReminderEnabled && notificationEnabled) {
      await scheduleClockReminders();
    }
  }

  Future<bool> checkNotificationPermission() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final androidImplementation = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final granted = await androidImplementation.areNotificationsEnabled();
        return granted ?? false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = 'v${packageInfo.version}';
      trickWith((state) => state.copyWith(appVersion: version));
    } catch (e) {
      trickWith((state) => state.copyWith(appVersion: 'v.DEV'));
    }
  }

  Future<void> clearProflie() async {
    await AuthUtils.resetAuthSession();
    await AuthUtils.clearCredentials();
    trickWith((state) => state.copyWith(error: null));
  }

  Future<void> getUserInfo() async {
    final result = await _repository.getUserInfo().run();

    result.fold(
      (failure) => trickWith((state) => state.copyWith(error: failure)),
      (response) {
        final jsonData = response.data as Map<String, dynamic>;
        final userInfo = UserInfo.fromJson(jsonData['data']);
        trickWith((state) => state.copyWith(userInfo: userInfo));
      },
    );
  }

  void toggleNotifications(bool value) {
    trickWith((state) => state.copyWith(notificationsEnabled: value));
    LocalStorage.set(StorageKeys.notificationsEnabled, value);
    
    // If notifications are disabled, also disable clock reminders
    if (!value && state.clockReminderEnabled) {
      cancelClockReminders();
    } else if (value && state.clockReminderEnabled) {
      // If notifications are enabled and clock reminder was already on, reschedule
      scheduleClockReminders();
    }
  }

  void toggleDarkMode(bool value) {
    trickWith((state) => state.copyWith(darkModeEnabled: value));
    LocalStorage.set(StorageKeys.darkModeEnabled, value);
  }

  Future<void> refresh() async {
    try {
      await getUserInfo();
      await getAppVersion();
      await _setDefaultToggle();
    } catch (e) {
      trickWith(
        (state) => state.copyWith(
          error: Failure(message: '刷新失敗: $e', status: 'error'),
        ),
      );
    }
  }

  // Clock reminder methods
  Future<void> toggleClockReminder(bool value) async {
    await LocalStorage.set(StorageKeys.clockReminderEnabled, value);
    trickWith((state) => state.copyWith(clockReminderEnabled: value));

    if (value && state.notificationsEnabled) {
      await scheduleClockReminders();
    } else {
      await cancelClockReminders();
    }
  }

  Future<void> setMorningReminderTime(TimeOfDay time) async {
    await LocalStorage.set(StorageKeys.morningReminderHour, time.hour);
    await LocalStorage.set(StorageKeys.morningReminderMinute, time.minute);
    trickWith((state) => state.copyWith(morningReminderTime: time));

    if (state.clockReminderEnabled && state.notificationsEnabled) {
      await scheduleClockReminders();
    }
  }

  Future<void> setEveningReminderTime(TimeOfDay time) async {
    await LocalStorage.set(StorageKeys.eveningReminderHour, time.hour);
    await LocalStorage.set(StorageKeys.eveningReminderMinute, time.minute);
    trickWith((state) => state.copyWith(eveningReminderTime: time));

    if (state.clockReminderEnabled && state.notificationsEnabled) {
      await scheduleClockReminders();
    }
  }

  Future<void> scheduleClockReminders() async {
    final plugin = FlutterLocalNotificationsPlugin();
    final state = value;

    // Cancel existing reminders
    await plugin.cancel(1001); // Morning reminder ID
    await plugin.cancel(1002); // Evening reminder ID

    // Schedule morning reminder
    await _scheduleWeekdayReminder(
      id: 1001,
      time: state.morningReminderTime,
      title: '上班打卡提醒',
      body: '別忘了打卡上班喔！',
    );

    // Schedule evening reminder
    await _scheduleWeekdayReminder(
      id: 1002,
      time: state.eveningReminderTime,
      title: '下班打卡提醒',
      body: '記得打卡下班喔！',
    );
  }

  Future<void> _scheduleWeekdayReminder({
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    final plugin = FlutterLocalNotificationsPlugin();
    final now = DateTime.now();
    
    // Schedule for each weekday (Monday to Friday)
    for (int weekday = DateTime.monday; weekday <= DateTime.friday; weekday++) {
      var scheduledDate = _nextInstanceOfTimeOnWeekday(time, weekday);
      
      // If the time has passed today, schedule for next week
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      const androidDetails = AndroidNotificationDetails(
        'clock_reminder',
        '打卡提醒',
        channelDescription: '工作日打卡提醒通知',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      try {
        await plugin.zonedSchedule(
          id + weekday, // Unique ID for each weekday
          title,
          body,
          tz.TZDateTime.from(scheduledDate, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (e) {
        debugPrint('Failed to schedule reminder: $e');
      }
    }
  }

  DateTime _nextInstanceOfTimeOnWeekday(TimeOfDay time, int weekday) {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Adjust to the target weekday
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelClockReminders() async {
    final plugin = FlutterLocalNotificationsPlugin();
    
    // Cancel all weekday reminders for both morning and evening
    for (int weekday = DateTime.monday; weekday <= DateTime.friday; weekday++) {
      await plugin.cancel(1001 + weekday); // Morning reminders
      await plugin.cancel(1002 + weekday); // Evening reminders
    }
  }

  Future<bool> hasClockedInToday() async {
    try {
      final result = await _repository.getUserInfo().run();
      return result.fold(
        (_) => false,
        (response) {
          final jsonData = response.data as Map<String, dynamic>;
          final clockInTime = jsonData['data']?['clockInTime'] as String?;
          return clockInTime != null && clockInTime.isNotEmpty;
        },
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasClockedOutToday() async {
    try {
      final result = await _repository.getUserInfo().run();
      return result.fold(
        (_) => false,
        (response) {
          final jsonData = response.data as Map<String, dynamic>;
          final clockOutTime = jsonData['data']?['clockOutTime'] as String?;
          return clockOutTime != null && clockOutTime.isNotEmpty;
        },
      );
    } catch (e) {
      return false;
    }
  }

  Future<void> checkAndCancelTodaysReminders() async {
    final now = DateTime.now();
    final weekday = now.weekday;

    // Only check on weekdays
    if (weekday >= DateTime.monday && weekday <= DateTime.friday) {
      final plugin = FlutterLocalNotificationsPlugin();

      if (await hasClockedInToday()) {
        await plugin.cancel(1001 + weekday); // Cancel morning reminder
      }

      if (await hasClockedOutToday()) {
        await plugin.cancel(1002 + weekday); // Cancel evening reminder
      }
    }
  }
}
