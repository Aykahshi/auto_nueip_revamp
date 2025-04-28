import 'package:auto_route/auto_route.dart';

import '../../presentation/screens/apply_form_screen.dart';
import '../../presentation/screens/calendar_screen.dart';
import '../../presentation/screens/developer_info_screen.dart';
import '../../presentation/screens/form_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/main_screen.dart';
import '../../presentation/screens/profile_editing_screen.dart';
import '../../presentation/screens/setting_screen.dart';
import 'auth_guard.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes => <AutoRoute>[
    AutoRoute(page: LoginRoute.page, keepHistory: false),
    AutoRoute(
      page: MainRoute.page,
      initial: true,
      guards: [AuthGuard()],
      children: <AutoRoute>[
        AutoRoute(page: HomeRoute.page, initial: true),
        AutoRoute(
          page: SettingRoute.page,
          children: [
            AutoRoute(page: SettingMainRoute.page, initial: true),
            AutoRoute(page: DeveloperInfoRoute.page),
            AutoRoute(page: ProfileEditingRoute.page),
          ],
        ),
        AutoRoute(
          page: FormRoute.page,
          children: [
            AutoRoute(page: FormHistoryRoute.page, initial: true),
            AutoRoute(page: ApplyFormRoute.page),
          ],
        ),
        AutoRoute(page: CalendarRoute.page),
      ],
    ),
  ];
}
