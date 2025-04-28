import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/auth_utils.dart';
import '../../core/utils/nueip_helper.dart';
import '../../data/models/login_status_enum.dart';
import '../../data/repositories/nueip_repository_impl.dart';
import '../../domain/repositories/nueip_repository.dart';

class LoginPresenter extends Presenter<LoginStatus> {
  final NueipRepository _repository;
  final NueipHelper _helper;

  LoginPresenter({super.keepAlive = true})
    : _repository = Circus.find<NueipRepositoryImpl>(),
      _helper = Circus.find<NueipHelper>(),
      super(LoginStatus.initial);

  @override
  void onReady() {
    super.onReady();
    init();
  }

  Future<void> init() async {
    final client = Circus.find<ApiClient>();
    if (AuthUtils.isAuthSessionValid()) {
      client.updateAuthSession(AuthUtils.getAuthSession());
      return;
    }

    final (companyCode, employeeId, password, _) = AuthUtils.getCredentials();

    if (companyCode.isEmpty || employeeId.isEmpty || password.isEmpty) {
      return;
    }

    await login(
      companyCode: companyCode,
      employeeId: employeeId,
      password: password,
    );
    client.updateAuthSession(AuthUtils.getAuthSession());
  }

  /// Performs the login operation.
  Future<void> login({
    required String companyCode,
    required String employeeId,
    required String password,
  }) async {
    // Update state using the presenter's built-in trick method
    trick(LoginStatus.loading);

    final result =
        await _repository
            .login(company: companyCode, id: employeeId, password: password)
            .run();

    // Process the result after awaiting the repository call
    result.match(
      (loginFailure) {
        trick(LoginStatus.error);
      },
      (response) async {
        if (response.statusCode != 303) {
          // Consider specific error for non-redirect
          trick(LoginStatus.error);
          return;
        }

        _helper.redirectUrl = response.headers['location']?.first ?? '';

        if (_helper.redirectUrl == '') {
          // Consider specific error for missing location
          trick(LoginStatus.error);
          return;
        }

        if (_helper.redirectUrl.contains('/home')) {
          try {
            await _helper.getCookieAndToken();
            await AuthUtils.saveCredentials(companyCode, employeeId, password);
            trick(LoginStatus.success);
          } catch (e) {
            debugPrint('Helper setup failed: $e');
            trick(LoginStatus.error); // Indicate error during setup
          }
        } else {
          // Handle cases where redirect URL is not '/home'
          debugPrint(
            'Redirect URL does not contain /home: ${_helper.redirectUrl}',
          );
          trick(LoginStatus.error);
        }
      },
    );
  }
}
