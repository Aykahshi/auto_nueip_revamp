import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/network/failure.dart';
import '../../../form/data/models/employee_list.dart';
import '../../../form/data/models/form_type_enum.dart';
import '../../../form/data/models/leave_record.dart';
import '../../../form/data/models/leave_sign_data.dart';
import '../../../form/data/models/work_hour.dart';
import '../../../form/domain/entities/leave_rule.dart';
import '../../../home/data/models/notice.dart';
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

  TaskEither<Failure, Map<String, (String?, List<Employee>)>> getEmployees();

  TaskEither<Failure, List<LeaveRule>> getLeaveRules();

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

  TaskEither<Failure, Response> sendLeaveForm({
    required String ruleId,
    required String startDate,
    required String endDate,
    required List<(String date, String start, String end, int hour, int min)>
    leaveEntries,
    required (String id, String sn) agent,
    required String remark,
    List<File>? files,
    required String cookie,
  });

  TaskEither<Failure, Response> deleteLeaveForm({required String id});

  TaskEither<Failure, List<WorkHour>> getWorkHour({
    required List<String> dates,
  });

  TaskEither<Failure, List<Notice>> getNoticeList([int page = 1]);
}
