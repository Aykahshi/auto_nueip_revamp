import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:joker_state/joker_state.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

    trickWith(
      (state) => state.copyWith(
        notificationsEnabled: notificationEnabled,
        darkModeEnabled: LocalStorage.get<bool>(
          StorageKeys.darkModeEnabled,
          defaultValue: false,
        ),
      ),
    );
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
}
