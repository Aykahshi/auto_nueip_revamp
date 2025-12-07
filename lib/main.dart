import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'core/config/storage_keys.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/global_presenter.dart';
import 'core/utils/local_storage.dart';
import 'core/utils/notification.dart';
import 'core/utils/nueip_helper.dart';
import 'features/calendar/presentation/presenters/attendance_presenter.dart';
import 'features/form/presentation/presenters/apply_form_presenter.dart';
import 'features/form/presentation/presenters/apply_form_ui_presenter.dart';
import 'features/form/presentation/presenters/date_range_presenter.dart';
import 'features/form/presentation/presenters/leave_record_presenter.dart';
import 'features/form/presentation/presenters/sign_presenter.dart';
import 'features/holiday/data/repositories/holiday_repository_impl.dart';
import 'features/holiday/data/services/holiday_service.dart';
import 'features/holiday/domain/repositories/holiday_repository.dart';
import 'features/holiday/presentation/presenters/holiday_presenter.dart';
import 'features/home/presentation/presenters/clock_presenter.dart';
import 'features/home/presentation/presenters/notice_presenter.dart';
import 'features/login/data/models/auth_session.dart';
import 'features/login/presentation/presenters/login_presenter.dart';
import 'features/nueip/data/repositories/nueip_repository_impl.dart';
import 'features/nueip/data/services/nueip_services.dart';
import 'features/nueip/domain/repositories/nueip_repository.dart';
import 'features/setting/presentation/presenters/profile_editing_presenter.dart';
import 'features/setting/presentation/presenters/setting_presenter.dart';
import 'index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStorage.init();

  // Initialize timezone database
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Taipei'));

  await _initDependencies();

  await NotificationUtils.init();

  runApp(const App());
}

Future<void> _initDependencies() async {
  // Add router registration
  Circus.hire<AppRouter>(AppRouter());

  // Add AuthSession Joker registration
  Circus.hire(Joker<AuthSession>(const AuthSession()), tag: 'auth');

  // Add GlobalPresenter registration
  Circus.hire(GlobalPresenter());

  // Add Company Address Joker registration
  final initialAddress = LocalStorage.get<String>(
    StorageKeys.companyAddress,
    defaultValue: '',
  );

  Circus.hire(
    Joker<String>(initialAddress, keepAlive: true),
    tag: 'companyAddress',
  );

  // Add API features registration
  Circus
    ..hire<ApiClient>(ApiClient())
    ..hire<NueipHelper>(NueipHelper())
    ..contract<NueipService>(() => NueipService())
    ..hireLazily<NueipRepositoryImpl>(
      () => NueipRepositoryImpl(),
      alias: NueipRepository,
    )
    ..bindDependency<NueipRepository, NueipService>();

  // Add API features registration
  Circus
    ..contract<HolidayService>(() => HolidayService())
    ..hireLazily<HolidayRepositoryImpl>(
      () => HolidayRepositoryImpl(),
      alias: HolidayRepository,
    )
    ..bindDependency<HolidayRepository, HolidayService>();

  // Add Presenters registration
  Circus
    ..hireLazily<HolidayPresenter>(() => HolidayPresenter())
    ..hireLazily<AttendancePresenter>(() => AttendancePresenter())
    ..hireLazily<NoticePresenter>(() => NoticePresenter())
    ..hireLazily<LoginPresenter>(() => LoginPresenter())
    ..hireLazily<SettingPresenter>(() => SettingPresenter())
    ..hireLazily<LeaveRecordPresenter>(() => LeaveRecordPresenter())
    ..contract<ClockPresenter>(() => ClockPresenter())
    ..contract<SignPresenter>(() => SignPresenter())
    ..contract<ApplyFormPresenter>(() => ApplyFormPresenter())
    ..contract<ApplyFormUiPresenter>(() => ApplyFormUiPresenter())
    ..contract<DateRangePresenter>(() => DateRangePresenter())
    ..contract<ProfileEditingPresenter>(() => ProfileEditingPresenter());

  // Add theme mode Joker registration
  Circus.hire(Joker<AppThemeMode>(AppThemeMode.light), tag: 'themeMode');
}
