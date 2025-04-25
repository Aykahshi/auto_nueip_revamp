import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:joker_state/joker_state.dart';

import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/failure.dart';

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
}
