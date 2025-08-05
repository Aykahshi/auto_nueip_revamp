import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:joker_state/joker_state.dart';

import '../../features/calendar/presentation/presenters/attendance_presenter.dart';
import '../../features/form/presentation/presenters/leave_record_presenter.dart';
import '../../features/home/presentation/presenters/clock_presenter.dart';
import '../../features/setting/presentation/presenters/setting_presenter.dart';
import '../extensions/network_extension.dart';
import 'auth_utils.dart';

part 'global_presenter.freezed.dart';

class GlobalPresenter extends Presenter<GlobalState> {
  GlobalPresenter({super.keepAlive = true}) : super(const GlobalState.idle());

  late final StreamSubscription<List<ConnectivityResult>> _networkStatus;

  @override
  void onReady() {
    super.onReady();
    _networkStatus = Connectivity().onConnectivityChanged.listen((result) {
      if (result.isConnected && previousState is NetworkDisconnected) {
        trick(const GlobalState.networkConnected());
      } else {
        trick(const GlobalState.networkDisconnected());
      }
    });
  }

  @override
  void onDone() {
    _networkStatus.cancel();
    super.onDone();
  }

  Future<void> refresh(String type) async {
    trick(const GlobalState.idle());

    await AuthUtils.checkAuthSession(force: true);

    switch (type) {
      case 'clock':
        await Circus.find<ClockPresenter>().refresh();
        break;
      case 'setting':
        await Circus.find<SettingPresenter>().getUserInfo();
        break;
      case 'attendance':
        await Circus.find<AttendancePresenter>().refresh();
        break;
      case 'leave':
        Circus.find<LeaveRecordPresenter>().reset();
        break;
      default:
        break;
    }

    trick(const GlobalState.refreshed());
  }
}

@freezed
sealed class GlobalState with _$GlobalState {
  const factory GlobalState.idle() = Idle;

  const factory GlobalState.refreshed() = Refreshed;

  const factory GlobalState.networkConnected() = NetworkConnected;

  const factory GlobalState.networkDisconnected() = NetworkDisconnected;
}
