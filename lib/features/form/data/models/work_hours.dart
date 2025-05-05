import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_hours.freezed.dart';
part 'work_hours.g.dart';

@freezed
sealed class WorkHours with _$WorkHours {
  const WorkHours._();

  const factory WorkHours({
    required String date,
    required int hours,
    required int mins,
    @JsonKey(name: 'startH') required String startHour,
    @JsonKey(name: 'startM') required String startMinute,
    @JsonKey(name: 'endH') required String endHour,
    @JsonKey(name: 'endM') required String endMinute,
    @JsonKey(name: 'rest', fromJson: _restFromJson) required List<String> rest,
  }) = _WorkHours;

  factory WorkHours.fromJson(Map<String, dynamic> json) =>
      _$WorkHoursFromJson(json);

  Duration? get restDurMins {
    if (rest.isEmpty || rest.first.length != 2) return null;
    final start = DateTime.tryParse(rest.first[0]);
    final end = DateTime.tryParse(rest.first[1]);
    if (start == null || end == null) return null;
    return end.difference(start);
  }
}

List<String> _restFromJson(dynamic json) {
  if (json == null || json is! List) return [];
  return json.map((e) => e.toString()).toList();
}
