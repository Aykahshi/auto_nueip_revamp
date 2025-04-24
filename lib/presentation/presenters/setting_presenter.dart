import 'package:joker_state/joker_state.dart';

import '../../core/config/storage_keys.dart';
import '../../core/utils/local_storage.dart';
import '../../domain/entities/setting_state.dart';

class SettingPresenter extends Presenter<SettingState> {
  SettingPresenter() : super(const SettingState());

  @override
  void onInit() {
    super.onInit();
    trick(
      SettingState(
        username: LocalStorage.get<String>(
          StorageKeys.username,
          defaultValue: '使用者',
        ),
        notificationsEnabled: LocalStorage.get<bool>(
          StorageKeys.notificationsEnabled,
          defaultValue: false,
        ),
        darkModeEnabled: LocalStorage.get<bool>(
          StorageKeys.darkModeEnabled,
          defaultValue: false,
        ),
      ),
    );
  }

  void updateUsername(String name) {
    trickWith((state) => state.copyWith(username: name));
    // Save to local storage
    LocalStorage.set(StorageKeys.username, name);
  }

  void toggleNotifications(bool value) {
    trickWith((state) => state.copyWith(notificationsEnabled: value));
    LocalStorage.set(StorageKeys.notificationsEnabled, value);
  }

  void toggleDarkMode(bool value) {
    trickWith((state) => state.copyWith(darkModeEnabled: value));
    LocalStorage.set(StorageKeys.darkModeEnabled, value);
  }
}
