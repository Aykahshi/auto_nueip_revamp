import 'package:cookie_jar/cookie_jar.dart' show Cookie;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:joker_state/joker_state.dart';

import '../../data/models/auth_session.dart';
import '../../data/repositories/nueip_repository_impl.dart';
import '../config/api_config.dart';
import '../extensions/cookie_parser.dart';
import '../extensions/htmlx.dart';
import '../network/api_client.dart';
import 'auth_utils.dart';

final class NueipHelper {
  String? _redirectUrl;
  String? _accessToken;
  DateTime? _expiryTime;
  String? _cookie;
  String? _crsfToken;

  set redirectUrl(String url) => _redirectUrl = url;

  String get redirectUrl => _redirectUrl ?? '';

  Future<void> getCookieAndToken() async {
    await _getCookie();
    await _getCrsfToken();
    await _getOauthToken();
    final AuthSession session = AuthSession(
      accessToken: _accessToken,
      cookie: _cookie,
      csrfToken: _crsfToken,
      expiryTime: _expiryTime,
    );

    await AuthUtils.updateAuthSession(session);
  }

  Future<void> _getCrsfToken() async {
    try {
      final client = Circus.find<ApiClient>();

      final res = await client.get(
        _redirectUrl!,
        options: Options(headers: {'Cookie': _cookie}),
      );

      final html = res.data as String;

      final token = html.extractToken();

      _crsfToken = token;

      debugPrint('NueipHelper getCrsfToken: $_crsfToken');
    } catch (e) {
      debugPrint('NueipHelper getCrsfToken failed: $e');
    }
  }

  Future<void> _getCookie() async {
    try {
      final cookieJar = Circus.find<ApiClient>().cookieJar;
      final List<Cookie> cookies = await cookieJar.loadForRequest(
        Uri.parse(ApiConfig.LOGIN_URL),
      );
      final String cookie = cookies.parse();

      _cookie = cookie;

      debugPrint('NueipHelper getCookie: $_cookie');
    } catch (e) {
      debugPrint('NueipHelper getCookie failed: $e');
    }
  }

  Future<void> _getOauthToken() async {
    final repository = Circus.find<NueipRepositoryImpl>();

    final result = await repository.getOauthToken(cookie: _cookie ?? '').run();

    result.fold(
      (faulure) {
        debugPrint('NueipHelper getOauthToken failed: ${faulure.message}');
      },
      (res) async {
        final String accessToken = res.data['token_access_token'];
        final int expiresIn = res.data['token_expires_in'] as int;
        final DateTime expiryTime = DateTime.now().add(
          Duration(seconds: expiresIn),
        );

        _accessToken = accessToken;
        _expiryTime = expiryTime;

        debugPrint('NueipHelper getOauthToken: $accessToken');
      },
    );
  }
}
