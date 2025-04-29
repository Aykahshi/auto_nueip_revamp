import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_sn.freezed.dart';
part 'user_sn.g.dart';

@freezed
sealed class UserSn with _$UserSn {
  const factory UserSn({
    @JsonKey(name: 's_sn') required String system,
    @JsonKey(name: 'c_sn') required String company,
    @JsonKey(name: 'd_sn') required String department,
  }) = _UserSn;

  factory UserSn.fromJson(Map<String, dynamic> json) => _$UserSnFromJson(json);
}
