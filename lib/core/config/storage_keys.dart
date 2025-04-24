/// Sealed class containing static constants for local storage keys.
sealed class StorageKeys {
  /// Key for storing the company code.
  static const String companyCode = 'company_code';

  /// Key for storing the employee ID.
  static const String employeeId = 'employee_id';

  /// Key for storing the user's password (UNSECURE, use with caution!).
  static const String password = 'password';

  /// Key for storing the fetched holiday list.
  static const String holidays = 'holidays';

  /// Key for storing the username.
  static const String username = 'username';

  /// Key for storing the user number.
  static const String userNo = 'user_no';

  /// Key for storing the notifications enabled.
  static const String notificationsEnabled = 'notifications_enabled';

  /// Key for storing the dark mode enabled.
  static const String darkModeEnabled = 'dark_mode_enabled';
}
