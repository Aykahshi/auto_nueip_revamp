import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:joker_state/joker_state.dart';

import '../../../../core/config/storage_keys.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/auth_utils.dart';
import '../../../../core/utils/local_storage.dart';
import '../../../../core/utils/notification.dart';
import '../../../../core/utils/nueip_helper.dart';
import '../../../login/data/models/auth_session.dart';
import '../../../nueip/data/repositories/nueip_repository_impl.dart';
import '../../../nueip/data/services/nueip_services.dart';

/// 背景服務管理類，用於處理自動打卡的背景任務
class ScheduleBackgroundService {
  // 服務狀態流
  static final _serviceStatusController = StreamController<bool>.broadcast();

  /// 獲取服務狀態流
  static Stream<bool?> get serviceStatus => _serviceStatusController.stream;

  /// 初始化背景服務
  static Future<void> initialize() async {
    // 初始化本地通知
    await NotificationUtils.init();

    // 初始化本地存儲
    await LocalStorage.init();

    // 讀取保存的設置
    await _loadSettings();

    // 初始化背景服務
    final service = FlutterBackgroundService();

    const notificationChannelId = 'auto_nueip_bg_channel';

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId, // id
      'Auto Nueip BG', // title
      description: 'Auto Nueip Background Service', // description
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: false,
        autoStart: false,
        autoStartOnBoot: false,
        initialNotificationTitle: 'Nueip 自動打卡',
        initialNotificationContent: '正在背景運行...',
        notificationChannelId: notificationChannelId,
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [
          AndroidForegroundType.location,
          AndroidForegroundType.dataSync,
        ],
      ),
      // don't care about iOS
      iosConfiguration: IosConfiguration(autoStart: false),
    );

    // 監聽服務狀態變化
    service.isRunning().then((value) {
      _serviceStatusController.add(value);
    });

    // 定期檢查服務狀態
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      final isRunning = await service.isRunning();
      _serviceStatusController.add(isRunning);
    });
  }

  /// 檢查服務是否正在運行
  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  /// 啟動背景服務
  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
    final isRunning = await service.isRunning();
    _serviceStatusController.add(isRunning);

    // 保存服務啟用狀態
    await LocalStorage.set(StorageKeys.serviceEnabled, true);
  }

  /// 停止背景服務
  static Future<void> stopService() async {
    try {
      // 先更新服務狀態，避免空值檢查錯誤
      _serviceStatusController.add(false);

      // 保存服務狀態
      await LocalStorage.set(StorageKeys.serviceEnabled, false);

      // 停止服務
      final service = FlutterBackgroundService();

      // 確保在停止服務前先設置一個標記，讓 onStart 方法知道服務正在停止
      await LocalStorage.set('service_stopping', true);

      // 停止服務
      service.invoke('stop');

      // 等待一段時間，確保服務已經停止
      await Future.delayed(const Duration(seconds: 1));

      // 移除停止標記
      await LocalStorage.set(StorageKeys.stopFlag, false);
    } catch (e) {
      debugPrint('停止服務時發生錯誤: $e');
    } finally {
      // 無論如何都確保狀態被更新
      _serviceStatusController.add(false);
      await LocalStorage.set(StorageKeys.serviceEnabled, false);
      await LocalStorage.set(StorageKeys.stopFlag, false);
    }
  }

  /// 顯示本地通知
  static Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await NotificationUtils.showSimpleNotification(id, title, body);
  }

  /// 設定上下班打卡任務
  static Future<void> scheduleClockInOut({
    required DateTime clockInTime,
    required DateTime clockOutTime,
    required Duration flexibleDuration,
    required Duration randomDuration,
  }) async {
    // 保存打卡設置
    await _saveClockInOutSettings(
      clockInTime,
      clockOutTime,
      flexibleDuration,
      randomDuration,
    );

    // 計算下一次上班打卡時間
    final now = DateTime.now();
    DateTime nextClockInTime = DateTime(
      now.year,
      now.month,
      now.day,
      clockInTime.hour,
      clockInTime.minute,
    );

    // 計算下一次下班打卡時間
    DateTime nextClockOutTime = DateTime(
      now.year,
      now.month,
      now.day,
      clockOutTime.hour,
      clockOutTime.minute,
    );

    // 如果今天的上班打卡時間已經過了，設定為明天
    if (nextClockInTime.isBefore(now)) {
      nextClockInTime = nextClockInTime.add(const Duration(days: 1));
      nextClockOutTime = nextClockOutTime.add(const Duration(days: 1));
    }
    // 如果今天的上班打卡時間還沒過，但下班打卡時間已經過了，則下班打卡時間設定為明天
    else if (nextClockOutTime.isBefore(now)) {
      nextClockOutTime = nextClockOutTime.add(const Duration(days: 1));
    }

    // 保存下一次上下班打卡時間
    await LocalStorage.set(
      StorageKeys.nextClockInTime,
      nextClockInTime.millisecondsSinceEpoch,
    );
    await LocalStorage.set(
      StorageKeys.nextClockOutTime,
      nextClockOutTime.millisecondsSinceEpoch,
    );

    // 將設置傳遞給背景服務
    final service = FlutterBackgroundService();
    service.invoke('setData', {
      StorageKeys.clockInTime: clockInTime.millisecondsSinceEpoch,
      StorageKeys.clockOutTime: clockOutTime.millisecondsSinceEpoch,
      StorageKeys.flexibleDuration: flexibleDuration.inMinutes,
      StorageKeys.randomTimeRange: randomDuration.inMinutes,
    });
  }

  /// 保存上下班打卡設置到 LocalStorage
  static Future<void> _saveClockInOutSettings(
    DateTime clockInTime,
    DateTime clockOutTime,
    Duration flexibleDuration,
    Duration randomDuration,
  ) async {
    // 保存上班打卡時間
    await LocalStorage.set(
      StorageKeys.clockInTime,
      clockInTime.millisecondsSinceEpoch,
    );

    // 保存下班打卡時間
    await LocalStorage.set(
      StorageKeys.clockOutTime,
      clockOutTime.millisecondsSinceEpoch,
    );

    // 保存工作時間區間
    final workHoursStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      9, // 預設工作時間區間起始為 9:00
      0,
    );

    final workHoursEnd = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      18, // 預設工作時間區間結束為 18:00
      0,
    );

    await LocalStorage.set(
      StorageKeys.workHoursStart,
      workHoursStart.millisecondsSinceEpoch,
    );

    await LocalStorage.set(
      StorageKeys.workHoursEnd,
      workHoursEnd.millisecondsSinceEpoch,
    );

    // 保存彈性時間
    await LocalStorage.set(
      StorageKeys.flexibleDuration,
      flexibleDuration.inMinutes,
    );

    // 保存隨機時間範圍
    await LocalStorage.set(
      StorageKeys.randomTimeRange,
      randomDuration.inMinutes,
    );
  }

  /// 從 LocalStorage 讀取設置
  static Future<void> _loadSettings() async {
    // 讀取上下班打卡時間
    final clockInTimeMs = LocalStorage.get<int>(
      StorageKeys.clockInTime,
      defaultValue: 0,
    );
    final clockOutTimeMs = LocalStorage.get<int>(
      StorageKeys.clockOutTime,
      defaultValue: 0,
    );

    // 讀取彈性時間和隨機時間範圍
    final flexibleDurationMin = LocalStorage.get<int>(
      StorageKeys.flexibleDuration,
      defaultValue: 0,
    );
    final randomTimeRangeMin = LocalStorage.get<int>(
      StorageKeys.randomTimeRange,
      defaultValue: 0,
    );

    // 讀取服務狀態
    final serviceEnabled = LocalStorage.get<bool>(
      StorageKeys.serviceEnabled,
      defaultValue: false,
    );

    // 檢查是否有有效的上下班時間設置
    final hasValidClockTimes = clockInTimeMs > 0 && clockOutTimeMs > 0;

    if (hasValidClockTimes && flexibleDurationMin > 0) {
      // 使用新的上下班打卡設置
      final clockInTime = DateTime.fromMillisecondsSinceEpoch(clockInTimeMs);
      final clockOutTime = DateTime.fromMillisecondsSinceEpoch(clockOutTimeMs);

      // 將設置傳遞給背景服務
      final service = FlutterBackgroundService();
      service.invoke('setData', {
        StorageKeys.clockInTime: clockInTimeMs,
        StorageKeys.clockOutTime: clockOutTimeMs,
        StorageKeys.flexibleDuration: flexibleDurationMin,
        StorageKeys.randomTimeRange: randomTimeRangeMin,
      });

      // 如果服務之前是啟用的，則自動啟動服務並重新設定打卡任務
      if (serviceEnabled) {
        await startService();

        // 重新設定上下班打卡任務
        await scheduleClockInOut(
          clockInTime: clockInTime,
          clockOutTime: clockOutTime,
          flexibleDuration: Duration(minutes: flexibleDurationMin),
          randomDuration: Duration(minutes: randomTimeRangeMin),
        );
      }
    } else if (serviceEnabled) {
      // 即使沒有有效的設置，如果服務之前是啟用的，也自動啟動服務
      await startService();
    }
  }

  /// 釋放資源
  static void dispose() {
    _serviceStatusController.close();
  }
}

