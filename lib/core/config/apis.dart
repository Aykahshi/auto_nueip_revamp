// ignore_for_file: constant_identifier_names

import 'api_config.dart';

sealed class APIs {
  static const String INFO = 'https://portal-api.nueip.com/system/basic-info';
  static const String LOGIN = '${ApiConfig.BASE_URL}/login/index/param';
  static const String CLOCK = '${ApiConfig.BASE_URL}/time_clocks/ajax';
  static const String TOKEN = '${ApiConfig.BASE_URL}/oauth2/token/api';
  static const String RECORD =
      '${ApiConfig.BASE_URL}/portal/Portal_punch_clock/ajax';
  static const String ATTENDANCE =
      '${ApiConfig.BASE_URL}/attendance_record/ajax';
  static const String INBOX = '${ApiConfig.BASE_URL}/shared/getMessage';
  static const String USER_SN =
      '${ApiConfig.BASE_URL}/widget/deptChain/getUserDeptMap';
  static const String EMPLOYEE_LIST =
      '${ApiConfig.BASE_URL}/shared/org3layermenu_ajax';
  static const String LEAVE_SYSTEM =
      '${ApiConfig.BASE_URL}/leave_application/personal_leave_application_user';
  static const String LEAVE_RULES = '$LEAVE_SYSTEM/getLeaveList';
  static const String LEAVE_DELETE = '$LEAVE_SYSTEM/validate_delete';
  static const String UNREAD =
      'https://rd2-api.nueip.com/center/notice/get-unread';
  static const String ANNOUNCEMENT = 'https://rd2-api.nueip.com/center/notice';
  static const String SIGN_DATA =
      '${ApiConfig.BASE_URL}/leader_audit_work_list/getSignData';
  static const String HOLIDAY =
      'https://cdn.jsdelivr.net/gh/ruyut/TaiwanCalendar/data/';
}
