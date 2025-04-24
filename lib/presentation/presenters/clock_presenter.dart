import 'package:flutter/foundation.dart';
import 'package:joker_state/joker_state.dart';

import '../../core/config/storage_keys.dart';
import '../../core/network/failure.dart';
import '../../core/utils/auth_utils.dart';
import '../../core/utils/local_storage.dart';
import '../../data/models/clock_action_enum.dart';
import '../../data/models/daily_clock_detail.dart';
import '../../data/models/login_status_enum.dart';
import '../../data/repositories/nueip_repository_impl.dart';
import '../../domain/entities/clock_state.dart';
import '../../domain/repositories/nueip_repository.dart';
import 'login_presenter.dart';

class ClockPresenter extends Presenter<ClockState> {
  final NueipRepository _repository;
  final LoginPresenter _loginPresenter;
  late final VoidCallback _cancel;

  ClockPresenter({NueipRepository? repository})
    : _repository = repository ?? Circus.find<NueipRepositoryImpl>(),
      _loginPresenter = Circus.find<LoginPresenter>(),
      super(const ClockState.initial());

  @override
  void onReady() {
    super.onReady();
    _cancel = _loginPresenter.listen((_, current) {
      if (current == LoginStatus.success) {
        _init();
      }
    });
  }

  @override
  void onDone() {
    _cancel();
    super.onDone();
  }

  Future<void> _init() async {
    final session = AuthUtils.getAuthSession();

    await getClockTimes(
      accessToken: session.accessToken ?? '',
      cookie: session.cookie ?? '',
    );
  }

  Future<void> getClockTimes({
    required String accessToken,
    required String cookie,
  }) async {
    trick(const ClockState.loading());

    final result =
        await _repository
            .getClockTime(accessToken: accessToken, cookie: cookie)
            .run();

    result.fold((failure) => trick(ClockState.failure(failure)), (
      response,
    ) async {
      try {
        final jsonData = response.data as Map<String, dynamic>;
        final detailData = jsonData['data']['user'] as Map<String, dynamic>?;

        if (detailData != null) {
          final dailyClockDetail = DailyClockDetail.fromJson(detailData);
          await LocalStorage.set(StorageKeys.userNo, dailyClockDetail.userNo);
          trick(ClockState.success(dailyClockDetail));
        } else {
          trick(
            const ClockState.failure(
              Failure(
                message: "Invalid response format: 'user' data not found.",
                status: 'get clock times failed',
              ),
            ),
          );
        }
      } catch (e, stackTrace) {
        // Handle parsing errors
        debugPrint("Error parsing clock time response: $e\n$stackTrace");
        trick(
          ClockState.failure(
            Failure(
              message: "Failed to parse clock time data: $e",
              status: 'get clock times failed',
            ),
          ),
        );
      }
    });
  }

  /// Performs a clock action (e.g., clock-in or clock-out).
  /// Requires method ('1' for in, '2' for out), tokens, and location.
  Future<void> clockAction({
    required ClockAction action,
    required String cookie,
    required String csrfToken,
    required double latitude,
    required double longitude,
    // Added required tokens for fetching after successful punch
    required String accessToken,
  }) async {
    // Set loading state
    trick(const ClockState.loading());

    final result =
        await _repository
            .clockAction(
              method: action.value,
              cookie: cookie,
              csrfToken: csrfToken,
              latitude: latitude,
              longitude: longitude,
            )
            .run();

    result.fold((failure) => trick(ClockState.failure(failure)), (_) async {
      // Punch action itself was successful, now fetch updated times
      debugPrint("Punch action successful. Fetching updated times...");
      // Trigger fetchPunchTimes to get the latest state
      // Pass the required tokens for the fetch call
      await getClockTimes(accessToken: accessToken, cookie: cookie);
    });
  }
}
