import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/failure.dart';
import '../../data/models/user_info.dart';

part 'setting_state.freezed.dart';

@freezed
sealed class SettingState with _$SettingState {
  const SettingState._();

  const factory SettingState({
    required UserInfo userInfo,
    @Default(false) final bool notificationsEnabled,
    @Default(false) final bool darkModeEnabled,
    @Default(false) final bool clockReminderEnabled,
    @Default(TimeOfDay(hour: 9, minute: 0)) final TimeOfDay morningReminderTime,
    @Default(TimeOfDay(hour: 18, minute: 0))
    final TimeOfDay eveningReminderTime,
    @Default(false) final bool isLoading,
    final String? appVersion,
    final Failure? error,
  }) = _SettingState;

  factory SettingState.initial() => SettingState(userInfo: UserInfo.empty());
}
