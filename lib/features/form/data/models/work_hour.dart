import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_hour.freezed.dart';
part 'work_hour.g.dart';

@freezed
sealed class WorkHour with _$WorkHour {
  const WorkHour._();

  const factory WorkHour({
    required String date,
    required int hours,
    required int mins,
    @JsonKey(name: 'startH') required String startHour,
    @JsonKey(name: 'startM') required String startMinute,
    @JsonKey(name: 'endH') required String endHour,
    @JsonKey(name: 'endM') required String endMinute,
    @JsonKey(name: 'rest', fromJson: _restFromJson)
    required List<List<String>> rest,
  }) = _WorkHour;

  factory WorkHour.fromJson(Map<String, dynamic> json) =>
      _$WorkHourFromJson(json);

  Duration get restDuration {
    if (rest.isEmpty) {
      return Duration.zero;
    }

    Duration totalRest = Duration.zero;

    for (var interval in rest) {
      if (interval.length < 2) continue;

      final start = DateTime.tryParse(interval[0]);
      final end = DateTime.tryParse(interval[1]);

      if (start == null || end == null) continue;

      // 計算此休息區間的時長並加到總休息時間
      totalRest += end.difference(start);
    }

    return totalRest;
  }

  /// 計算實際工作時間 (總工時減去休息時間)
  Duration get actualWorkDuration {
    final totalDuration = Duration(hours: hours, minutes: mins);
    final rest = restDuration;

    // 如果總工時小於休息時間，返回零以避免負數
    if (totalDuration < rest) {
      return Duration.zero;
    }

    return totalDuration - rest;
  }
}

List<List<String>> _restFromJson(dynamic json) {
  if (json == null) return [];
  if (json is! List) return [];

  final result = <List<String>>[];

  for (var item in json) {
    if (item is List) {
      final innerList = <String>[];
      for (var innerItem in item) {
        if (innerItem != null) {
          innerList.add(innerItem.toString());
        }
      }
      if (innerList.isNotEmpty) {
        result.add(innerList);
      }
    }
  }

  return result;
}
