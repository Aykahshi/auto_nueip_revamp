import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:joker_state/joker_state.dart';

import '../extensions/network_extension.dart';

part 'global_presenter.freezed.dart';

class GlobalPresenter extends Presenter<GlobalState> {
  GlobalPresenter({super.keepAlive = true}) : super(const GlobalState.idle());

  late final StreamSubscription<List<ConnectivityResult>> _networkStatus;

  @override
  void onReady() {
    super.onReady();
    _networkStatus = Connectivity().onConnectivityChanged.listen((result) {
      if (!result.isConnected) {
        trick(const GlobalState.networkDisconnected());
      } else if (result.isConnected && state is NetworkDisconnected) {
        trick(const GlobalState.networkConnected());
      }
    });
  }

  @override
  void onDone() {
    _networkStatus.cancel();
    super.onDone();
  }
}

@freezed
sealed class GlobalState with _$GlobalState {
  const factory GlobalState.idle() = Idle;

  const factory GlobalState.networkConnected() = NetworkConnected;

  const factory GlobalState.networkDisconnected() = NetworkDisconnected;
}
