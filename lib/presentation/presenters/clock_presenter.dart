import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:joker_state/joker_state.dart';

import '../../core/config/storage_keys.dart';
import '../../core/network/failure.dart';
import '../../core/utils/auth_utils.dart';
import '../../core/utils/local_storage.dart';
import '../../data/models/clock_action_enum.dart';
import '../../data/models/daily_clock_detail.dart';
import '../../data/repositories/nueip_repository_impl.dart';
import '../../domain/entities/clock_state.dart';
import '../../domain/repositories/nueip_repository.dart';

class ClockPresenter extends Presenter<ClockState> {
  final NueipRepository _repository;

  ClockPresenter({NueipRepository? repository})
    : _repository = repository ?? Circus.find<NueipRepositoryImpl>(),
      super(
        const ClockState(
          status: ClockActionStatus.initial,
          timeStatus: ClockTimeStatus.initial,
        ),
      );

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await AuthUtils.checkAuthSession();
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
    trickWith((state) => state.copyWith(timeStatus: ClockTimeStatus.loading));

    final result =
        await _repository
            .getClockTime(accessToken: accessToken, cookie: cookie)
            .run();

    result.fold(
      (failure) {
        trickWith(
          (state) => state.copyWith(
            timeStatus: ClockTimeStatus.failure,
            failure: failure,
          ),
        );
      },
      (response) async {
        try {
          final jsonData = response.data as Map<String, dynamic>;
          final detailData = jsonData['data']['user'] as Map<String, dynamic>?;

          if (detailData != null) {
            final dailyClockDetail = DailyClockDetail.fromJson(detailData);
            await LocalStorage.set(StorageKeys.userNo, dailyClockDetail.userNo);
            trickWith(
              (state) => state.copyWith(
                timeStatus: ClockTimeStatus.success,
                details: dailyClockDetail,
              ),
            );
          } else {
            trickWith(
              (state) => state.copyWith(
                timeStatus: ClockTimeStatus.failure,
                failure: const Failure(
                  message: "Invalid response format: 'user' data not found.",
                  status: 'get clock times failed',
                ),
              ),
            );
          }
        } catch (e, stackTrace) {
          // Handle parsing errors
          debugPrint("Error parsing clock time response: $e\n$stackTrace");

          trickWith(
            (state) => state.copyWith(
              timeStatus: ClockTimeStatus.failure,
              failure: Failure(
                message: "Failed to parse clock time data: $e",
                status: 'get clock times failed',
              ),
            ),
          );
        }
      },
    );
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
    trickWith((state) => state.copyWith(status: ClockActionStatus.loading));

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

    result.fold(
      (failure) {
        trickWith(
          (state) => state.copyWith(
            status: ClockActionStatus.failure,
            failure: failure,
          ),
        );
      },
      (_) async {
        // Punch action itself was successful, now fetch updated times
        debugPrint("Punch action successful. Fetching updated times...");
        // Trigger fetchPunchTimes to get the latest state
        // Pass the required tokens for the fetch call
        await getClockTimes(accessToken: accessToken, cookie: cookie);
      },
    );
  }
}
