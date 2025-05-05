import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/failure.dart';
import '../../data/models/user_info.dart';

part 'setting_state.freezed.dart';

@freezed
sealed class SettingState with _$SettingState {
  const factory SettingState({
    required UserInfo userInfo,
    @Default(false) final bool notificationsEnabled,
    @Default(false) final bool darkModeEnabled,
    @Default(false) final bool isLoading,
    final Failure? error,
  }) = _SettingState;
}
