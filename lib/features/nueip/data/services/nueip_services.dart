import 'dart:convert';
import 'dart:io' show File;

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:joker_state/joker_state.dart';

import '../../../../core/config/apis.dart';
import '../../../../core/config/storage_keys.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/utils/local_storage.dart';
import '../../../form/data/models/employee_list.dart';
import '../../../form/data/models/form_type_enum.dart';
import '../../../form/data/models/leave_record.dart';
import '../../../form/data/models/leave_sign_data.dart';
import '../../../form/data/models/work_hour.dart';
import '../../../form/domain/entities/leave_rule.dart';
import '../models/user_sn.dart';

final class NueipService {
  final ApiClient _client;

  NueipService({ApiClient? client})
    : _client = client ?? Circus.find<ApiClient>();

  TaskEither<Failure, Response> login({
    required String company,
    required String id,
    required String password,
  }) {
    final body = {
      'inputCompany': company,
      'inputID': id,
      'inputPassword': password,
    };
    return TaskEither.tryCatch(
      () async => await _client.post(APIs.LOGIN, data: body),
      (e, _) => Failure(message: e.toString(), status: 'login_failed'),
    );
  }

  TaskEither<Failure, Response> clockAction({
    required String method,
    required String cookie,
    required String csrfToken,
    required double latitude,
    required double longitude,
  }) {
    final String timeStamp = DateTime.now().toIso8601String();
    final formData = {
      'action': 'add',
      'id': method,
      'attendance_time': timeStamp,
      'token': csrfToken,
      'lat': latitude,
      'lng': longitude,
    };
    return TaskEither.tryCatch(
      () async => await _client.post(
        APIs.CLOCK,
        data: formData,
        options: Options(headers: {'Cookie': cookie}),
      ),
      (e, _) => Failure(
        message: e.toString(),
        status: 'clock_failed',
      ), // Provide default status
    );
  }

  TaskEither<Failure, Response> getOauthToken({required String cookie}) {
    return TaskEither.tryCatch(
      () async => await _client.get(
        APIs.TOKEN,
        options: Options(headers: {'Cookie': cookie}),
      ),
      (e, _) => Failure(
        message: e.toString(),
        status: 'token_failed',
      ), // Provide default status
    );
  }

