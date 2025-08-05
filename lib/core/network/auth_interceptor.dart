import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

/// 身份驗證攔截器
/// 當 API 返回 401 且包含特定訊息時，執行重新登入邏輯
class AuthInterceptor extends Interceptor {
  final Future<void> Function() onReauthenticate;

  AuthInterceptor({required this.onReauthenticate});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 檢查是否為 401 錯誤且包含重新登入訊息
    if (err.response?.statusCode == 401 &&
        _needReauthentication(err.response?.data)) {
      try {
        // 執行重新認證
        await onReauthenticate();

        // 重新執行原始請求
        final dio = Circus.find<Dio>();
        final response = await dio.request(
          err.requestOptions.uri.toString(),
          data: err.requestOptions.data,
          queryParameters: err.requestOptions.queryParameters,
          options: Options(
            method: err.requestOptions.method,
            headers: err.requestOptions.headers,
          ),
        );

        // 返回成功的回應
        handler.resolve(response);
        return;
      } catch (e) {
        // 重新認證失敗，繼續拋出原始錯誤
        debugPrint('重新認證失敗: $e');
      }
    }

    // 其他情況直接傳遞錯誤
    handler.next(err);
  }

  /// 檢查是否需要重新認證
  bool _needReauthentication(dynamic responseData) {
    if (responseData == null) return false;

    try {
      final dataString =
          responseData is String ? responseData : jsonEncode(responseData);

      return dataString.contains('請重新登入系統') ||
          dataString.contains(
            '\\u8acb\\u91cd\\u65b0\\u767b\\u5165\\u7cfb\\u7d71',
          );
    } catch (e) {
      return false;
    }
  }
}
