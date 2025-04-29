import 'dart:io' show File;

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:joker_state/joker_state.dart';

import '../../core/config/api_config.dart';
import '../../core/config/storage_keys.dart';
import '../../core/network/api_client.dart';
import '../../core/network/failure.dart';
import '../../core/utils/local_storage.dart';
import '../models/employee_list.dart';
import '../models/form_type_enum.dart';
import '../models/leave_record.dart';
import '../models/leave_sign_data.dart';
import '../models/user_sn.dart';
import '../models/work_hours.dart';

class NueipService {
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
      () async => await _client.post(ApiConfig.LOGIN_URL, data: body),
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
        ApiConfig.CLOCK_URL,
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
        ApiConfig.TOKEN_URL,
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
        ApiConfig.RECORD_URL,
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
        ApiConfig.ATTENDANCE_URL,
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
        ApiConfig.ATTENDANCE_URL,
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
      () async => await _client.get(ApiConfig.INFO_URL),
      (e, _) => Failure(message: e.toString(), status: 'info_failed'),
    );
  }

  TaskEither<Failure, Map<String, List<Employee>>> getEmployees() {
    return TaskEither.tryCatch(
      () async {
        final Map<String, dynamic> payload = {
          'single_select': 1,
          'all_user': 1,
          'work_status': 1,
        };

        final response = await _client.post(
          ApiConfig.EMPLOYEE_LIST_URL,
          data: payload,
        );

        final responseData = response.data as Map<String, dynamic>;
        final companyList =
            responseData['company_list'] as Map<String, dynamic>;

        final firstCompanyKey = companyList.keys.first;
        final firstCompany =
            companyList[firstCompanyKey] as Map<String, dynamic>;

        final deptList = firstCompany['dept_list'] as Map<String, dynamic>;

        final Map<String, List<Employee>> departmentEmployees = {};

        for (final deptEntry in deptList.entries) {
          final dept = Department.fromJson(
            deptEntry.value as Map<String, dynamic>,
          );
          final deptName = dept.title ?? '查無此部門';

          if (dept.userList != null && dept.userList!.isNotEmpty) {
            final employeesList = dept.userList!.values.toList();
            departmentEmployees[deptName] = employeesList;
          } else {
            departmentEmployees[deptName] = [];
          }
        }

        return departmentEmployees;
      },
      (e, _) => Failure(
        message: e.toString(),
        status: 'get_employees_by_department_failed',
      ),
    );
  }

  TaskEither<Failure, List<String>> getLeaveRules() {
    return TaskEither.tryCatch(
      () async {
        final userNo = LocalStorage.get<String>(
          StorageKeys.userNo,
          defaultValue: '',
        );

        if (userNo.isEmpty) return [];

        final response = await _client.get(
          ApiConfig.LEAVE_RULES_URL,
          queryParameters: {'user_no': userNo},
        );

        final responseData = response.data as Map<String, dynamic>;
        final data = responseData['data'] as Map<String, dynamic>;

        final List<String> leaveTypes = [];

        data.forEach((_, outerValue) {
          if (outerValue is Map<String, dynamic>) {
            outerValue.forEach((_, innerValue) {
              if (innerValue is String) {
                leaveTypes.add(innerValue);
              }
            });
          }
        });

        return leaveTypes;
      },
      (e, _) =>
          Failure(message: e.toString(), status: 'get_leave_types_failed'),
    );
  }

  TaskEither<Failure, List<WorkHours>> getWorkHours({
    required List<String> dates,
    required String employeeId,
  }) {
    return TaskEither.tryCatch(
      () async {
        final userNo = LocalStorage.get<String>(
          StorageKeys.userNo,
          defaultValue: '',
        );

        if (userNo.isEmpty) return [];

        final formData = {
          'action': 'getWorksHours',
          'employee': userNo,
          'printeveryday': '1',
        };

        final request = FormData();
        for (final entry in formData.entries) {
          request.fields.add(MapEntry(entry.key, entry.value));
        }

        for (final date in dates) {
          request.fields.add(MapEntry('dates[]', date));
        }

        final response = await _client.post(ApiConfig.LEAVE_URL, data: request);

        final List<dynamic> data = response.data as List<dynamic>;

        final workHoursList =
            data
                .map((item) => WorkHours.fromJson(item as Map<String, dynamic>))
                .toList();

        return workHoursList;
      },
      (e, _) => Failure(message: e.toString(), status: 'get_work_hours_failed'),
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
          ApiConfig.LEAVE_URL,
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
      final response = await _client.post(ApiConfig.USER_SN_URL);

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
          ApiConfig.SIGN_DATA_URL,
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
    required String startTime,
    required String endTime,
    required int hours,
    required int minutes,
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

        formData.fields.addAll([
          MapEntry('myFLayer', ruleId),
          MapEntry('leave[0][start]', startTime),
          MapEntry('leave[0][end]', endTime),
          MapEntry('leave[0][hour]', hours.toString()),
          MapEntry('leave[0][min]', minutes.toString()),
          MapEntry('leave[0][date]', startDate),
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

        final response = await _client.post(
          ApiConfig.LEAVE_URL,
          data: formData,
          options: Options(headers: {'X-Requested-With': 'XMLHttpRequest'}),
        );
        return response;
      },
      (e, s) => Failure(
        message: 'Failed to send form request: ${e.toString()}',
        status: 'send_form_failed',
      ),
    );
  }
}
