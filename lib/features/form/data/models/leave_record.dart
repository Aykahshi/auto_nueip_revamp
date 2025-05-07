import 'package:freezed_annotation/freezed_annotation.dart';

part 'leave_record.freezed.dart';
part 'leave_record.g.dart';

@freezed
sealed class LeaveRecord with _$LeaveRecord {
  const LeaveRecord._();

  const factory LeaveRecord({
    @JsonKey(name: 's_sn') required String id,
    @JsonKey(name: 'rule_name') String? ruleName,
    @JsonKey(name: 'qry_no') required String qryNo,
    @JsonKey(name: 'is_canceled', fromJson: _isCanceledFromJson)
    required bool isCanceled,
    @JsonKey(name: 'total_time') String? totalTime,
    final String? remark,
    @JsonKey(name: 'sign_status', fromJson: _parseIntFromJson)
    required num signStatus,
    @JsonKey(name: 'agent_name') String? agentName,
    @JsonKey(name: 'c_date') String? createTime,
    @JsonKey(name: 'start_time') String? startTime,
    @JsonKey(name: 'end_time') String? endTime,
    @JsonKey(name: 'total_hours') String? totalHours,
    @JsonKey(name: 'c_user_name') String? username,
    final String? file,
    @JsonKey(fromJson: _fileInfoFromJson) final FileInfo? fileInfo,
    @JsonKey(name: 'attachment_status') String? attachmentStatus,
    @Default(true) final bool isCancelable,
  }) = _LeaveRecord;

  factory LeaveRecord.fromJson(Map<String, dynamic> json) =>
      _$LeaveRecordFromJson(json);

  String get formattedTotalHours {
    if (totalHours == null || totalHours!.isEmpty) {
      return '--';
    }
    try {
      final parts = totalHours!.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        String formatted = '';
        if (hour > 0) formatted += '$hour 小時';
        if (minute > 0) formatted += '$minute 分鐘';
        return formatted.isNotEmpty ? formatted : '--';
      }
      return '格式錯誤';
    } catch (e) {
      return '解析錯誤';
    }
  }

  bool get isSigned => signStatus == 2;
  bool get isRejected => signStatus == 3;
  bool get isPending => signStatus != 1 && signStatus < 2;
  bool get canCancel => isCancelable && !isSigned && !isRejected;
}

@freezed
sealed class FileInfo with _$FileInfo {
  const factory FileInfo({List<StorageFile>? storage}) = _FileInfo;

  factory FileInfo.fromJson(Map<String, dynamic> json) =>
      _$FileInfoFromJson(json);
}

@freezed
sealed class StorageFile with _$StorageFile {
  const factory StorageFile({String? link, String? name}) = _StorageFile;

  factory StorageFile.fromJson(Map<String, dynamic> json) =>
      _$StorageFileFromJson(json);
}

bool _isCanceledFromJson(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is String) return value == '1';
  return false;
}

num _parseIntFromJson(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is double) return value.toInt();
  if (value is int) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

/// Custom fromJson function for FileInfo to handle both map and list cases
FileInfo? _fileInfoFromJson(dynamic json) {
  if (json == null) return null;

  // Case 1: json is already a Map<String, dynamic>
  if (json is Map<String, dynamic>) {
    return FileInfo.fromJson(json);
  }

  // Case 2: json is a List
  if (json is List) {
    if (json.isEmpty) return null;

    // Create a storage list from the array
    final storageFiles = <StorageFile>[];

    for (var item in json) {
      if (item is Map<String, dynamic>) {
        storageFiles.add(StorageFile.fromJson(item));
      }
    }

    return FileInfo(storage: storageFiles);
  }

  // If json is neither a map nor a list, return null
  return null;
}
