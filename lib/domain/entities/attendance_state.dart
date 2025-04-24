import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/attendance_details.dart';

part 'attendance_state.freezed.dart';

@freezed
sealed class AttendanceState with _$AttendanceState {
  const factory AttendanceState.initial() = AttendanceInitial;
  const factory AttendanceState.loading() = AttendanceLoading;
  const factory AttendanceState.success(
    final List<AttendanceRecord>? attendanceRecords,
    final AttendanceRecord? dailyAttendanceRecord,
  ) = AttendanceSuccess;
  const factory AttendanceState.error(String message) = AttendanceError;
}
