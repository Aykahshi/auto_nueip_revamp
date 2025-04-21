import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/local_storage.dart';
import 'core/utils/nueip_helper.dart';
import 'data/repositories/nueip_repository_impl.dart';
import 'data/services/nueip_services.dart';
import 'index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _init();

  await LocalStorage.init();

  runApp(const App());
}

Future<void> _init() async {
  Circus.hire<ApiClient>(ApiClient());
  Circus.hire<NueipHelper>(NueipHelper());
  Circus.contract<NueipService>(() => NueipService());
  Circus.hireLazily<NueipRepositoryImpl>(() => NueipRepositoryImpl());
  Circus.bindDependency<NueipRepositoryImpl, NueipService>();

  // Add theme mode Joker registration
  Circus.summon<AppThemeMode>(
    AppThemeMode.system,
    tag: 'themeMode',
    keepAlive: true,
  );
}