/// 背景服務啟動時的回調函數
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  // 初始化本地存儲
  if (!LocalStorage.isInitialized()) {
    await LocalStorage.init();
  }

  if (!Circus.isHired<NueipRepositoryImpl>()) {
    Circus
      ..hire<ApiClient>(ApiClient())
      ..hire<NueipHelper>(NueipHelper())
      ..contract<NueipService>(() => NueipService())
      ..hireLazily<NueipRepositoryImpl>(() => NueipRepositoryImpl())
      ..bindDependency<NueipRepositoryImpl, NueipService>();
  }

  // 設置前台服務通知（僅 Android）
  if (service is AndroidServiceInstance) {
    // 設置前台服務通知，避免 ForegroundServiceDidNotStartInTimeException 錯誤
    if (await service.isForegroundService()) {
      await service.setForegroundNotificationInfo(
        title: "Nueip 自動打卡",
        content: "正在背景運行...",
      );
    }

    // 定義一個變數來追蹤定時器
    Timer? periodicTimer;

    periodicTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      // 檢查服務是否正在停止
      final isStopping = LocalStorage.get<bool>(
        'service_stopping',
        defaultValue: false,
      );
      final isEnabled = LocalStorage.get<bool>(
        StorageKeys.serviceEnabled,
        defaultValue: false,
      );

      // 如果服務正在停止或已經停止，取消定時器並返回
      if (isStopping || !isEnabled) {
        periodicTimer?.cancel();
        return;
      }

      final now = DateTime.now();

      // 從 LocalStorage 獲取設置
      final clockInTimeMs = LocalStorage.get<int>(
        StorageKeys.clockInTime,
        defaultValue: 0,
      );
      final clockOutTimeMs = LocalStorage.get<int>(
        StorageKeys.clockOutTime,
        defaultValue: 0,
      );
      final flexibleDurationMin = LocalStorage.get<int>(
        StorageKeys.flexibleDuration,
        defaultValue: 0,
      );
      final randomTimeRangeMin = LocalStorage.get<int>(
        StorageKeys.randomTimeRange,
        defaultValue: 0,
      );

      // 檢查是否有有效的上下班打卡時間設置
      final hasValidClockTimes = clockInTimeMs > 0 && clockOutTimeMs > 0;

      if (hasValidClockTimes && flexibleDurationMin > 0) {
        // 使用新的上下班打卡設置
        final clockInTime = DateTime.fromMillisecondsSinceEpoch(clockInTimeMs);
        final clockOutTime = DateTime.fromMillisecondsSinceEpoch(
          clockOutTimeMs,
        );
        final flexibleDuration = Duration(minutes: flexibleDurationMin);
        final randomDuration = Duration(minutes: randomTimeRangeMin);

        // 檢查是否在上班打卡時間範圍內
        if (_isWithinClockInTime(now, clockInTime, flexibleDuration)) {
          // 執行上班打卡選擇
          final success = await _performClockIn();
          if (success) {
            final notification = FlutterLocalNotificationsPlugin();

            // 隨機調整打卡時間
            final randomizedTime = _getRandomizedTime(now, randomDuration);

            await notification.show(
              0,
              '上班打卡成功',
              '您已於 ${randomizedTime.hour}:${randomizedTime.minute}:${randomizedTime.second} 成功上班打卡',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'auto_nueip_bg_channel',
                  'Auto Nueip BG',
                  channelDescription: 'Auto Nueip Background Service',
                  ongoing: true,
                ),
              ),
            );

            // 計算下一次上班打卡時間（明天同一時間）
            final tomorrow = DateTime(
              now.year,
              now.month,
              now.day,
              clockInTime.hour,
              clockInTime.minute,
            ).add(const Duration(days: 1));

            // 更新下一次上班打卡時間
            await LocalStorage.set(
              StorageKeys.nextClockInTime,
              tomorrow.millisecondsSinceEpoch,
            );
          }
        }

        // 檢查是否在下班打卡時間範圍內
        if (_isWithinClockOutTime(now, clockOutTime, flexibleDuration)) {
          // 執行下班打卡選擇
          final success = await _performClockIn();
          if (success) {
            final notification = FlutterLocalNotificationsPlugin();

            // 隨機調整打卡時間
            final randomizedTime = _getRandomizedTime(now, randomDuration);

            await notification.show(
              1,
              '下班打卡成功',
              '您已於 ${randomizedTime.hour}:${randomizedTime.minute} 成功下班打卡',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'auto_nueip_bg_channel',
                  'Auto Nueip BG',
                  channelDescription: 'Auto Nueip Background Service',
                  ongoing: true,
                ),
              ),
            );

            // 計算下一次下班打卡時間（明天同一時間）
            final tomorrow = DateTime(
              now.year,
              now.month,
              now.day,
              clockOutTime.hour,
              clockOutTime.minute,
            ).add(const Duration(days: 1));

            // 更新下一次下班打卡時間
            await LocalStorage.set(
              StorageKeys.nextClockOutTime,
              tomorrow.millisecondsSinceEpoch,
            );
          }
        }
      }
    });
  }

  // 處理來自主應用的命令
  service.on('stop').listen((event) async {
    // 更新服務狀態
    await LocalStorage.set(StorageKeys.serviceEnabled, false);

    // 設置服務停止標記
    await LocalStorage.set('service_stopping', true);

    // 釋放依賴資源
    await Circus.fireAll();

    // 停止服務
    service.stopSelf();
  });

  // 處理設置更新
  service.on('setData').listen((event) async {
    if (event != null) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(event);

      for (final entry in data.entries) {
        await LocalStorage.set(entry.key, entry.value);
      }
    }
  });
}

