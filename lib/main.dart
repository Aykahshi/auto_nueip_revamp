import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/local_storage.dart';
import 'core/utils/notification.dart';
import 'core/utils/nueip_helper.dart';
import 'data/repositories/holiday_repository_impl.dart';
import 'data/repositories/nueip_repository_impl.dart';
import 'data/services/holiday_service.dart';
import 'data/services/nueip_services.dart';
import 'index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _init();

  await LocalStorage.init();

  await NotificationUtils.init();

  runApp(const App());
}

Future<void> _init() async {
  // Add router registration
  Circus.hire<AppRouter>(AppRouter());

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

  // Add theme mode Joker registration
  Circus.summon<AppThemeMode>(
    AppThemeMode.system,
    tag: 'themeMode',
    keepAlive: true,
  );
}
