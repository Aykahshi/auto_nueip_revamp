import 'dart:async';

import 'package:flutter/material.dart';
import 'package:joker_state/cue_gate.dart';
import 'package:joker_state/joker_state.dart';

import '../../../../core/config/storage_keys.dart';
import '../../../../core/utils/local_storage.dart';
import '../../data/services/schedule_background_service.dart';
import '../../domain/entities/background_service_state.dart';

/// Presenter for Background Service, manages all state and business logic.
class ScheduleClockPresenter extends Presenter<BackgroundServiceState> {
  StreamSubscription<bool?>? _serviceStatusSubscription;

  ScheduleClockPresenter({super.keepAlive = true})
    : super(BackgroundServiceState.initial());

  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }

  @override
  void onDone() {
    _serviceStatusSubscription?.cancel();
    super.onDone();
  }

  Future<void> _initializeService() async {
    trick(state.copyWith(isLoading: true));
    await ScheduleBackgroundService.initialize();

    // Listen to service status changes
    _serviceStatusSubscription = ScheduleBackgroundService.serviceStatus.listen((
      isRunning,
    ) {
      if (isRunning == null) return;
      trick(
        state.copyWith(
          isServiceRunning: isRunning,
          lastStatus:
              '服務狀態: ${isRunning ? '運行中' : '已停止'} (${DateTime.now().hour}:${DateTime.now().minute})',
        ),
      );
    });

    // Check current status
    final isRunning = await ScheduleBackgroundService.isRunning();
    // Load saved settings
    final workHoursStartMs = LocalStorage.get<int>(
      StorageKeys.workHoursStart,
      defaultValue: 0,
    );
    final workHoursEndMs = LocalStorage.get<int>(
      StorageKeys.workHoursEnd,
      defaultValue: 0,
    );
    final clockInTimeMs = LocalStorage.get<int>(
      StorageKeys.clockInTime,
      defaultValue: 0,
    );
    final clockOutTimeMs = LocalStorage.get<int>(
      StorageKeys.clockOutTime,
      defaultValue: 0,
    );
    final savedFlexible = LocalStorage.get<int>(
      StorageKeys.flexibleDuration,
      defaultValue: 0,
    );
    final savedRandom = LocalStorage.get<int>(
      StorageKeys.randomTimeRange,
      defaultValue: 0,
    );

    TimeOfDay workHoursStart = state.workHoursStart;
    TimeOfDay workHoursEnd = state.workHoursEnd;
    DateTime clockInTime = state.clockInTime;
    DateTime clockOutTime = state.clockOutTime;
    int flexibleMinutes = state.flexibleMinutes;
    int randomMinutes = state.randomMinutes;

    if (workHoursStartMs > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(workHoursStartMs);
      workHoursStart = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    if (workHoursEndMs > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(workHoursEndMs);
      workHoursEnd = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    if (clockInTimeMs > 0) {
      clockInTime = DateTime.fromMillisecondsSinceEpoch(clockInTimeMs);
    }
    if (clockOutTimeMs > 0) {
      clockOutTime = DateTime.fromMillisecondsSinceEpoch(clockOutTimeMs);
    }
    if (savedFlexible > 0) {
      flexibleMinutes = savedFlexible;
    }
    if (savedRandom > 0) {
      randomMinutes = savedRandom;
    }

    trick(
      state.copyWith(
        isServiceRunning: isRunning,
        lastStatus:
            '服務狀態: ${isRunning ? '運行中' : '已停止'} (${DateTime.now().hour}:${DateTime.now().minute})',
        workHoursStart: workHoursStart,
        workHoursEnd: workHoursEnd,
        clockInTime: clockInTime,
        clockOutTime: clockOutTime,
        flexibleMinutes: flexibleMinutes,
        randomMinutes: randomMinutes,
        isLoading: false,
      ),
    );
  }

  Future<void> selectWorkHoursStart(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: state.workHoursStart,
    );
    if (picked != null) {
      trick(state.copyWith(workHoursStart: picked));
      LocalStorage.set(StorageKeys.workHoursStart, _timeOfDayToMs(picked));
    }
  }

  Future<void> selectWorkHoursEnd(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: state.workHoursEnd,
    );
    if (picked != null) {
      trick(state.copyWith(workHoursEnd: picked));
      LocalStorage.set(StorageKeys.workHoursEnd, _timeOfDayToMs(picked));
    }
  }

  Future<void> selectClockInTime(BuildContext context) async {
    final DateTime? picked = await _pickDateTime(context, state.clockInTime);
    if (picked != null) {
      trick(state.copyWith(clockInTime: picked));
      LocalStorage.set(StorageKeys.clockInTime, picked.millisecondsSinceEpoch);
    }
  }

  Future<void> selectClockOutTime(BuildContext context) async {
    final DateTime? picked = await _pickDateTime(context, state.clockOutTime);
    if (picked != null) {
      trick(state.copyWith(clockOutTime: picked));
      LocalStorage.set(StorageKeys.clockOutTime, picked.millisecondsSinceEpoch);
    }
  }

  void updateFlexibleMinutes(int value) {
    trick(state.copyWith(flexibleMinutes: value));
    LocalStorage.set(StorageKeys.flexibleDuration, value);
  }

  void updateRandomMinutes(int value) {
    trick(state.copyWith(randomMinutes: value));
    LocalStorage.set(StorageKeys.randomTimeRange, value);
  }

  Future<void> startService() async {
    CueGate.debounce(delay: const Duration(seconds: 1)).trigger(() async {
      trick(state.copyWith(isLoading: true));
      await ScheduleBackgroundService.startService();
      await ScheduleBackgroundService.scheduleClockInOut(
        clockInTime: state.clockInTime,
        clockOutTime: state.clockOutTime,
        flexibleDuration: Duration(minutes: state.flexibleMinutes),
        randomDuration: Duration(minutes: state.randomMinutes),
      );
      trick(state.copyWith(isLoading: false));
    });
  }

  Future<void> stopService() async {
    CueGate.debounce(delay: const Duration(seconds: 1)).trigger(() async {
      trick(state.copyWith(isLoading: true));
      await ScheduleBackgroundService.stopService();
      trick(state.copyWith(isLoading: false));
    });
  }

  // --- Helper functions ---
  int _timeOfDayToMs(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      t.hour,
      t.minute,
    ).millisecondsSinceEpoch;
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime initial,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (picked != null) {
      return initial.copyWith(hour: picked.hour, minute: picked.minute);
    }
    return null;
  }
}
