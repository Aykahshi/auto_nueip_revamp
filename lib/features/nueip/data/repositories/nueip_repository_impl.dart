import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:joker_state/joker_state.dart';

import '../../../../core/network/failure.dart';
import '../../../form/data/models/employee_list.dart';
import '../../../form/data/models/form_type_enum.dart';
import '../../../form/data/models/leave_record.dart';
import '../../../form/data/models/leave_sign_data.dart';
import '../../../form/data/models/work_hours.dart';
import '../../../form/domain/entities/leave_rule.dart';
import '../../domain/repositories/nueip_repository.dart';
import '../models/user_sn.dart';
import '../services/nueip_services.dart';

final class NueipRepositoryImpl implements NueipRepository {
  final NueipService _service;

  NueipRepositoryImpl({NueipService? service})
    : _service = service ?? Circus.find<NueipService>();

  @override
  TaskEither<Failure, Response> login({
    required String company,
    required String id,
    required String password,
  }) {
    return _service.login(company: company, id: id, password: password);
  }

  @override
  TaskEither<Failure, Response> clockAction({
    required String method,
    required String cookie,
    required String csrfToken,
    required double latitude,
    required double longitude,
  }) {
    return _service.clockAction(
      method: method,
      cookie: cookie,
      csrfToken: csrfToken,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  TaskEither<Failure, Response> getOauthToken({required String cookie}) {
    return _service.getOauthToken(cookie: cookie);
  }

  @override
  TaskEither<Failure, Response> getClockTime({
    required String accessToken,
    required String cookie,
  }) {
    return _service.getClockTime(accessToken: accessToken, cookie: cookie);
  }

  @override
  TaskEither<Failure, Response> getDailyAttendanceRecord({
    required String date,
    required String cookie,
  }) {
    return _service.getDailyAttendanceRecord(date: date, cookie: cookie);
  }

  @override
  TaskEither<Failure, Response> getAttendanceRecords({
    required String startDate,
    required String endDate,
    required String cookie,
  }) {
    return _service.getAttendanceRecords(
      startDate: startDate,
      endDate: endDate,
      cookie: cookie,
    );
  }

  @override
  TaskEither<Failure, Response> getUserInfo() {
    return _service.getUserInfo();
  }

  @override
  TaskEither<Failure, Map<String, (String?, List<Employee>)>> getEmployees() {
    return _service.getEmployees();
  }

  @override
  TaskEither<Failure, List<WorkHours>> getWorkHours({
    required List<String> dates,
    required String employeeId,
  }) {
    return _service.getWorkHours(dates: dates, employeeId: employeeId);
  }

  @override
  TaskEither<Failure, List<LeaveRule>> getLeaveRules() {
    return _service.getLeaveRules();
  }

  @override
  TaskEither<Failure, List<LeaveRecord>> getLeaveRecords({
    required String employee,
    required String startDate,
    required String endDate,
    required String cookie,
  }) {
    return _service.getLeaveRecords(
      employee: employee,
      startDate: startDate,
      endDate: endDate,
      cookie: cookie,
    );
  }

  @override
  TaskEither<Failure, UserSn> getUserSn() {
    return _service.getUserSn();
  }

  @override
  TaskEither<Failure, LeaveSignData> getLeaveSignData({
    required FormType type,
    required String id,
  }) {
    return _service.getLeaveSignData(type: type, id: id);
  }

  @override
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
    return _service.sendLeaveForm(
      ruleId: ruleId,
      startDate: startDate,
      endDate: endDate,
      startTime: startTime,
      endTime: endTime,
      hours: hours,
      minutes: minutes,
      agentId: agentId,
      remark: remark,
      files: files,
      cookie: cookie,
    );
  }
}
