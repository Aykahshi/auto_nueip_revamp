import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

import '../../core/config/storage_keys.dart';
import '../../core/utils/local_storage.dart';
import '../../core/utils/nueip_helper.dart';
import '../../data/repositories/nueip_repository_impl.dart';
import '../../domain/repositories/nueip_repository.dart';

class LoginPresenter {
  final NueipRepository _repository;
  final NueipHelper _helper;

  LoginPresenter({required NueipRepository? repository})
    : _repository = repository ?? Circus.find<NueipRepositoryImpl>(),
      _helper = Circus.find<NueipHelper>();

  /// Performs the login operation.
  Future<void> login({
    required String companyCode,
    required String employeeId,
    required String password,
    required Joker<bool> loadingJoker,
  }) async {
    // Update loading state via the passed Joker
    loadingJoker.trick(true);

    final result =
        await _repository
            .login(company: companyCode, id: employeeId, password: password)
            .run();

    // Process the result after awaiting the repository call
    result.match(
      (failure) {
        debugPrint('Login Failed in Presenter: ${failure.message}');
      },
      (response) async {
        debugPrint('Login Successful in Presenter! Saving credentials...');
        // Trigger save operation (fire and forget or await if needed)
        _saveCredentials(companyCode, employeeId, password);

        if (response.statusCode != 303) return;

        _helper.redirectUrl = response.headers['location']?.first ?? '';

        if (_helper.redirectUrl == '') return;

        if (_helper.redirectUrl.contains('/home')) {
          await _helper.getCookie();
          await _helper.getCrsfToken();
          await _helper.getOauthToken();
        }
      },
    );

    // Turn off loading state via the passed Joker *after* processing
    loadingJoker.trick(false);
  }

  // --- Helper for Saving Credentials (remains internal to Presenter) ---
  Future<void> _saveCredentials(
    String companyCode,
    String employeeId,
    String password,
    /*, String? cookie */
  ) async {
    try {
      // Use constants from StorageKeys
      await LocalStorage.set(StorageKeys.companyCode, companyCode);
      await LocalStorage.set(StorageKeys.employeeId, employeeId);
      // WARNING: Storing raw password is not secure!
      await LocalStorage.set(
        StorageKeys.password,
        password,
      ); // Save the password
      debugPrint(
        'Credentials (including password) saved successfully by Presenter.',
      );
    } catch (e) {
      debugPrint('Failed to save credentials in Presenter: $e');
      // Handle storage failure appropriately
    }
  }
}
