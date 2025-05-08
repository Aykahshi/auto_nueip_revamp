import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'background_service_state.freezed.dart';

/// 背景服務狀態，使用單一狀態模式，包含服務狀態和設定參數
@freezed
sealed class BackgroundServiceState with _$BackgroundServiceState {
  const factory BackgroundServiceState({
    // 服務狀態
    @Default(false) bool isServiceRunning,
    @Default('尚未初始化') String lastStatus,
    @Default(false) bool isLoading,
    String? errorMessage,

    // 工作時間區間
    @Default(TimeOfDay(hour: 9, minute: 0)) TimeOfDay workHoursStart,
    @Default(TimeOfDay(hour: 18, minute: 0)) TimeOfDay workHoursEnd,

    // 上下班打卡時間
    required DateTime clockInTime,
    required DateTime clockOutTime,

    // 彈性時間和隨機時間
    @Default(30) int flexibleMinutes,
    @Default(5) int randomMinutes,
  }) = _BackgroundServiceState;

  /// 建立初始狀態
  factory BackgroundServiceState.initial() => BackgroundServiceState(
    clockInTime: DateTime.now().copyWith(hour: 9, minute: 0),
    clockOutTime: DateTime.now().copyWith(hour: 18, minute: 0),
  );
}
