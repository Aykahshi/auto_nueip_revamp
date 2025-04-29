import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

import 'core/config/storage_keys.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/local_storage.dart';
import 'core/utils/notification.dart';
import 'core/utils/nueip_helper.dart';
import 'data/models/auth_session.dart';
import 'data/repositories/holiday_repository_impl.dart';
import 'data/repositories/nueip_repository_impl.dart';
import 'data/services/holiday_service.dart';
import 'data/services/nueip_services.dart';
import 'index.dart';
import 'presentation/presenters/attendance_presenter.dart';
import 'presentation/presenters/clock_presenter.dart';
import 'presentation/presenters/holiday_presenter.dart';
import 'presentation/presenters/leave_record_presenter.dart';
import 'presentation/presenters/login_presenter.dart';
import 'presentation/presenters/setting_presenter.dart';
import 'presentation/presenters/sign_presenter.dart';

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
  Circus.hireLazily<HolidayPresenter>(() => HolidayPresenter());
  Circus.hireLazily<AttendancePresenter>(() => AttendancePresenter());
  Circus.hireLazily<LoginPresenter>(() => LoginPresenter());
  Circus.hireLazily<SettingPresenter>(() => SettingPresenter());
  Circus.hireLazily<ClockPresenter>(() => ClockPresenter());
  Circus.hireLazily<LeaveRecordPresenter>(() => LeaveRecordPresenter());
  Circus.contract<SignPresenter>(() => SignPresenter());

  // Add theme mode Joker registration
  Circus.summon<AppThemeMode>(
    AppThemeMode.light,
    tag: 'themeMode',
    keepAlive: true,
  );
}
