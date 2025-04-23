import 'package:flutter/foundation.dart';

import '../config/storage_keys.dart';
import 'local_storage.dart';

sealed class AuthUtils {
  const AuthUtils._();

  static bool isLoggedIn() {
    return [
      getEmployeeId().isNotEmpty,
      getCompanyCode().isNotEmpty,
      getPassword().isNotEmpty,
    ].contains(true);
  }

  /// Save auth data to storage
  static Future<void> saveCredentials(
    String companyCode,
    String employeeId,
    String password,
  ) async {
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

  /// Get the current EmployeeId from storage
  static String getEmployeeId() {
    return LocalStorage.get<String>(defaultValue: '', StorageKeys.employeeId);
  }

  /// Get the current companyCode from storage
  static String getCompanyCode() {
    return LocalStorage.get<String>(defaultValue: '', StorageKeys.companyCode);
  }

  /// Get the current password from storage
  static String getPassword() {
    return LocalStorage.get<String>(defaultValue: '', StorageKeys.password);
  }

  /// Set the current EmployeeId to storage
  static Future<void> setEmployeeId(String? userId) async {
    await LocalStorage.set(StorageKeys.employeeId, userId);
  }

  /// Set the current companyCode to storage
  static Future<void> setCompanyCode(String? companyCode) async {
    await LocalStorage.set(StorageKeys.companyCode, companyCode);
  }

  /// Set the current Password to storage
  static Future<void> setPassword(String? companyCode) async {
    await LocalStorage.set(StorageKeys.password, companyCode);
  }

  /// Clear all auth data from storage
  static Future<void> clear() async {
    await Future.wait([
      LocalStorage.remove(StorageKeys.companyCode),
      LocalStorage.remove(StorageKeys.employeeId),
      LocalStorage.remove(StorageKeys.password),
    ]);
  }
}