  TaskEither<Failure, Response> getClockTime({
    required String accessToken,
    required String cookie,
  }) {
    return TaskEither.tryCatch(
      () async => await _client.get(
        APIs.RECORD,
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken', 'Cookie': cookie},
        ),
        queryParameters: {'type': 'view'},
      ),
      (e, _) => Failure(
        message: e.toString(),
        status: 'record_failed',
      ), // Provide default status
    );
  }

  TaskEither<Failure, Response> getDailyAttendanceRecord({
    required String date,
    required String cookie,
  }) {
    final formData = {
      'action': 'attendance',
      'loadInBatch': '1',
      'loadBatchGroupNum': '1000',
      'loadBatchNumber': '1',
      'work_status': '1,4',
    };
    return TaskEither.tryCatch(
      () async => await _client.post(
        APIs.ATTENDANCE,
        data: formData,
        options: Options(
          headers: {
            'Cookie':
                'Search_42_date_start=$date; Search_42_date_end=$date; $cookie',
          },
        ),
      ),
      (e, _) => Failure(
        message: e.toString(),
        status: 'daily_attendance_failed',
      ), // Provide default status
    );
  }

  TaskEither<Failure, Response> getAttendanceRecords({
    required String startDate,
    required String endDate,
    required String cookie,
  }) {
    final formData = {
      'action': 'attendance',
      'loadInBatch': '1',
      'loadBatchGroupNum': '1000',
      'loadBatchNumber': '1',
      'work_status': '1,4',
    };
    return TaskEither.tryCatch(
      () async => await _client.post(
        APIs.ATTENDANCE,
        data: formData,
        options: Options(
          headers: {
            'Cookie':
                'Search_42_date_start=$startDate; Search_42_date_end=$endDate; $cookie',
          },
        ),
      ),
      (e, _) => Failure(
        message: e.toString(),
        status: 'attendance_failed',
      ), // Provide default status
    );
  }

  TaskEither<Failure, Response> getUserInfo() {
    return TaskEither.tryCatch(
      () async => await _client.get(APIs.INFO),
      (e, _) => Failure(message: e.toString(), status: 'info_failed'),
    );
  }

  TaskEither<Failure, Map<String, (String?, List<Employee>)>> getEmployees() {
    return TaskEither.tryCatch(
      () async {
        final Map<String, dynamic> payload = {
          'single_select': "1",
          'all_user': "1",
          'work_status': "1",
        };

        final response = await _client.post(APIs.EMPLOYEE_LIST, data: payload);

        final responseData = response.data as Map<String, dynamic>;
        final companyList =
            responseData['company_list'] as Map<String, dynamic>;

        final firstCompanyKey = companyList.keys.first;
        final firstCompany =
            companyList[firstCompanyKey] as Map<String, dynamic>;

        final deptList = firstCompany['dept_list'] as Map<String, dynamic>;

        final Map<String, (String?, List<Employee>)> departmentEmployees = {};

        for (final deptEntry in deptList.entries) {
          final dept = Department.fromJson(
            deptEntry.value as Map<String, dynamic>,
          );
          final deptName = dept.title ?? '查無此部門';
          final deptId = dept.id;
          final filteredEmployees =
              dept.userList?.where((employee) {
                return employee.name == null ||
                    !employee.name!.contains("Administrator");
              }).toList();

          departmentEmployees[deptName] = (deptId, filteredEmployees ?? []);
        }

        return departmentEmployees;
      },
      (e, _) => Failure(
        message: e.toString(),
        status: 'get_employees_by_department_failed',
      ),
    );
  }

  TaskEither<Failure, List<LeaveRule>> getLeaveRules() {
    return TaskEither.tryCatch(
      () async {
        final userNo = LocalStorage.get<String>(
          StorageKeys.userNo,
          defaultValue: '',
        );

        if (userNo.isEmpty) return [];

        final response = await _client.get(
          APIs.LEAVE_RULES,
          queryParameters: {'applicant': userNo},
        );

        final responseData = response.data as Map<String, dynamic>;
        final data = responseData['data'] as Map<String, dynamic>;

        final List<LeaveRule> leaveRules = [];

        data.forEach((_, rules) {
          if (rules is Map<String, dynamic>) {
            rules.forEach((key, value) {
              final rule = LeaveRule(id: key, ruleName: value);
              leaveRules.add(rule);
            });
          }
        });

        return leaveRules;
      },
      (e, _) =>
          Failure(message: e.toString(), status: 'get_leave_types_failed'),
    );
  }

  TaskEither<Failure, List<LeaveRecord>> getLeaveRecords({
    required String employee,
    required String startDate,
    required String endDate,
    required String cookie,
  }) {
    return TaskEither.tryCatch(
      () async {
        final userSn = LocalStorage.get<List<String>>(
          StorageKeys.userSn,
          defaultValue: [],
        );

        if (userSn.isEmpty) return [];

        final sn = UserSn(
          company: userSn[0],
          department: userSn[1],
          system: userSn[2],
        );

        final String employee = '${sn.company}_${sn.department}_${sn.system}';

        final Map<String, dynamic> queryParams = {
          'action': 'list',
          's_date': startDate,
          'e_date': endDate,
          'employee': employee,
          'resource': 'all',
          'qry_no': '',
          'filtMethod': 'all',
        };

        final response = await _client.post(
          APIs.LEAVE_SYSTEM,
          data: queryParams,
          options: Options(
            contentType: 'application/x-www-form-urlencoded',
            responseType: ResponseType.json,
            headers: {'X-Requested-With': 'XMLHttpRequest'},
          ),
        );

        final responseData = response.data as Map<String, dynamic>;
        if (!responseData.containsKey('result') ||
            responseData['result'] is! List) {
          throw Exception('Invalid response format for leave records');
        }

        final List<dynamic> resultList =
            responseData['result'] as List<dynamic>;

        final leaveRecords =
            resultList
                .map(
                  (item) => LeaveRecord.fromJson(item as Map<String, dynamic>),
                )
                .toList();

        return leaveRecords;
      },
      (e, _) =>
          Failure(message: e.toString(), status: 'get_leave_records_failed'),
    );
  }

  TaskEither<Failure, UserSn> getUserSn() {
    return TaskEither.tryCatch(() async {
      final response = await _client.post(APIs.USER_SN);

      final userNo = LocalStorage.get<String>(
        StorageKeys.userNo,
        defaultValue: '',
      );

      if (userNo.isEmpty) {
        return const UserSn(system: '', company: '', department: '');
      }

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData[userNo] as Map<String, dynamic>;

      final sn = UserSn.fromJson(data);

      await LocalStorage.set<List<String>>(StorageKeys.userSn, [
        sn.company,
        sn.department,
        sn.system,
      ]);

      return sn;
    }, (e, _) => Failure(message: e.toString(), status: 'get_user_sn_failed'));
  }

  TaskEither<Failure, LeaveSignData> getLeaveSignData({
    required FormType type,
    required String id,
  }) {
    return TaskEither.tryCatch(
      () async {
        final formData = {
          'p_no': type.value,
          'fn_typ': "1,3",
          's_sn': id,
          'return': 'data',
        };

        final response = await _client.post(
          APIs.SIGN_DATA,
          data: formData,
          options: Options(headers: {'X-Requested-With': 'XMLHttpRequest'}),
        );

        final responseData = response.data as Map<String, dynamic>;

        final leaveData = responseData['data']['leave'] as Map<String, dynamic>;

        final leaveSignData = LeaveSignData.fromJson(leaveData);

        return leaveSignData;
      },
      (e, s) => Failure(
        message: 'Failed to get sign data: ${e.toString()}',
        status: 'get_sign_failed',
      ),
    );
  }

  TaskEither<Failure, Response> sendLeaveForm({
    required String ruleId,
    required String startDate,
    required String endDate,
    required List<(String date, String start, String end, int hour, int min)>
    leaveEntries,
    required String agentId,
    required String remark,
    List<File>? files,
    required String cookie,
  }) {
    return TaskEither.tryCatch(
      () async {
        final formData = FormData();

        final userSn = LocalStorage.get<List<String>>(
          StorageKeys.userSn,
          defaultValue: [],
        );

        final sn = UserSn(
          company: userSn[0],
          department: userSn[1],
          system: userSn[2],
        );

        final String employee = '${sn.company}_${sn.department}_${sn.system}';

        // Add common form fields
        formData.fields.addAll([
          MapEntry('myFLayer', ruleId),
          MapEntry('s_date', startDate),
          MapEntry('d_date', endDate),
          MapEntry('FLayer2', sn.company),
          MapEntry('SLayer2', sn.department),
          MapEntry('sub_usn', agentId),
          MapEntry('TLayer2', employee),
          MapEntry('remark', remark),
          const MapEntry('action', 'add'),
          const MapEntry('pageType', 'leave'),
        ]);

        // Add multiple leave entries
        for (var i = 0; i < leaveEntries.length; i++) {
          final entry = leaveEntries[i];
          formData.fields.addAll([
            MapEntry('leave[$i][start]', entry.$2),
            MapEntry('leave[$i][end]', entry.$3),
            MapEntry('leave[$i][hour]', entry.$4.toString()),
            MapEntry('leave[$i][min]', entry.$5.toString()),
            MapEntry('leave[$i][date]', entry.$1),
          ]);
        }

        if (files != null && files.isNotEmpty) {
          for (var i = 0; i < files.length; i++) {
            final file = files[i];
            final fileName = file.path.split('/').last;
            formData.files.add(
              MapEntry(
                'files[]',
                await MultipartFile.fromFile(file.path, filename: fileName),
              ),
            );
          }
        }

        try {
          final response = await _client.post(
            APIs.LEAVE_SYSTEM,
            data: formData,
            options: Options(headers: {'X-Requested-With': 'XMLHttpRequest'}),
          );
          return response;
        } on DioException catch (e) {
          // 處理 DioException，例如 400 Bad Request
          if (e.response != null) {
            // 嘗試解析錯誤響應中的 message
            try {
              final errorData = e.response!.data;
              String errorMessage = '提交請假表單失敗';

              if (errorData is Map<String, dynamic>) {
                // 直接從 Map 中獲取 message
                errorMessage = errorData['message'] ?? errorMessage;
              } else if (errorData is String) {
                // 嘗試將字符串解析為 JSON
                try {
                  final errorJson = jsonDecode(errorData);
                  if (errorJson is Map<String, dynamic>) {
                    errorMessage = errorJson['message'] ?? errorMessage;
                  }
                } catch (_) {
                  // 解析失敗，使用原始字符串
                  errorMessage = errorData;
                }
              }

              throw Failure(message: errorMessage, status: 'send_form_failed');
            } catch (parseError) {
              // 解析錯誤響應失敗，使用原始錯誤訊息
              rethrow;
            }
          }
          // 如果沒有響應或解析失敗，重新拋出原始異常
          rethrow;
        }
      },
      (e, s) {
        // 如果錯誤已經是 Failure 類型，則直接返回
        if (e is Failure) {
          return e;
        }
        // 否則創建新的 Failure
        return Failure(
          message: 'Failed to send form request: ${e.toString()}',
          status: 'send_form_failed',
        );
      },
    );
  }

  TaskEither<Failure, Response> deleteLeaveForm({required String id}) {
    return TaskEither.tryCatch(
      () async {
        final response = await _client.post(
          APIs.LEAVE_DELETE,
          data: FormData.fromMap({'s_sn[]': id}),
          options: Options(headers: {'X-Requested-With': 'XMLHttpRequest'}),
        );
        return response;
      },
      (e, s) => Failure(
        message: 'Failed to delete form request: ${e.toString()}',
        status: 'delete_form_failed',
      ),
    );
  }

  TaskEither<Failure, List<WorkHour>> getWorkHour({
    required List<String> dates,
  }) {
    return TaskEither.tryCatch(
      () async {
        final userSn = LocalStorage.get<List<String>>(
          StorageKeys.userSn,
          defaultValue: [],
        );

        if (userSn.isEmpty) return [];

        final sn = UserSn(
          company: userSn[0],
          department: userSn[1],
          system: userSn[2],
        );

        final formData = FormData.fromMap({
          'action': 'getWorksHours',
          'employee': sn.system,
          'printeveryday': '1',
          'dates': dates,
        }, ListFormat.multiCompatible);

        final response = await _client.post(
          APIs.LEAVE_SYSTEM,
          data: formData,
          options: Options(headers: {'X-Requested-With': 'XMLHttpRequest'}),
        );

        final res = response.data as String;

        final jsonList = jsonDecode(res);

        final data = jsonList as List<dynamic>;

        final workHoursList =
            data
                .map((item) => WorkHour.fromJson(item as Map<String, dynamic>))
                .toList();

        return workHoursList;
      },
      (e, _) => Failure(message: e.toString(), status: 'get_work_hours_failed'),
    );
  }
}
