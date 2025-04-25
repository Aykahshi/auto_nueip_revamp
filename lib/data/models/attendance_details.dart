import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_details.freezed.dart';
part 'attendance_details.g.dart';

@freezed
sealed class AttendanceRecord with _$AttendanceRecord {
  const factory AttendanceRecord({
    @JsonKey(name: 'dateInfo') final DateInfo? dateInfo,
    @JsonKey(name: 'attendance') final Attendance? attendance,
    @JsonKey(name: 'worktime') final String? workTime,
    @JsonKey(name: 'timeoff') @Default([]) final List<TimeOffRecord>? timeoff,
    @JsonKey(name: 'overtime')
    @Default([])
    final List<OvertimeRecord>? overtime,
    @JsonKey(fromJson: _punchFromJson) final PunchData? punch,
    final OtherInfo? other,
  }) = _AttendanceRecord;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      _$AttendanceRecordFromJson(json);
}

// --- Date Info ---
@freezed
sealed class DateInfo with _$DateInfo {
  const factory DateInfo({
    @JsonKey(name: 'date_off') required bool dateOff,
    final String? holiday,
    required String date,
  }) = _DateInfo;

  factory DateInfo.fromJson(Map<String, dynamic> json) =>
      _$DateInfoFromJson(json);
}

// --- Attendance Details (Nullable) ---
@freezed
sealed class Attendance with _$Attendance {
  const Attendance._();
  const factory Attendance({
    @JsonKey(name: 'durhour', fromJson: _parseIntFromJson)
    required num duringHour,
    @JsonKey(name: 'durmin', fromJson: _parseIntFromJson)
    required num duringMin,
    @JsonKey(fromJson: _parseIntFromJson) required num absent,
    @JsonKey(name: 'late', fromJson: _parseIntFromJson) required num lateEnter,
    @JsonKey(name: 'leave_early', fromJson: _parseIntFromJson)
    required num leaveEarly,
    @JsonKey(name: 'miss_punch', fromJson: _parseIntFromJson)
    required num missPunch,
    @JsonKey(name: 'leaveearlymin', fromJson: _parseIntFromJson)
    required num leaveEarlyMin,
    @JsonKey(name: 'latemin', fromJson: _parseIntFromJson) required num lateMin,
    @JsonKey(name: 'absentmin', fromJson: _parseIntFromJson)
    required num absentMin,
    @JsonKey(name: 'excel') String? tag,
  }) = _Attendance;

  factory Attendance.fromJson(Map<String, dynamic> json) =>
      _$AttendanceFromJson(json);

  bool get isAbsent => absent != 0;
  bool get isLate => lateEnter != 0;
  bool get isLeaveEarly => leaveEarly != 0;
  bool get isMissPunch => missPunch != 0;
}

// --- TimeOff Record (List item, Nullable List) ---
@freezed
sealed class TimeOffRecord with _$TimeOffRecord {
  const TimeOffRecord._();

  const factory TimeOffRecord({
    @JsonKey(name: 'rule_name') final String? ruleName,
    final String? time,
    @JsonKey(name: 'total_time', fromJson: _parseIntFromJson)
    final num? totalTime,
    @JsonKey(name: 'sign_status', fromJson: _parseIntFromJson)
    final num? signStatus,
    final String? remark,
  }) = _TimeOffRecord;

  factory TimeOffRecord.fromJson(Map<String, dynamic> json) =>
      _$TimeOffRecordFromJson(json);

  bool get isSign => signStatus == 2;
}

// --- Overtime Record (List item, Nullable List) ---
@freezed
sealed class OvertimeRecord with _$OvertimeRecord {
  const factory OvertimeRecord({
    final String? ruleName,
    final String? time,
    @JsonKey(name: 'total_time') final String? totalTime,
    final String? signStatus,
    final String? remark,
  }) = _OvertimeRecord;

  factory OvertimeRecord.fromJson(Map<String, dynamic> json) =>
      _$OvertimeRecordFromJson(json);
}

// --- Punch Data ---
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
  const PunchRecord._();

  const factory PunchRecord({
    required String date,
    final String? remark,
    @JsonKey(name: 'solved_status', fromJson: _parseIntFromJson)
    required num solvedStatus,
    @JsonKey(name: 'sign_status', fromJson: _parseIntFromJson)
    required num signStatus,
    required bool adjustBelong,
    required String time,
    required String type,
  }) = _PunchRecord;

  factory PunchRecord.fromJson(Map<String, dynamic> json) =>
      _$PunchRecordFromJson(json);

  bool get isSolved => solvedStatus == 2;
}

// --- Other Info ---
@freezed
sealed class OtherInfo with _$OtherInfo {
  const factory OtherInfo({
    final bool? future,
    final bool? modify,
    required bool correctionTimesExceeds,
    required bool correctionDateExceedsRange,
  }) = _OtherInfo;

  factory OtherInfo.fromJson(Map<String, dynamic> json) =>
      _$OtherInfoFromJson(json);
}

PunchData? _punchFromJson(dynamic json) {
  if (json is Map<String, dynamic>) {
    return PunchData.fromJson(json);
  }
  return null;
}

num _parseIntFromJson(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is double) return value.toInt();
  if (value is int) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}
