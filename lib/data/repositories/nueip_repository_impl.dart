import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:joker_state/joker_state.dart';

import '../../core/network/failure.dart';
import '../../domain/repositories/nueip_repository.dart';
import '../services/nueip_services.dart';

class NueipRepositoryImpl implements NueipRepository {
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
}
