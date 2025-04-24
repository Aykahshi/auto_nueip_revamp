import 'package:flutter/foundation.dart';
import 'package:joker_state/joker_state.dart';

import '../../data/models/auth_session.dart';
import '../config/storage_keys.dart';
import 'local_storage.dart';

sealed class AuthUtils {
  const AuthUtils._();

  static bool isLoggedIn() {
    return [
      _getEmployeeId().isNotEmpty,
      _getCompanyCode().isNotEmpty,
      _getPassword().isNotEmpty,
    ].contains(true);
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

  /// Get the current EmployeeId from storage
  static String _getEmployeeId() {
    return LocalStorage.get<String>(defaultValue: '', StorageKeys.employeeId);
  }

  /// Get the current companyCode from storage
  static String _getCompanyCode() {
    return LocalStorage.get<String>(defaultValue: '', StorageKeys.companyCode);
  }

  /// Get the current password from storage
  static String _getPassword() {
    return LocalStorage.get<String>(defaultValue: '', StorageKeys.password);
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
