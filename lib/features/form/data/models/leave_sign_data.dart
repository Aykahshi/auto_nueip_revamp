import 'package:freezed_annotation/freezed_annotation.dart';

part 'leave_sign_data.freezed.dart';
part 'leave_sign_data.g.dart';

@freezed
sealed class LeaveSignData with _$LeaveSignData {
  const factory LeaveSignData({
    @JsonKey(name: 'all_complete') required bool allComplete,
    @JsonKey(name: 'current_state', fromJson: _parseIntFromJson)
    required num currentState,
    @JsonKey(name: 'audit_list') required List<AuditItem> auditList,
  }) = _LeaveSignData;

  factory LeaveSignData.fromJson(Map<String, dynamic> json) =>
      _$LeaveSignDataFromJson(json);
}

@freezed
sealed class AuditItem with _$AuditItem {
  const AuditItem._();

  const factory AuditItem({
    @JsonKey(name: 'round_no') String? roundNo,
    @JsonKey(name: 'open_status', fromJson: _parseIntFromJson)
    required num openStatus,
    @JsonKey(name: 'sign_manager') String? signManager,
    @JsonKey(name: 'reply_status', fromJson: _parseIntFromJson)
    required num replyStatus,
    @JsonKey(name: 'reply') String? replyRemark,
    @JsonKey(name: 'sign_time') String? signTime,
    @JsonKey(name: 'added_remark') String? addedRemark,
    @JsonKey(name: 'c_date') String? createTime,
    @JsonKey(name: 'rec_status', fromJson: _parseIntFromJson)
    required num recStatus,
    @JsonKey(name: 'manager_name') String? managerName,
    @JsonKey(name: 'sign_manager_name') String? signManagerName,
    @Default(false) final bool isManagerSign,
  }) = _AuditItem;

  factory AuditItem.fromJson(Map<String, dynamic> json) =>
      _$AuditItemFromJson(json);

  bool get isSigned => isManagerSign;
}

num _parseIntFromJson(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is double) return value.toInt();
  if (value is int) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}
