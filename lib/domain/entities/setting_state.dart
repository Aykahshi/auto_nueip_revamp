import 'package:freezed_annotation/freezed_annotation.dart';

part 'setting_state.freezed.dart';

@freezed
sealed class SettingState with _$SettingState {
  const factory SettingState({
    @Default('使用者') String username,
    @Default(false) bool notificationsEnabled,
    @Default(false) bool darkModeEnabled,
  }) = _SettingState;
}
