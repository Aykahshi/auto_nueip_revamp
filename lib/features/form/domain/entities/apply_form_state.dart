import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/employee_list.dart';
import '../../data/models/work_hours.dart';
import '../../presentation/screens/form_screen.dart';
import 'leave_rule.dart';

part 'apply_form_state.freezed.dart';

/// Represents the state for the ApplyForm screen.
@freezed
sealed class ApplyFormState with _$ApplyFormState {
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
    @Default({}) Map<String, WorkHours> workHours,
  }) = _ApplyFormState;
}
