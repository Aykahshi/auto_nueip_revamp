import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:joker_state/joker_state.dart';

import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/failure.dart';

class NueipService {
  final ApiClient _client;

  NueipService({ApiClient? client})
    : _client = client ?? Circus.find<ApiClient>();

  TaskEither<LoginFailure, Response> login({
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
      (e, _) {
        // Handle DioException specifically for LoginFailure
        if (e is DioException && e.error is Map<String, dynamic>) {
          final errorDetails = e.error as Map<String, dynamic>;
          LoginErrors? loginErrors;

          try {
            // Assuming the API directly returns the LoginErrors structure
            // within the `errors` field provided to DioException.error
            loginErrors = LoginErrors.fromJson(errorDetails);
          } catch (parseError) {
            // If parsing LoginErrors fails, keep it null
            debugPrint(
              'Failed to parse LoginErrors: $parseError, Details: $errorDetails',
            );
            loginErrors = null;
          }

          if (errorDetails.containsKey('company')) {
            return LoginFailure.invalidCompany(errData: loginErrors);
          } else if (errorDetails.containsKey('user')) {
            return LoginFailure.userNotFound(errData: loginErrors);
          } else if (errorDetails.containsKey('pwd')) {
            return LoginFailure.wrongPassword(errData: loginErrors);
          } else {
            // Unknown structure within "status: fail"
            return LoginFailure.unknown(
              errData: errorDetails, // Pass raw details if parsing failed
            );
          }
        } else if (e is DioException) {
          // Other DioExceptions during login process
          return LoginFailure.unknown(errData: e);
        }
        // Non-Dio exceptions during login process
        return LoginFailure.unknown(errData: e);
      },
    );
  }

  TaskEither<Failure, Response> punchAction({
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
        status: 'error',
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
        status: 'error',
      ), // Provide default status
    );
  }

  TaskEither<Failure, Response> getPunchTime({
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
        status: 'error',
      ), // Provide default status
    );
  }

  TaskEither<Failure, Response> getDailyLogs({
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
        ApiConfig.DAILY_LOG_URL,
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
        status: 'error',
      ), // Provide default status
    );
  }
}