/// 檢查是否在上班打卡時間範圍內
bool _isWithinClockInTime(
  DateTime now,
  DateTime clockInTime,
  Duration flexibleDuration,
) {
  final checkInStart = DateTime(
    now.year,
    now.month,
    now.day,
    clockInTime.hour,
    clockInTime.minute,
  );
  final checkInEnd = checkInStart.add(flexibleDuration);

  return now.isAfter(checkInStart) && now.isBefore(checkInEnd);
}

/// 檢查是否在下班打卡時間範圍內
bool _isWithinClockOutTime(
  DateTime now,
  DateTime clockOutTime,
  Duration flexibleDuration,
) {
  final checkOutStart = DateTime(
    now.year,
    now.month,
    now.day,
    clockOutTime.hour,
    clockOutTime.minute,
  );
  final checkOutEnd = checkOutStart.add(flexibleDuration);

  return now.isAfter(checkOutStart) && now.isBefore(checkOutEnd);
}

/// 產生隨機調整後的打卡時間
DateTime _getRandomizedTime(DateTime baseTime, Duration randomDuration) {
  if (randomDuration.inSeconds <= 0) {
    return baseTime;
  }

  final random = Random();
  // 隨機產生一個在 -randomDuration 到 +randomDuration 之間的偏移量
  final randomOffsetSeconds =
      random.nextInt(randomDuration.inSeconds * 2) - randomDuration.inSeconds;

  return baseTime.add(Duration(seconds: randomOffsetSeconds));
}

