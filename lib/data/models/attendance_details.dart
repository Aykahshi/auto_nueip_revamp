import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_details.freezed.dart';
part 'attendance_details.g.dart';

@freezed
sealed class AttendanceRecord with _$AttendanceRecord {
  const factory AttendanceRecord({
    DateInfo? dateInfo,
    Attendance? attendance,
    @Default([]) List<TimeOffRecord>? timeoff,
    @Default([]) List<OvertimeRecord>? overtime,
    PunchData? punch,
    OtherInfo? other,
  }) = _AttendanceRecord;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      _$AttendanceRecordFromJson(json);
}

// --- Date Info ---
@freezed
sealed class DateInfo with _$DateInfo {
  const factory DateInfo({
    @JsonKey(name: 'date_off') required bool dateOff,
    required String holiday,
    required String date,
  }) = _DateInfo;

  factory DateInfo.fromJson(Map<String, dynamic> json) =>
      _$DateInfoFromJson(json);
}

// --- Attendance Details (Nullable) ---
@freezed
sealed class Attendance with _$Attendance {
  const factory Attendance({
    required String absent,
    @JsonKey(name: 'late') required String lateEnter,
    @JsonKey(name: 'leave_early') required String leaveEarly,
    @JsonKey(name: 'miss_punch') required String missPunch,
    required String leaveEarlyMin,
    required String lateMin,
    required String absentMin,
    @JsonKey(name: 'excel') required String tag,
  }) = _Attendance;

  factory Attendance.fromJson(Map<String, dynamic> json) =>
      _$AttendanceFromJson(json);
}

// --- TimeOff Record (List item, Nullable List) ---
@freezed
sealed class TimeOffRecord with _$TimeOffRecord {
  const factory TimeOffRecord({
    @JsonKey(name: 'rule_name') required String ruleName,
    required String time,
    @JsonKey(name: 'total_time') required String totalTime,
    required String remark,
  }) = _TimeOffRecord;

  factory TimeOffRecord.fromJson(Map<String, dynamic> json) =>
      _$TimeOffRecordFromJson(json);
}

// --- Overtime Record (List item, Nullable List) ---
@freezed
sealed class OvertimeRecord with _$OvertimeRecord {
  const factory OvertimeRecord({
    required String ruleName,
    required String time,
    @JsonKey(name: 'total_time') required String totalTime,
    required String signStatus,
    required String remark,
  }) = _OvertimeRecord;

  factory OvertimeRecord.fromJson(Map<String, dynamic> json) =>
      _$OvertimeRecordFromJson(json);
}

// --- Punch Data (Can be empty list or object) ---
@freezed
sealed class PunchData with _$PunchData {
  const factory PunchData({
    @Default([]) List<PunchRecord> onPunch,
    @Default([]) List<PunchRecord> offPunch,
  }) = _PunchData;

  factory PunchData.fromJson(Map<String, dynamic> json) =>
      _$PunchDataFromJson(json);
}

// --- Punch Record (List item in PunchData) ---
@freezed
sealed class PunchRecord with _$PunchRecord {
  const factory PunchRecord({
    required String date,
    required String remark,
    required String solvedStatus,
    required bool adjustBelong,
    required String time,
    required String type,
  }) = _PunchRecord;

  factory PunchRecord.fromJson(Map<String, dynamic> json) =>
      _$PunchRecordFromJson(json);
}

// --- Other Info ---
@freezed
sealed class OtherInfo with _$OtherInfo {
  const factory OtherInfo({
    bool? future,
    bool? modify,
    required bool correctionTimesExceeds,
    required bool correctionDateExceedsRange,
  }) = _OtherInfo;

  factory OtherInfo.fromJson(Map<String, dynamic> json) =>
      _$OtherInfoFromJson(json);
}
