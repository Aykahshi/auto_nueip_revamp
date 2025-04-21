/// Sealed class containing static constants for local storage keys.
sealed class StorageKeys {
  /// Key for storing the company code.
  static const String companyCode = 'company_code';

  /// Key for storing the employee ID.
  static const String employeeId = 'employee_id';

  /// Key for storing the user's password (UNSECURE, use with caution!).
  static const String password = 'password';

  // Add other keys here as needed, for example:
  // static const String sessionCookie = 'session_cookie';
  // static const String accessToken = 'access_token';
}
