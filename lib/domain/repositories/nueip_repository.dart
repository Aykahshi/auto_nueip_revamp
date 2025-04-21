import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/network/failure.dart';

abstract class NueipRepository {
  TaskEither<Failure, Response> login({
    required String company,
    required String id,
    required String password,
  });

  TaskEither<Failure, Response> punchAction({
    required String method,
    required String cookie,
    required String csrfToken,
    required double latitude,
    required double longitude,
  });

  TaskEither<Failure, Response> getOauthToken({required String cookie});

  TaskEither<Failure, Response> getPunchTime({
    required String accessToken,
    required String cookie,
  });

  TaskEither<Failure, Response> getDailyLogs({
    required String date,
    required String cookie,
  });
}
