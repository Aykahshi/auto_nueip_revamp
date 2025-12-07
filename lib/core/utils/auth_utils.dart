import 'package:flutter/foundation.dart';
import 'package:joker_state/joker_state.dart';

import '../../features/login/data/models/auth_session.dart';
import '../../features/login/presentation/presenters/login_presenter.dart';
import '../config/storage_keys.dart';
import '../network/api_client.dart';
import 'local_storage.dart';

sealed class AuthUtils {
  const AuthUtils._();

  static bool isLoggedIn() {
    final (companyCode, employeeId, password, _) = getCredentials();

    return companyCode.isNotEmpty &&
        employeeId.isNotEmpty &&
        password.isNotEmpty &&
        isAuthSessionValid();
  }

  static Future<void> resetAuthSession() async {
    await LocalStorage.remove(StorageKeys.authSession);
    Circus.find<ApiClient>().clearAuthSession();
  }

  /// Save auth data to storage
  static Future<void> saveCredentials(
    String companyCode,
    String employeeId,
    String password,
  ) async {
    // ignore: no_leading_underscores_for_local_identifiers
    final (_companyCode, _employeeId, _password, _) = getCredentials();

    if (_companyCode == companyCode &&
        _employeeId == employeeId &&
        _password == password) {
      return;
    }

    try {
      await Future.wait([
        LocalStorage.set(StorageKeys.companyCode, companyCode),
        LocalStorage.set(StorageKeys.employeeId, employeeId),
        LocalStorage.set(StorageKeys.password, password),
      ]);
      debugPrint('Credentials saved successfully.');
    } catch (e) {
      debugPrint('Failed to save credentials: $e');
    }
  }

  static Future<void> checkAuthSession({bool force = false}) async {
    final loginPresenter = Circus.find<LoginPresenter>();

    if (force) {
      await resetAuthSession();
      final (companyCode, employeeId, password, _) = getCredentials();
      await loginPresenter.login(
        companyCode: companyCode,
        employeeId: employeeId,
        password: password,
      );
      return;
    }

    await loginPresenter.init();
  }

  static bool isAuthSessionValid() {
    final sessionStr = LocalStorage.get<List<String>>(
      defaultValue: [],
      StorageKeys.authSession,
    );

    if (sessionStr.isEmpty) return false;

    final session = AuthSession(
      accessToken: sessionStr[0],
      cookie: sessionStr[1],
      csrfToken: sessionStr[2],
      expiryTime: DateTime.parse(sessionStr[3]),
    );

    final bool isExpired = session.isTokenExpired();

    if (!isExpired) {
      Circus.find<Joker<AuthSession>>('auth').trick(session);
    }

    return !isExpired;
  }

  static Future<void> updateAuthSession(
    AuthSession session, {
    bool isBackground = false,
  }) async {
    Circus.find<Joker<AuthSession>>('auth').trick(session);

    Circus.find<ApiClient>().updateAuthSession(session);

    await LocalStorage.set<List<String>>(StorageKeys.authSession, [
      session.accessToken ?? '',
      session.cookie ?? '',
      session.csrfToken ?? '',
      session.expiryTime.toString(),
    ]);
  }

  static AuthSession getAuthSession({bool isBackground = false}) {
    if (isBackground) {
      final sessionStr = LocalStorage.get<List<String>>(
        StorageKeys.authSession,
        defaultValue: [],
      );

      final session = AuthSession(
        accessToken: sessionStr[0],
        cookie: sessionStr[1],
        csrfToken: sessionStr[2],
        expiryTime: DateTime.parse(sessionStr[3]),
      );

      return session;
    }

    final session = Circus.find<Joker<AuthSession>>('auth').state;

    return AuthSession(
      accessToken: session.accessToken,
      cookie: session.cookie,
      csrfToken: session.csrfToken,
    );
  }

  static (
    String companyCode,
    String employeeId,
    String password,
    String companyAddress,
  )
  getCredentials() {
    return (
      LocalStorage.get<String>(defaultValue: '', StorageKeys.companyCode),
      LocalStorage.get<String>(defaultValue: '', StorageKeys.employeeId),
      LocalStorage.get<String>(defaultValue: '', StorageKeys.password),
      LocalStorage.get<String>(defaultValue: '', StorageKeys.companyAddress),
    );
  }

  /// Clear all auth data from storage
  static Future<void> clearCredentials() async {
    await Future.wait([
      LocalStorage.remove(StorageKeys.authSession),
      LocalStorage.remove(StorageKeys.companyCode),
      LocalStorage.remove(StorageKeys.employeeId),
      LocalStorage.remove(StorageKeys.password),
      LocalStorage.remove(StorageKeys.companyAddress),
    ]);
  }
}
