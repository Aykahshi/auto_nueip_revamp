// ignore_for_file: constant_identifier_names

import 'api_config.dart';

sealed class APIs {
  static const String _BASE = ApiConfig.BASE_URL;
  static const String _RD_BASE = 'https://rd2-api.nueip.com';
  static const String _PORTAL_BASE = 'https://portal-api.nueip.com';
  static const String INFO = '$_PORTAL_BASE/system/basic-info';
  static const String LOGIN = '$_BASE/login/index/param';
  static const String CLOCK = '$_BASE/time_clocks/ajax';
  static const String PUNCH_DIALOG = '$_BASE/widget/punch_prompt_dialog/ajax';
  static const String TOKEN = '$_BASE/oauth2/token/api';
  static const String RECORD = '$_BASE/portal/Portal_punch_clock/ajax';
  static const String ATTENDANCE = '$_BASE/attendance_record/ajax';
  static const String USER_SN = '$_BASE/widget/deptChain/getUserDeptMap';
  static const String EMPLOYEE_LIST = '$_BASE/shared/org3layermenu_ajax';
  static const String LEAVE_SYSTEM =
      '$_BASE/leave_application/personal_leave_application_user';
  static const String LEAVE_RULES = '$LEAVE_SYSTEM/getLeaveList';
  static const String NOTICE = '$_RD_BASE/center/notice';
  static const String SIGN_DATA = '$_BASE/leader_audit_work_list/getSignData';
  static const String HOLIDAY =
      'https://cdn.jsdelivr.net/gh/ruyut/TaiwanCalendar/data/';
}
