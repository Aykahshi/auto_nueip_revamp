import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_hours.freezed.dart';
part 'work_hours.g.dart';

@freezed
sealed class WorkHours with _$WorkHours {
  const factory WorkHours({
    required String date,
    required int hours,
    required int mins,
    @JsonKey(name: 'startH') required String startHour,
    @JsonKey(name: 'startM') required String startMinute,
    @JsonKey(name: 'endH') required String endHour,
    @JsonKey(name: 'endM') required String endMinute,
    required List<List<String>> rest,
  }) = _WorkHours;

  factory WorkHours.fromJson(Map<String, dynamic> json) =>
      _$WorkHoursFromJson(json);
}
