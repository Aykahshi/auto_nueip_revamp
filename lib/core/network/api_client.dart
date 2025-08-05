import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:joker_state/joker_state.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../features/login/data/models/auth_session.dart';
import '../config/api_config.dart';
import '../utils/auth_utils.dart';
import 'auth_interceptor.dart';
import 'content_type_transformer.dart';
import 'login_interceptor.dart';

/// ApiClient is a wrapper for Dio that manages cookies automatically.
class ApiClient {
  final Dio _dio;
  final CookieJar _cookieJar;

  CookieJar get cookieJar => _cookieJar;

  ApiClient()
    : _dio = Dio(
        BaseOptions(
          headers: ApiConfig.HEADERS,
          followRedirects: false,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      ),
      _cookieJar = CookieJar() {
    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.interceptors.add(LoginInterceptor());
    _dio.transformer = ContentTypeTransformer();

    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
        ),
      );
    }

    Circus.hire<Dio>(_dio);

    _dio.interceptors.add(
      AuthInterceptor(
        onReauthenticate: () async {
          await AuthUtils.checkAuthSession(force: true);
        },
      ),
    );
  }

  void updateAuthSession(AuthSession session) {
    _dio.options.headers['Cookie'] = session.cookie;
    _dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
  }

  void clearAuthSession() {
    _dio.options.headers['Cookie'] = '';
    _dio.options.headers['Authorization'] = '';
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
