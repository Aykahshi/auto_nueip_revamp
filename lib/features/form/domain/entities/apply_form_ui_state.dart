import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/employee_list.dart';

part 'apply_form_ui_state.freezed.dart';

/// 用於管理 ApplyFormScreen 的本地 UI 狀態
@freezed
sealed class ApplyFormUiState with _$ApplyFormUiState {
  const factory ApplyFormUiState({
    // 日期與時間選擇
    DateTime? selectedStartDate,
    TimeOfDay? selectedStartTime,
    DateTime? selectedEndDate,
    TimeOfDay? selectedEndTime,
    Duration? calculatedDuration,

    // 表單欄位選擇
    String? selectedLeaveRuleId,
    Employee? selectedAgent,
    @Default([]) List<File> selectedFiles,

    // 計算的顯示值
    @Default('選擇開始日期') String displayStartDate,
    @Default('選擇開始時間') String displayStartTime,
    @Default('選擇結束日期') String displayEndDate,
    @Default('選擇結束時間') String displayEndTime,
    @Default('請選擇起始時間') String displayDuration,

    // Form state
    @Default(false) bool isFormValid,
    @Default(false) bool isSubmitting,
    String? errorMessage,
  }) = _ApplyFormUiState;
}
