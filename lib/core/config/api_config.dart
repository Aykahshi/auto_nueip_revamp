// ignore_for_file: constant_identifier_names
sealed class ApiConfig {
  const ApiConfig._();

  static const String BASE_URL = 'https://cloud.nueip.com';
  static const String INFO_URL =
      'https://portal-api.nueip.com/system/basic-info';
  static const String LOGIN_URL = '$BASE_URL/login/index/param';
  static const String CLOCK_URL = '$BASE_URL/time_clocks/ajax';
  static const String TOKEN_URL = '$BASE_URL/oauth2/token/api';
  static const String RECORD_URL = '$BASE_URL/portal/Portal_punch_clock/ajax';
  static const String ATTENDANCE_URL = '$BASE_URL/attendance_record/ajax';
  static const String INBOX_URL = '$BASE_URL/shared/getMessage';
  static const String LEAVE_URL =
      '$BASE_URL/leave_application/personal_leave_application_user/getLeaveList';
  static const String UNREAD_URL =
      'https://rd2-api.nueip.com/center/notice/get-unread';
  static const String ANNOUNCEMENT_URL =
      'https://rd2-api.nueip.com/center/notice';
  static const String HOLIDAY_URL =
      'https://cdn.jsdelivr.net/gh/ruyut/TaiwanCalendar/data/';

  static const String GOOGLE_API_KEY = 'API_KEY_HERE';
  static const String GOOGLE_GEOCODING_URL =
      'https://maps.googleapis.com/maps/api/geocode/json?';

  static const Map<String, String> HEADERS = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
  };
}
