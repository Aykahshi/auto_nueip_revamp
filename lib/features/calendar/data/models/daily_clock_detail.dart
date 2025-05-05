import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_clock_detail.freezed.dart';
part 'daily_clock_detail.g.dart';

@freezed
sealed class DailyClockDetail with _$DailyClockDetail {
  const factory DailyClockDetail({
    @JsonKey(name: 'u_no') required String userNo,
    @JsonKey(name: 'A1') final String? clockInTime,
    @JsonKey(name: 'A2') final String? clockOutTime,
    @JsonKey(name: 'remarkA1') final String? clockInRemark,
    @JsonKey(name: 'remarkA2') final String? clockOutRemark,
  }) = _DailyClockDetail;

  factory DailyClockDetail.fromJson(Map<String, dynamic> json) =>
      _$DailyClockDetailFromJson(json);
}
