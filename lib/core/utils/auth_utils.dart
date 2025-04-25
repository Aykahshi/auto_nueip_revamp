import 'package:flutter/foundation.dart';
import 'package:joker_state/joker_state.dart';

import '../../data/models/auth_session.dart';
import '../../presentation/presenters/login_presenter.dart';
import '../config/storage_keys.dart';
import 'local_storage.dart';

sealed class AuthUtils {
  const AuthUtils._();

  static bool isLoggedIn() {
    final (companyCode, employeeId, password) = getCredentials();

    return companyCode.isNotEmpty &&
        employeeId.isNotEmpty &&
        password.isNotEmpty;
  }

  /// Save auth data to storage
  static Future<void> saveCredentials(
    String companyCode,
    String employeeId,
    String password,
  ) async {
    // ignore: no_leading_underscores_for_local_identifiers
    final (_companyCode, _employeeId, _password) = getCredentials();

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

  static Future<void> checkAuthSession() async {
    final loginPresenter = Circus.find<LoginPresenter>();

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
      Circus.spotlight<AuthSession>(tag: 'auth').whisper(session);
    }

    return !isExpired;
  }

  static AuthSession getAuthSession() {
    final session = Circus.spotlight<AuthSession>(tag: 'auth').state;

    return AuthSession(
      accessToken: session.accessToken,
      cookie: session.cookie,
      csrfToken: session.csrfToken,
    );
  }

  static (String companyCode, String employeeId, String password)
  getCredentials() {
    return (
      LocalStorage.get<String>(defaultValue: '', StorageKeys.companyCode),
      LocalStorage.get<String>(defaultValue: '', StorageKeys.employeeId),
      LocalStorage.get<String>(defaultValue: '', StorageKeys.password),
    );
  }

  /// Clear all auth data from storage
  static Future<void> clearCredentials() async {
    await Future.wait([
      LocalStorage.remove(StorageKeys.companyCode),
      LocalStorage.remove(StorageKeys.employeeId),
      LocalStorage.remove(StorageKeys.password),
    ]);
  }
}
