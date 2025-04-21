import 'package:auto_route/auto_route.dart';

import '../../presentation/screens/login_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: LoginRoute.page, initial: true),
    // AutoRoute(page: SettingsRoute.page),
  ];
}
