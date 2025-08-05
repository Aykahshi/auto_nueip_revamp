import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:joker_state/joker_state.dart';

import '../../../../core/config/storage_keys.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/utils/auth_utils.dart';
import '../../../../core/utils/local_storage.dart';
import '../../../calendar/data/models/daily_clock_detail.dart';
import '../../../nueip/domain/repositories/nueip_repository.dart';
import '../../domain/entities/clock_action_enum.dart';
import '../../domain/entities/clock_state.dart';

final class ClockPresenter extends Presenter<ClockState> {
  ClockPresenter()
    : _repository = Circus.find<NueipRepository>(),
      super(
        const ClockState(
          status: ClockActionStatus.idle,
          timeStatus: ClockTimeStatus.idle,
        ),
      );

  final NueipRepository _repository;
  late final Joker<DateTime> timeJoker;
  Timer? _timer;

  @override
  onInit() {
    super.onInit();
    timeJoker = Joker<DateTime>(DateTime.now());
  }

  @override
  void onReady() async {
    super.onReady();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      timeJoker.trick(DateTime.now());
    });
    await _init();
  }

  @override
  void onDone() {
    _timer?.cancel();
    super.onDone();
  }

  Future<void> _init() async {
    await AuthUtils.checkAuthSession();
    final session = AuthUtils.getAuthSession();

    await getClockTimes(
      accessToken: session.accessToken ?? '',
      cookie: session.cookie ?? '',
    );
  }

  Future<void> refresh() async {
    await _init();
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

  Future<void> performClockAction(ClockAction action) async {
    final session = AuthUtils.getAuthSession();

    final double latitude = LocalStorage.get<double>(
      StorageKeys.companyLatitude,
      defaultValue: 0,
    );
    final double longitude = LocalStorage.get<double>(
      StorageKeys.companyLongitude,
      defaultValue: 0,
    );

    await _clockAction(
      action: action,
      cookie: session.cookie ?? '',
      csrfToken: session.csrfToken ?? '',
      latitude: latitude,
      longitude: longitude,
      accessToken: session.accessToken ?? '',
    );
  }

  /// Performs a clock action (e.g., clock-in or clock-out).
  /// Requires method ('1' for in, '2' for out), tokens, and location.
  Future<void> _clockAction({
    required ClockAction action,
    required String cookie,
    required String csrfToken,
    required double latitude,
    required double longitude,
    required String accessToken,
  }) async {
    // Set loading state and active action
    trickWith(
      (state) => state.copyWith(
        status: ClockActionStatus.loading,
        activeAction: action, // Indicate which action is loading
      ),
    );

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
            activeAction: null, // Clear active action on failure
            failure: failure,
          ),
        );
      },
      (_) async {
        // Punch action itself was successful
        debugPrint(
          "Punch action successful. Updating status and fetching updated times...",
        );

        // Update action status to success and clear active action
        // before fetching times (time fetch will handle its own status)
        trickWith(
          (state) => state.copyWith(
            status: ClockActionStatus.success,
            activeAction: null,
          ),
        );

        // Pass the required tokens for the fetch call
        await getClockTimes(accessToken: accessToken, cookie: cookie);
      },
    );
  }
}
