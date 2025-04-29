import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/network/failure.dart';
import '../../data/models/employee_list.dart';
import '../../data/models/form_type_enum.dart';
import '../../data/models/leave_record.dart';
import '../../data/models/leave_sign_data.dart';
import '../../data/models/user_sn.dart';

abstract class NueipRepository {
  TaskEither<Failure, Response> login({
    required String company,
    required String id,
    required String password,
  });

  TaskEither<Failure, Response> clockAction({
    required String method,
    required String cookie,
    required String csrfToken,
    required double latitude,
    required double longitude,
  });

  TaskEither<Failure, Response> getOauthToken({required String cookie});

  TaskEither<Failure, Response> getClockTime({
    required String accessToken,
    required String cookie,
  });

  TaskEither<Failure, Response> getDailyAttendanceRecord({
    required String date,
    required String cookie,
  });

  TaskEither<Failure, Response> getAttendanceRecords({
    required String startDate,
    required String endDate,
    required String cookie,
  });

  TaskEither<Failure, Response> getUserInfo();

  TaskEither<Failure, Map<String, List<Employee>>> getEmployees();

  TaskEither<Failure, List<String>> getLeaveRules();

  TaskEither<Failure, List<LeaveRecord>> getLeaveRecords({
    required String employee,
    required String startDate,
    required String endDate,
    required String cookie,
  });

  TaskEither<Failure, UserSn> getUserSn();

  TaskEither<Failure, LeaveSignData> getLeaveSignData({
    required FormType type,
    required String id,
  });
}
