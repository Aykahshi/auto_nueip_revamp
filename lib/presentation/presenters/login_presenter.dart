import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

import '../../core/config/storage_keys.dart';
import '../../core/network/failure.dart';
import '../../core/utils/local_storage.dart';
import '../../core/utils/nueip_helper.dart';
import '../../data/models/login_status_enum.dart';
import '../../data/repositories/nueip_repository_impl.dart';
import '../../domain/entities/login_state.dart';
import '../../domain/repositories/nueip_repository.dart';

class LoginPresenter extends Presenter<LoginState> {
  final NueipRepository _repository;
  final NueipHelper _helper;

  LoginPresenter({NueipRepository? repository})
    : _repository = repository ?? Circus.find<NueipRepositoryImpl>(),
      _helper = Circus.find<NueipHelper>(),
      super(const LoginState(status: LoginStatus.initial));

  /// Performs the login operation.
  Future<void> login({
    required String companyCode,
    required String employeeId,
    required String password,
  }) async {
    // Update state using the presenter's built-in trick method
    trick(const LoginState(status: LoginStatus.loading));

    final result =
        await _repository
            .login(company: companyCode, id: employeeId, password: password)
            .run();

    // Process the result after awaiting the repository call
    result.match(
      (loginFailure) {
        switch (loginFailure) {
          case CompanyInvalid(:final errData):
            debugPrint('Login Failed (Invalid Company): $errData');
            trick(
              LoginState(
                status: LoginStatus.error,
                errors: LoginErrors(
                  message: errData?.message ?? '',
                  company: errData?.company,
                ),
              ),
            );
          case UserInvalid(:final errData):
            debugPrint('Login Failed (User Not Found): $errData');
            trick(
              LoginState(
                status: LoginStatus.error,
                errors: LoginErrors(
                  message: errData?.message ?? '',
                  user: errData?.user,
                ),
              ),
            );
          case PasswordInvalid(:final errData):
            debugPrint('Login Failed (Wrong Password): $errData');
            trick(
              LoginState(
                status: LoginStatus.error,
                errors: LoginErrors(
                  message: errData?.message ?? '',
                  pwd: errData?.pwd,
                ),
              ),
            );
          case UnknownLoginFailure(:final errData):
            debugPrint('Login Failed (Unknown): $errData');
            trick(
              LoginState(
                status: LoginStatus.error,
                errors: LoginErrors(message: errData?.message ?? ''),
              ),
            );
        }

        trick(const LoginState(status: LoginStatus.error));
      },
      (response) async {
        debugPrint('Login Successful in Presenter! Saving credentials...');
        // Trigger save operation (fire and forget or await if needed)
        _saveCredentials(companyCode, employeeId, password);

        if (response.statusCode != 303) {
          // Consider specific error for non-redirect
          trick(const LoginState(status: LoginStatus.error));
          return;
        }

        _helper.redirectUrl = response.headers['location']?.first ?? '';

        if (_helper.redirectUrl == '') {
          // Consider specific error for missing location
          trick(const LoginState(status: LoginStatus.error));
          return;
        }

        if (_helper.redirectUrl.contains('/home')) {
          try {
            await _helper.getCookie();
            await _helper.getCrsfToken();
            await _helper.getOauthToken();
            trick(const LoginState(status: LoginStatus.success));
          } catch (e) {
            debugPrint('Helper setup failed: $e');
            trick(
              const LoginState(status: LoginStatus.error),
            ); // Indicate error during setup
          }
        } else {
          // Handle cases where redirect URL is not '/home'
          debugPrint(
            'Redirect URL does not contain /home: ${_helper.redirectUrl}',
          );
          trick(const LoginState(status: LoginStatus.error));
        }
      },
    );
  }

  Future<void> _saveCredentials(
    String companyCode,
    String employeeId,
    String password,
  ) async {
    try {
      await LocalStorage.set(StorageKeys.companyCode, companyCode);
      await LocalStorage.set(StorageKeys.employeeId, employeeId);
      await LocalStorage.set(StorageKeys.password, password);
      debugPrint(
        'Credentials saved successfully by ${runtimeType.toString()}.',
      );
    } catch (e) {
      debugPrint(
        'Failed to save credentials in  ${runtimeType.toString()}: $e',
      );
    }
  }
}
