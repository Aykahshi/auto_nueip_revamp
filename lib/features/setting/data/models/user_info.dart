import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_info.freezed.dart';
part 'user_info.g.dart';

@freezed
sealed class UserInfo with _$UserInfo {
  const UserInfo._();

  const factory UserInfo({
    @JsonKey(name: 'company_name') final String? companyName,
    @JsonKey(name: 'dept_name') final String? deptName,
    @JsonKey(name: 'user_name') final String? userName,
  }) = _UserInfo;

  factory UserInfo.empty() =>
      const UserInfo(companyName: '', deptName: '', userName: '');

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);
}
