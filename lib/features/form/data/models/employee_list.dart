import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee_list.freezed.dart';
part 'employee_list.g.dart';

@freezed
sealed class Department with _$Department {
  const factory Department({
    @JsonKey(name: 'sn') final String? id,
    final String? title,
    @Default([])
    @JsonKey(name: 'user_list', fromJson: _parseUserList)
    List<Employee>? userList,
  }) = _Department;

  factory Department.fromJson(Map<String, dynamic> json) =>
      _$DepartmentFromJson(json);
}

@freezed
sealed class Employee with _$Employee {
  const factory Employee({
    @JsonKey(name: 'sn') final String? id,
    @JsonKey(name: 'ud_sn') final String? sn,
    @JsonKey(name: 'title') final String? name,
  }) = _Employee;

  factory Employee.fromJson(Map<String, dynamic> json) =>
      _$EmployeeFromJson(json);
}

List<Employee> _parseUserList(dynamic userList) {
  if (userList == null) return [];

  if (userList is List && userList.isEmpty) return [];

  if (userList is Map<String, dynamic>) {
    return userList.entries.map((entry) {
      final employeeData = entry.value as Map<String, dynamic>;
      return Employee.fromJson(employeeData);
    }).toList();
  }

  return [];
}
