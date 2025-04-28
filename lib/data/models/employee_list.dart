import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee_list.freezed.dart';
part 'employee_list.g.dart';

@freezed
sealed class Department with _$Department {
  const factory Department({
    final String? title,
    @JsonKey(name: 'user_list') Map<String, Employee>? userList,
  }) = _Department;

  factory Department.fromJson(Map<String, dynamic> json) =>
      _$DepartmentFromJson(json);
}

@freezed
sealed class Employee with _$Employee {
  const factory Employee({@JsonKey(name: 'title') final String? name}) =
      _Employee;

  factory Employee.fromJson(Map<String, dynamic> json) =>
      _$EmployeeFromJson(json);
}
