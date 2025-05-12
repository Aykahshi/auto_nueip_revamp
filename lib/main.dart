import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

import 'core/config/storage_keys.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/local_storage.dart';
import 'core/utils/notification.dart';
import 'core/utils/nueip_helper.dart';
import 'features/calendar/presentation/presenters/attendance_presenter.dart';
import 'features/form/presentation/presenters/leave_record_presenter.dart';
import 'features/form/presentation/presenters/sign_presenter.dart';
import 'features/hidden/presentation/presenters/schedule_clock_presenter.dart';
import 'features/holiday/data/repositories/holiday_repository_impl.dart';
import 'features/holiday/data/services/holiday_service.dart';
import 'features/holiday/presentation/presenters/holiday_presenter.dart';
import 'features/home/presentation/presenters/clock_presenter.dart';
import 'features/login/data/models/auth_session.dart';
import 'features/login/presentation/presenters/login_presenter.dart';
import 'features/nueip/data/repositories/nueip_repository_impl.dart';
import 'features/nueip/data/services/nueip_services.dart';
import 'features/setting/presentation/presenters/setting_presenter.dart';
import 'index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStorage.init();

  await _initDependencies();

  await NotificationUtils.init();

  runApp(const App());
}

Future<void> _initDependencies() async {
  // Add router registration
  Circus.hire<AppRouter>(AppRouter());

  // Add AuthSession Joker registration
  Circus.recruit<AuthSession>(
    const AuthSession(),
    tag: 'auth',
    keepAlive: true,
  );

  // Add Company Address Joker registration
  final initialAddress = LocalStorage.get<String>(
    StorageKeys.companyAddress,
    defaultValue: '',
  );
  Circus.summon<String>(initialAddress, tag: 'companyAddress', keepAlive: true);

  // Add API features registration
  Circus
    ..hire<ApiClient>(ApiClient())
    ..hire<NueipHelper>(NueipHelper())
    ..contract<NueipService>(() => NueipService())
    ..hireLazily<NueipRepositoryImpl>(() => NueipRepositoryImpl())
    ..bindDependency<NueipRepositoryImpl, NueipService>();

  // Add API features registration
  Circus
    ..contract<HolidayService>(() => HolidayService())
    ..hireLazily<HolidayRepositoryImpl>(() => HolidayRepositoryImpl())
    ..bindDependency<HolidayRepositoryImpl, HolidayService>();

  // Add Presenters registration
  Circus
    ..hireLazily<HolidayPresenter>(() => HolidayPresenter())
    ..hireLazily<AttendancePresenter>(() => AttendancePresenter())
    ..hireLazily<LoginPresenter>(() => LoginPresenter())
    ..hireLazily<SettingPresenter>(() => SettingPresenter())
    ..hireLazily<ClockPresenter>(() => ClockPresenter())
    ..hireLazily<LeaveRecordPresenter>(() => LeaveRecordPresenter())
    ..contract<SignPresenter>(() => SignPresenter())
    ..hireLazily<ScheduleClockPresenter>(() => ScheduleClockPresenter());

  // Add theme mode Joker registration
  Circus.summon<AppThemeMode>(
    AppThemeMode.light,
    tag: 'themeMode',
    keepAlive: true,
  );
}
