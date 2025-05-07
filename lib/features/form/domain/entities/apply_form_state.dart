import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/employee_list.dart';
import '../../data/models/work_hour.dart';
import '../../presentation/screens/form_screen.dart';
import 'leave_rule.dart';

part 'apply_form_state.freezed.dart';

/// Represents the state for the ApplyForm screen.
@freezed
sealed class ApplyFormState with _$ApplyFormState {
  const ApplyFormState._();

  const factory ApplyFormState({
    // Identifying Info
    required FormHistoryType formType,

    // Status Flags
    @Default(false) bool isLoadingInitialData,
    @Default(false) bool isLoadingWorkHours,
    @Default(false) bool isSubmitting,
    @Default(false) bool hasError,
    String? errorMessage,
    String? errorStatus,

    // Data
    @Default({}) Map<String, (String?, List<Employee>)> departmentEmployees,
    @Default([]) List<LeaveRule> leaveRules,
    List<WorkHour>? workHours,
    Duration? totalWorkHoursDuration,
  }) = _ApplyFormState;

  String get displayTotalWorkHours {
    if (totalWorkHoursDuration == null) return '--';

    final hours = totalWorkHoursDuration!.inHours;
    final minutes = totalWorkHoursDuration!.inMinutes.remainder(60);

    // 處理工時為零的情況 (API 有返回但為零)
    if (hours == 0 && minutes == 0) {
      if (workHours != null && workHours!.isNotEmpty) {
        return '0 小時 0 分鐘'; // 明確顯示零工時
      }
      return '--'; // API 未返回或未選擇日期
    }

    // 格式化顯示非零的工時
    String result = '';
    if (hours > 0) {
      result += '$hours 小時';
    }

    if (minutes > 0) {
      if (result.isNotEmpty) result += ' ';
      result += '$minutes 分鐘';
    }

    return result.isEmpty ? '0 小時 0 分鐘' : result;
  }
}
