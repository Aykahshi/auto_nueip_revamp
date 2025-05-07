import 'package:flutter/services.dart';
import 'package:joker_state/joker_state.dart';

import '../../../nueip/data/repositories/nueip_repository_impl.dart';
import '../../../nueip/domain/repositories/nueip_repository.dart';
import '../../data/models/form_type_enum.dart';
import '../../domain/entities/sign_state.dart'; // Import the new SignState entity

/// Presenter for fetching and managing leave form sign data.
final class SignPresenter extends Presenter<SignState> {
  // Use the SignState entity
  final NueipRepository _repository;

  SignPresenter({NueipRepository? repository})
    : _repository = repository ?? Circus.find<NueipRepositoryImpl>(),
      super(
        SignState.initial(), // Use the factory for initial state
      );

  /// Fetches the sign data for a specific leave form.
  Future<void> fetchSignData(FormType type, String id) async {
    // Set loading state using copyWith - Provide current state to trick
    trick(state.copyWith(isLoading: true, error: null));

    final result = await _repository.getLeaveSignData(type: type, id: id).run();

    // Update state based on result using copyWith - Provide current state to trick
    result.fold(
      (failure) => trick(
        state.copyWith(
          isLoading: false,
          error: failure.message, // Store error message
          signData: null, // Clear data on error
        ),
      ),
      (data) => trick(
        state.copyWith(
          isLoading: false,
          error: null,
          signData: data, // Store fetched data
        ),
      ),
    );
  }

  Future<void> cauculateWorkHour() async {}

  Future<void> deleteLeaveForm({
    required String id,
    required VoidCallback onSuccess,
    required VoidCallback onFailed,
  }) async {
    trick(state.copyWith(isLoading: true, error: null));

    final result = await _repository.deleteLeaveForm(id: id).run();

    // Update state based on result using copyWith - Provide current state to trick
    result.fold(
      (failure) {
        trick(
          state.copyWith(
            isLoading: false,
            error: failure.message, // Store error message
            signData: null, // Clear data on error
          ),
        );
        onFailed.call();
      },
      (_) {
        trick(state.copyWith(isLoading: false, error: null));
        onSuccess.call();
      },
    );
  }
}
