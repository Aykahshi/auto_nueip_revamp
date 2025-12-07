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

  /// Key for storing the user number.
  static const String userNo = 'user_no';

  /// Key for storing the notifications enabled.
  static const String notificationsEnabled = 'notifications_enabled';

  /// Key for storing the dark mode enabled.
  static const String darkModeEnabled = 'dark_mode_enabled';

  /// Key for storing the auth session.
  static const String authSession = 'auth_session';

  /// Key for storing the company address.
  static const String companyAddress = 'company_address';

  /// Key for storing the company address latitude.
  static const String companyLatitude = 'company_latitude';

  /// Key for storing the company address longitude.
  static const String companyLongitude = 'company_longitude';

  /// Key for storing the user SN.
  static const String userSn = 'user_sn';

  /// Key for storing the work hours start time (e.g., 9:00).
  static const String workHoursStart = 'work_hours_start';

  /// Key for storing the work hours end time (e.g., 18:00).
  static const String workHoursEnd = 'work_hours_end';

  /// Key for storing the clock-in time in milliseconds (e.g., 8:40).
  static const String clockInTime = 'clock_in_time';

  /// Key for storing the clock-out time in milliseconds (e.g., 17:40).
  static const String clockOutTime = 'clock_out_time';

  /// Key for storing the flexible duration in minutes.
  static const String flexibleDuration = 'flexible_duration';

  /// Key for storing the random time range in minutes.
  static const String randomTimeRange = 'random_time_range';

  /// Key for storing the service enabled status.
  static const String serviceEnabled = 'service_enabled';

  /// Key for storing the next check-in time in milliseconds.
  static const String nextClockInTime = 'next_clock_in_time';

  /// Key for storing the next check-out time in milliseconds.
  static const String nextClockOutTime = 'next_clock_out_time';

  /// Key for storing the stop flag.
  static const String stopFlag = 'service_stopping';

  /// Key for storing whether the user has triggered the secret feature.
  static const String secretFeatureTriggered = 'secret_feature_triggered';

  /// Key for storing whether GPS clock-in is enabled.
  static const String gpsClockInEnabled = 'gps_clock_in_enabled';
}
