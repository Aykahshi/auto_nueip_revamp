import 'package:joker_state/joker_state.dart';

import '../../../../core/config/storage_keys.dart';
import '../../../../core/utils/auth_utils.dart';
import '../../../../core/utils/local_storage.dart';
import '../../../nueip/data/repositories/nueip_repository_impl.dart';
import '../../../nueip/domain/repositories/nueip_repository.dart';
import '../../data/models/user_info.dart';
import '../../domain/entities/setting_state.dart';

final class SettingPresenter extends Presenter<SettingState> {
  final NueipRepository _repository;

  SettingPresenter({super.keepAlive = true})
    : _repository = Circus.find<NueipRepositoryImpl>(),
      super(
        SettingState(
          userInfo: UserInfo(companyName: '', deptName: '', userName: ''),
        ),
      );

  @override
  void onInit() {
    super.onInit();
    trickWith(
      (state) => state.copyWith(
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
}
