import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/failure.dart';
import '../../data/models/leave_record.dart';

part 'leave_record_state.freezed.dart';

@freezed
sealed class LeaveRecordState with _$LeaveRecordState {
  // Initial state
  const factory LeaveRecordState.initial() = LeaveRecordInitial;

  // Loading state
  const factory LeaveRecordState.loading() = LeaveRecordLoading;

  // Success state with leave records
  const factory LeaveRecordState.success({required List<LeaveRecord> records}) =
      LeaveRecordSuccess;

  // Error state with failure details
  const factory LeaveRecordState.error({required Failure failure}) =
      LeaveRecordError;
}