/// 執行打卡選擇
Future<bool> _performClockIn() async {
  try {
    // 從 LocalStorage 獲取必要的資訊
    final authSessionStrs = LocalStorage.get<List<String>>(
      StorageKeys.authSession,
      defaultValue: [],
    );

    if (authSessionStrs.isEmpty) {
      debugPrint('打卡失敗：找不到授權資訊');
      return false;
    }

    // 建立 AuthSession 物件
    AuthSession authSession = AuthSession(
      accessToken: authSessionStrs[0],
      cookie: authSessionStrs[1],
      csrfToken: authSessionStrs[2],
      expiryTime: DateTime.parse(authSessionStrs[3]),
    );

    // 檢查 Token 是否過期
    if (authSession.isTokenExpired()) {
      debugPrint('授權已過期，嘗試重新登入');

      // 獲取登入憑證
      final companyCode = LocalStorage.get<String>(
        StorageKeys.companyCode,
        defaultValue: '',
      );
      final employeeId = LocalStorage.get<String>(
        StorageKeys.employeeId,
        defaultValue: '',
      );
      final password = LocalStorage.get<String>(
        StorageKeys.password,
        defaultValue: '',
      );

      if (companyCode.isEmpty || employeeId.isEmpty || password.isEmpty) {
        debugPrint('重新登入失敗：登入憑證不完整');
        return false;
      }

      // 重新登入
      final repository = Circus.find<NueipRepositoryImpl>();
      final helper = Circus.find<NueipHelper>();

      final loginResult =
          await repository
              .login(company: companyCode, id: employeeId, password: password)
              .run();

      final success = await loginResult.fold<Future<bool>>(
        (failure) async {
          debugPrint('重新登入失敗：${failure.message}');
          return false;
        },
        (response) async {
          if (response.statusCode != 303) {
            debugPrint('重新登入失敗：非預期的狀態碼 ${response.statusCode}');
            return false;
          }

          helper.redirectUrl = response.headers['location']?.first ?? '';

          if (helper.redirectUrl.isEmpty) {
            debugPrint('重新登入失敗：無法取得重定向 URL');
            return false;
          }

          if (helper.redirectUrl.contains('/home')) {
            try {
              await helper.getCookieAndToken();

              // 重新獲取更新後的 AuthSession
              authSession = AuthUtils.getAuthSession(isBackground: true);
              debugPrint('重新登入成功，已更新授權資訊');
              return true;
            } catch (e) {
              debugPrint('重新登入過程中發生錯誤：$e');
              return false;
            }
          } else {
            debugPrint('重新登入失敗：重定向 URL 不包含 /home');
            return false;
          }
        },
      );

      if (!success) {
        debugPrint('重新登入失敗，無法繼續打卡');
        return false;
      }
    }

    // 獲取公司位置
    final latitude = LocalStorage.get<double>(
      StorageKeys.companyLatitude,
      defaultValue: 0.0,
    );
    final longitude = LocalStorage.get<double>(
      StorageKeys.companyLongitude,
      defaultValue: 0.0,
    );

    if (authSession.accessToken == null ||
        authSession.cookie == null ||
        authSession.csrfToken == null) {
      debugPrint('打卡失敗：授權資訊不完整');
      return false;
    }

    if (latitude == 0.0 || longitude == 0.0) {
      debugPrint('打卡失敗：公司位置資訊不完整');
      return false;
    }

    // 從 Circus 獲取 NueipRepository 實例
    final repository = Circus.find<NueipRepositoryImpl>();

    // 判斷是上班還是下班打卡
    final now = DateTime.now();
    final clockInTime = DateTime(
      now.year,
      now.month,
      now.day,
      LocalStorage.get<int>(StorageKeys.clockInTime, defaultValue: 9) ~/ 60,
      LocalStorage.get<int>(StorageKeys.clockInTime, defaultValue: 9) % 60,
    );
    final clockOutTime = DateTime(
      now.year,
      now.month,
      now.day,
      LocalStorage.get<int>(StorageKeys.clockOutTime, defaultValue: 18) ~/ 60,
      LocalStorage.get<int>(StorageKeys.clockOutTime, defaultValue: 18) % 60,
    );

    // 判斷現在時間接近上班時間還是下班時間
    final diffFromClockIn = now.difference(clockInTime).abs();
    final diffFromClockOut = now.difference(clockOutTime).abs();

    // 選擇打卡類型（1 為上班，2 為下班）
    final method = diffFromClockIn < diffFromClockOut ? '1' : '2';

    // 執行打卡操作
    final result =
        await repository
            .clockAction(
              method: method,
              cookie: authSession.cookie!,
              csrfToken: authSession.csrfToken!,
              latitude: latitude,
              longitude: longitude,
            )
            .run();

    return result.fold(
      (failure) {
        debugPrint('打卡失敗：${failure.message}');
        return false;
      },
      (response) {
        debugPrint('打卡成功：${response.statusCode}');
        return true;
      },
    );
  } catch (e) {
    debugPrint('打卡過程中發生錯誤：$e');
    return false;
  }
}
