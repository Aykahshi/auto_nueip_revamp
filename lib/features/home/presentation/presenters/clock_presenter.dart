import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:joker_state/joker_state.dart';
import 'package:timezone/timezone.dart' as tz;

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

    // Load GPS clock-in setting
    final isGpsEnabled = LocalStorage.get<bool>(
      StorageKeys.gpsClockInEnabled,
      defaultValue: false,
    );

    trickWith((state) => state.copyWith(isGpsClockInEnabled: isGpsEnabled));

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

    final result = await _repository
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
    final state = value;

    double latitude;
    double longitude;

    if (state.isGpsClockInEnabled) {
      // Use GPS location
      final position = await _getCurrentLocation();
      if (position == null) {
        trickWith(
          (state) => state.copyWith(
            status: ClockActionStatus.failure,
            failure: const Failure(
              message: "無法獲取 GPS 位置，請檢查位置權限設定",
              status: 'gps_location_failed',
            ),
          ),
        );
        return;
      }
      latitude = position.latitude;
      longitude = position.longitude;
    } else {
      // Use fixed company location
      latitude = LocalStorage.get<double>(
        StorageKeys.companyLatitude,
        defaultValue: 0,
      );
      longitude = LocalStorage.get<double>(
        StorageKeys.companyLongitude,
        defaultValue: 0,
      );
    }

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

    final result = await _repository
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

        // Cancel today's reminder for the corresponding action
        await _cancelTodaysReminder(action);

        // Pass the required tokens for the fetch call
        await getClockTimes(accessToken: accessToken, cookie: cookie);
      },
    );
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      trickWith((state) => state.copyWith(isGpsLoading: true));

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('定位服務未啟用');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('定位權限被拒絕');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('定位權限被永久拒絕，請在設定中開啟');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Get address from coordinates (optional)
      try {
        // You can add geocoding here to get the address
        // For now, just use coordinates
        trickWith(
          (state) => state.copyWith(
            isGpsLoading: false,
            currentAddress:
                '緯度: ${position.latitude.toStringAsFixed(6)}, 經度: ${position.longitude.toStringAsFixed(6)}',
          ),
        );
      } catch (e) {
        // Address lookup failed, but we still have coordinates
        trickWith((state) => state.copyWith(isGpsLoading: false));
      }

      return position;
    } catch (e) {
      trickWith((state) => state.copyWith(isGpsLoading: false));
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  Future<void> toggleGpsClockIn(bool enabled) async {
    await LocalStorage.set(StorageKeys.gpsClockInEnabled, enabled);
    trickWith((state) => state.copyWith(isGpsClockInEnabled: enabled));

    if (enabled) {
      // Pre-load current location when enabling GPS
      await _getCurrentLocation();
    } else {
      // Clear current address when disabling GPS
      trickWith((state) => state.copyWith(currentAddress: null));
    }
  }

  Future<void> _cancelTodaysReminder(ClockAction action) async {
    final now = DateTime.now();
    final weekday = now.weekday;

    // Only cancel on weekdays
    if (weekday >= DateTime.monday && weekday <= DateTime.friday) {
      final plugin = FlutterLocalNotificationsPlugin();
      final notificationId = (action == ClockAction.IN ? 1001 : 1002) + weekday;

      // Cancel the current schedule for this weekday
      await plugin.cancel(notificationId);

      // Check if reminders are enabled
      final notificationsEnabled = LocalStorage.get<bool>(
        StorageKeys.notificationsEnabled,
        defaultValue: false,
      );
      final clockReminderEnabled = LocalStorage.get<bool>(
        StorageKeys.clockReminderEnabled,
        defaultValue: false,
      );

      if (!notificationsEnabled || !clockReminderEnabled) {
        return;
      }

      // Reschedule for next week
      int hour;
      int minute;
      String title;
      String body;

      if (action == ClockAction.IN) {
        hour = LocalStorage.get<int>(
          StorageKeys.morningReminderHour,
          defaultValue: 9,
        );
        minute = LocalStorage.get<int>(
          StorageKeys.morningReminderMinute,
          defaultValue: 0,
        );
        title = '上班打卡提醒';
        body = '別忘了打卡上班喔！';
      } else {
        hour = LocalStorage.get<int>(
          StorageKeys.eveningReminderHour,
          defaultValue: 18,
        );
        minute = LocalStorage.get<int>(
          StorageKeys.eveningReminderMinute,
          defaultValue: 0,
        );
        title = '下班打卡提醒';
        body = '記得打卡下班喔！';
      }

      // Calculate next week's date for the same weekday
      final scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      ).add(const Duration(days: 7));

      const androidDetails = AndroidNotificationDetails(
        'clock_reminder',
        '打卡提醒',
        channelDescription: '工作日打卡提醒通知',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      try {
        await plugin.zonedSchedule(
          notificationId,
          title,
          body,
          tz.TZDateTime.from(scheduledDate, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (e) {
        debugPrint('Failed to reschedule reminder: $e');
      }
    }
  }
}
